#lang racket

;; Define a structure for accounts
(define-struct account (number name balance))

;; Define a structure for generic transactions
(define-struct transaction (tag number timestamp merchant-or-payment-method amount))

;; Define structures for specific types of payments (subtypes of transactions)
(define-struct cash-payment (transaction))
(define-struct check-payment (transaction check-number))
(define-struct card-payment (transaction card-number type))  ; 'type' can be 'credit' or 'debit'


; Helper function to read all lines from the current input port
(define (read-lines)
  (let loop ((line (read-line)))
    (if (eof-object? line)
        '()
        (cons line (loop (read-line))))))

;; Helper function to split a string by whitespace, preserving quoted strings
(define (split-string-preserving-quotes str)
  (map (lambda (s)
         (if (and (string-prefix? "\"" s) (string-suffix? "\"" s) (>= (string-length s) 2))
             (substring s 1 (- (string-length s) 1))
             s))
       (regexp-split #px"\\s+(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)" str)))

(define (parse-transaction parts)
  (let ([tag (car parts)])
    (cond
      [(string=? tag "Purchase")
       ;; Handle purchase transaction
       (make-transaction tag
                         (string->number (cadr parts))
                         (string->number (caddr parts))
                         (cadddr parts)
                         (string->number (cadddr (cdr parts))))]
      [(string=? tag "Payment")
       ;; Distinguish payment types (assuming 'payment-method' follows the 'tag')
       (let ([payment-method (cadddr parts)])
         (cond
           [(string=? payment-method "Cash")
            (make-transaction tag
                              (string->number (cadr parts))
                              (string->number (caddr parts))
                              payment-method
                              (string->number (cadddr (cdr parts))))]
           [(or (string=? payment-method "Check") (string=? payment-method "Credit") (string=? payment-method "Debit"))
            ;; Further parsing needed for check number or card details, for simplification assuming one additional field
            (make-transaction tag
                              (string->number (cadr parts))
                              (string->number (caddr parts))
                              payment-method
                              (string->number (cadddr (cdr (cdr parts)))))]
           [else (error "Unrecognized payment method" payment-method)]))]
      [else (error "Unrecognized transaction type" tag)])))




;; Function to read and parse accounts from ACCOUNTS.TXT
(define (load-accounts)
  (with-input-from-file "ACCOUNTS.TXT"
    (lambda ()
      (let loop ((lines (read-lines)))
        (if (null? lines)
            '()
            (let* ((line (car lines))
                   (parts (split-string-preserving-quotes line))
                   (number (string->number (car parts)))
                   (name (cadr parts))
                   (balance (string->number (caddr parts))))
              (cons (make-account number name balance) (loop (cdr lines)))))))))

(define (load-transactions)
  (with-input-from-file "TRANSACTIONS.TXT"
    (lambda ()
      (let loop ((lines (read-lines)) (line-number 1))
        (if (null? lines)
            '()
            (let* ((line (car lines))
                   (parts (split-string-preserving-quotes line)))
              ;; Check for a basic validation to ensure there are enough parts to parse.
              (if (< (length parts) 4)  ; Adjusted for minimal transaction structure
                  (error "Line format error" line-number line)
                  (let ((transaction (parse-transaction parts)))
                    (cons transaction
                          (loop (cdr lines) (+ 1 line-number)))))))))))


;; Test the file reading functions
(define (test-file-reading)
  (let ([accounts (load-accounts)]
        [transactions (load-transactions)])
    (printf "Loaded Accounts:\n")
    (for ([acc accounts])
      (printf "Account Number: ~a, Name: ~a, Balance: ~a\n"
              (account-number acc) (account-name acc) (account-balance acc)))
    (printf "\nLoaded Transactions:\n")
    (for ([trans transactions])
      (printf "Tag: ~a, Account Number: ~a, Timestamp: ~a, Merchant/Payment Method: ~a, Amount: ~a\n"
              (transaction-tag trans) (transaction-number trans) (transaction-timestamp trans)
              (transaction-merchant-or-payment-method trans) (transaction-amount trans)))))

;; Call the test function
(test-file-reading)


(define (apply-transactions-to-accounts accounts transactions)
  (foldl (lambda (transaction accs)
           (map (lambda (acc)
                  (if (= (account-number acc) (transaction-number transaction))
                      (update-account-balance acc transaction)
                      acc))
                accs))
         accounts
         transactions))

(define (update-account-balance account transaction)
  (let* ((new-balance (cond
                        [(string=? (transaction-tag transaction) "Purchase")
                         (- (account-balance account) (transaction-amount transaction))]
                        [(string=? (transaction-tag transaction) "Payment")
                         (+ (account-balance account) (transaction-amount transaction))]
                        [else
                         (error "Unrecognized transaction type: " (transaction-tag transaction))]))
         (updated-account (make-account (account-number account)
                                        (account-name account)
                                        new-balance)))
    (printf "Updating account ~a: ~a -> ~a (~a: ~a)\n"
            (account-number account)
            (account-balance account)
            new-balance
            (transaction-tag transaction)
            (transaction-amount transaction))
    updated-account))


(define (generate-statements accounts transactions)
  (for-each (lambda (acc)
              (generate-statement-for-account acc transactions))
            (sort accounts < #:key account-number)))


(define (generate-statement-for-account account transactions)
  (let* ((acc-trans (filter (lambda (t) (= (account-number account) (transaction-number t)))
                            transactions))
         (sorted-trans (sort acc-trans < #:key transaction-timestamp))
         (initial-balance (account-balance account))
         (total-purchases (apply + 0 (map (lambda (t) (if (string=? (transaction-tag t) "Purchase") (transaction-amount t) 0)) acc-trans)))
         (total-payments (apply + 0 (map (lambda (t) (if (string=? (transaction-tag t) "Payment") (transaction-amount t) 0)) acc-trans)))
         (ending-balance (+ initial-balance (- total-payments) total-purchases)))
    (with-output-to-file "STATEMENTS.txt"
      (lambda ()
        (displayln "*********************************************************")
        (displayln "STATEMENT OF ACCOUNT")
        (displayln (format "~a        ~a        Starting Balance:   ~a \n"
                           (account-number account) (account-name account) initial-balance))
        (for-each (lambda (trans)
                    (displayln (format "~a   ~a    ~a                  ~a"
                                       (transaction-timestamp trans) (transaction-tag trans)
                                       (transaction-merchant-or-payment-method trans) (transaction-amount trans))))
                  sorted-trans)
        (displayln (format "\nTotal Purchases:        ~a" total-purchases))
        (displayln (format "Total Payments:         ~a" total-payments))
        (displayln (format "Ending Balance:         ~a\n" ending-balance)))
      #:exists 'append))) ; Append to the file instead of overwriting




(define accounts (load-accounts))
(define transactions (load-transactions))
(define updated-accounts (apply-transactions-to-accounts accounts transactions))
(generate-statements updated-accounts transactions)
