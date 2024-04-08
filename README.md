# Bank-Accounts

Transactions Processor

This Racket-based program processes financial transactions, updates account balances, and generates detailed statements for each account. It's designed to demonstrate basic financial transactions handling, including purchases and payments, in a simplified manner.
Features

    Load Transactions: Reads transactions from a text file, including purchases and various types of payments (cash, check, credit, and debit).
    Update Account Balances: Dynamically updates account balances based on the transactions processed.
    Generate Statements: Produces a detailed statement for each account, showing starting and ending balances, along with a chronological list of transactions.

Getting Started

To run this program, you will need Racket installed on your computer. Follow these steps:

    Install Racket: Download and install Racket from the official Racket website.
    Download the Program: Clone or download this program's repository to your local machine.
    Prepare Input Files: Ensure ACCOUNTS.TXT and TRANSACTIONS.TXT are placed in the same directory as the program. Format these files as described in the "Input File Formats" section below.

Running the Program

Navigate to the program's directory in your terminal, and run the program using the Racket interpreter. After execution, the program will generate a STATEMENTS.TXT file in the same directory, containing the updated account statements.
Input File Formats

    ACCOUNTS.TXT: Lists accounts, one per line, with the format: <account number> "<account name>" <initial balance>.
    TRANSACTIONS.TXT: Lists transactions, one per line, with the format for purchases: Purchase <account number> <timestamp> "<merchant name>" <amount> and for payments: Payment <account number> <timestamp> <payment type> <amount> where payment type can be Cash, Check, Credit, or Debit.

Output

    STATEMENTS.TXT: Contains updated statements for each account, including a list of transactions (sorted by timestamp), total purchases, total payments, and the ending balance.
