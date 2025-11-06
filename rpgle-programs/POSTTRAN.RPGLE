      *===============================================================
      * Program: POSTTRAN (Post Transaction)
      * Description: Transaction processing with commitment control
      * Language: RPG ILE (Free Format)
      * Created: 2010-01-15
      * Modified: 2024-11-20
      *===============================================================
      * This program demonstrates ACID transaction processing in RPG
      * including balance updates, journaling, and concurrent access
      *===============================================================

     H DFTACTGRP(*NO) ACTGRP(*CALLER) BNDDIR('BANKLIB/BANKBND')

      *===============================================================
      * File Specifications - Using commitment control
      *===============================================================
     FACCTMAST  UF   E           K DISK    COMMIT
     FTRANLOG   O    E             DISK    COMMIT

      *===============================================================
      * Data Structures
      *===============================================================
     D TransactionDS   DS                  QUALIFIED
     D  TransactionId                15A
     D  AccountId                    12A
     D  TransType                     2A
     D  Amount                       15P 2
     D  ToAccountId                  12A
     D  Description                  50A
     D  ReferenceNum                 20A
     D  Channel                       3A
     D  UserId                       10A
     D  Terminal                      8A
     D  IpAddress                    15A

     D ResponseDS      DS                  QUALIFIED
     D  Success                       1A
     D  ErrorCode                     5A
     D  ErrorMsg                     80A
     D  TransactionId                15A
     D  NewBalance                   15P 2

     D AccountInfo     DS                  QUALIFIED
     D  AccountId                    12A
     D  Balance                      15P 2
     D  AvailBalance                 15P 2
     D  Status                        1A
     D  OverdraftProt                 1A
     D  OverdraftLimit               15P 2

      *===============================================================
      * Constants
      *===============================================================
     D TRAN_DEPOSIT    C                   CONST('DP')
     D TRAN_WITHDRAW   C                   CONST('WD')
     D TRAN_TRANSFER   C                   CONST('TF')

     D STATUS_PENDING  C                   CONST('P')
     D STATUS_COMPLETE C                   CONST('C')
     D STATUS_REVERSED C                   CONST('R')

     D ACCT_ACTIVE     C                   CONST('A')
     D ACCT_CLOSED     C                   CONST('C')
     D ACCT_FROZEN     C                   CONST('F')

      *===============================================================
      * Standalone Variables
      *===============================================================
     D CurrentDate     S               8S 0
     D CurrentTime     S               6S 0
     D PostDate        S               8S 0
     D PostTime        S               6S 0
     D NewTransId      S              15A

      *===============================================================
      * Procedure Prototypes
      *===============================================================
     D ProcessTransaction...
     D                 PR                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D ProcessDeposit  PR                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D ProcessWithdrawal...
     D                 PR                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D ProcessTransfer...
     D                 PR                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D GetAccountInfo  PR                  LIKEDS(AccountInfo)
     D  pAccountId                   12A   CONST

     D UpdateAccountBalance...
     D                 PR              1N
     D  pAccountId                   12A   CONST
     D  pAmount                      15P 2 CONST
     D  pIsDebit                      1N   CONST

     D WriteTransactionLog...
     D                 PR              1N
     D  pTransaction                       LIKEDS(TransactionDS)
     D  pBalance                     15P 2 CONST
     D  pStatus                       1A   CONST
     D  pErrorCode                    5A   CONST

     D GenerateTransactionId...
     D                 PR            15A

     D ValidateTransaction...
     D                 PR                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D CheckSufficientFunds...
     D                 PR              1N
     D  pAccount                           LIKEDS(AccountInfo)
     D  pAmount                      15P 2 CONST

     D GetDateTime     PR
     D  pDate                         8S 0
     D  pTime                         6S 0

      *===============================================================
      * Main Procedure
      *===============================================================
      /FREE

       *INLR = *ON;
       RETURN;

      /END-FREE

      *===============================================================
      * ProcessTransaction - Main transaction router
      *===============================================================
     P ProcessTransaction...
     P                 B                   EXPORT
     D ProcessTransaction...
     D                 PI                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D wResponse       DS                  LIKEDS(ResponseDS)

      /FREE

       // Initialize response
       wResponse.Success = 'N';

       // Validate transaction
       wResponse = ValidateTransaction(pTransaction);
       IF wResponse.Success = 'N';
         RETURN wResponse;
       ENDIF;

       // Route to appropriate processor based on transaction type
       SELECT;
         WHEN pTransaction.TransType = TRAN_DEPOSIT;
           wResponse = ProcessDeposit(pTransaction);

         WHEN pTransaction.TransType = TRAN_WITHDRAW;
           wResponse = ProcessWithdrawal(pTransaction);

         WHEN pTransaction.TransType = TRAN_TRANSFER;
           wResponse = ProcessTransfer(pTransaction);

         OTHER;
           wResponse.ErrorCode = 'E1001';
           wResponse.ErrorMsg = 'Invalid transaction type';
       ENDSL;

       RETURN wResponse;

      /END-FREE
     P ProcessTransaction...
     P                 E

      *===============================================================
      * ProcessDeposit - Handle deposit transactions
      *===============================================================
     P ProcessDeposit  B
     D ProcessDeposit  PI                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D wResponse       DS                  LIKEDS(ResponseDS)
     D wAccount        DS                  LIKEDS(AccountInfo)
     D wSuccess        S               1N

      /FREE

       wResponse.Success = 'N';

       // Get account information
       wAccount = GetAccountInfo(pTransaction.AccountId);

       IF wAccount.AccountId = *BLANKS;
         wResponse.ErrorCode = 'E1002';
         wResponse.ErrorMsg = 'Account not found';
         RETURN wResponse;
       ENDIF;

       IF wAccount.Status <> ACCT_ACTIVE;
         wResponse.ErrorCode = 'E1003';
         wResponse.ErrorMsg = 'Account not active';
         RETURN wResponse;
       ENDIF;

       // Generate transaction ID
       NewTransId = GenerateTransactionId();
       pTransaction.TransactionId = NewTransId;

       // Update account balance (credit)
       wSuccess = UpdateAccountBalance(
                    pTransaction.AccountId :
                    pTransaction.Amount :
                    *OFF);  // Credit (not debit)

       IF NOT wSuccess;
         wResponse.ErrorCode = 'E1099';
         wResponse.ErrorMsg = 'Failed to update balance';
         ROLLBACK;
         RETURN wResponse;
       ENDIF;

       // Get new balance
       wAccount = GetAccountInfo(pTransaction.AccountId);

       // Write transaction log
       wSuccess = WriteTransactionLog(
                    pTransaction :
                    wAccount.Balance :
                    STATUS_COMPLETE :
                    '');

       IF NOT wSuccess;
         wResponse.ErrorCode = 'E1098';
         wResponse.ErrorMsg = 'Failed to log transaction';
         ROLLBACK;
         RETURN wResponse;
       ENDIF;

       // Commit transaction
       COMMIT;

       wResponse.Success = 'Y';
       wResponse.TransactionId = NewTransId;
       wResponse.NewBalance = wAccount.Balance;
       wResponse.ErrorMsg = 'Deposit successful';

       RETURN wResponse;

      /END-FREE
     P ProcessDeposit  E

      *===============================================================
      * ProcessWithdrawal - Handle withdrawal transactions
      *===============================================================
     P ProcessWithdrawal...
     P                 B
     D ProcessWithdrawal...
     D                 PI                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D wResponse       DS                  LIKEDS(ResponseDS)
     D wAccount        DS                  LIKEDS(AccountInfo)
     D wSuccess        S               1N
     D wHasFunds       S               1N

      /FREE

       wResponse.Success = 'N';

       // Get account information with lock
       wAccount = GetAccountInfo(pTransaction.AccountId);

       IF wAccount.AccountId = *BLANKS;
         wResponse.ErrorCode = 'E1002';
         wResponse.ErrorMsg = 'Account not found';
         RETURN wResponse;
       ENDIF;

       IF wAccount.Status <> ACCT_ACTIVE;
         wResponse.ErrorCode = 'E1003';
         wResponse.ErrorMsg = 'Account not active';
         RETURN wResponse;
       ENDIF;

       // Check sufficient funds
       wHasFunds = CheckSufficientFunds(wAccount : pTransaction.Amount);

       IF NOT wHasFunds;
         wResponse.ErrorCode = 'E1004';
         wResponse.ErrorMsg = 'Insufficient funds';
         RETURN wResponse;
       ENDIF;

       // Generate transaction ID
       NewTransId = GenerateTransactionId();
       pTransaction.TransactionId = NewTransId;

       // Update account balance (debit)
       wSuccess = UpdateAccountBalance(
                    pTransaction.AccountId :
                    pTransaction.Amount :
                    *ON);  // Debit

       IF NOT wSuccess;
         wResponse.ErrorCode = 'E1099';
         wResponse.ErrorMsg = 'Failed to update balance';
         ROLLBACK;
         RETURN wResponse;
       ENDIF;

       // Get new balance
       wAccount = GetAccountInfo(pTransaction.AccountId);

       // Write transaction log
       wSuccess = WriteTransactionLog(
                    pTransaction :
                    wAccount.Balance :
                    STATUS_COMPLETE :
                    '');

       IF NOT wSuccess;
         wResponse.ErrorCode = 'E1098';
         wResponse.ErrorMsg = 'Failed to log transaction';
         ROLLBACK;
         RETURN wResponse;
       ENDIF;

       // Commit transaction
       COMMIT;

       wResponse.Success = 'Y';
       wResponse.TransactionId = NewTransId;
       wResponse.NewBalance = wAccount.Balance;
       wResponse.ErrorMsg = 'Withdrawal successful';

       RETURN wResponse;

      /END-FREE
     P ProcessWithdrawal...
     P                 E

      *===============================================================
      * ProcessTransfer - Handle transfer between accounts
      *===============================================================
     P ProcessTransfer...
     P                 B
     D ProcessTransfer...
     D                 PI                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D wResponse       DS                  LIKEDS(ResponseDS)
     D wFromAcct       DS                  LIKEDS(AccountInfo)
     D wToAcct         DS                  LIKEDS(AccountInfo)
     D wSuccess        S               1N

      /FREE

       wResponse.Success = 'N';

       // Validate both accounts exist
       wFromAcct = GetAccountInfo(pTransaction.AccountId);
       wToAcct = GetAccountInfo(pTransaction.ToAccountId);

       IF wFromAcct.AccountId = *BLANKS;
         wResponse.ErrorCode = 'E1002';
         wResponse.ErrorMsg = 'From account not found';
         RETURN wResponse;
       ENDIF;

       IF wToAcct.AccountId = *BLANKS;
         wResponse.ErrorCode = 'E1005';
         wResponse.ErrorMsg = 'To account not found';
         RETURN wResponse;
       ENDIF;

       // Check sufficient funds
       IF NOT CheckSufficientFunds(wFromAcct : pTransaction.Amount);
         wResponse.ErrorCode = 'E1004';
         wResponse.ErrorMsg = 'Insufficient funds';
         RETURN wResponse;
       ENDIF;

       // Generate transaction ID
       NewTransId = GenerateTransactionId();
       pTransaction.TransactionId = NewTransId;

       // Debit from source account
       wSuccess = UpdateAccountBalance(
                    pTransaction.AccountId :
                    pTransaction.Amount :
                    *ON);

       IF NOT wSuccess;
         ROLLBACK;
         wResponse.ErrorCode = 'E1099';
         wResponse.ErrorMsg = 'Failed to debit source account';
         RETURN wResponse;
       ENDIF;

       // Credit to destination account
       wSuccess = UpdateAccountBalance(
                    pTransaction.ToAccountId :
                    pTransaction.Amount :
                    *OFF);

       IF NOT wSuccess;
         ROLLBACK;
         wResponse.ErrorCode = 'E1099';
         wResponse.ErrorMsg = 'Failed to credit destination account';
         RETURN wResponse;
       ENDIF;

       // Log transaction for both accounts
       wFromAcct = GetAccountInfo(pTransaction.AccountId);

       wSuccess = WriteTransactionLog(
                    pTransaction :
                    wFromAcct.Balance :
                    STATUS_COMPLETE :
                    '');

       IF NOT wSuccess;
         ROLLBACK;
         wResponse.ErrorCode = 'E1098';
         wResponse.ErrorMsg = 'Failed to log transaction';
         RETURN wResponse;
       ENDIF;

       // Commit entire transfer
       COMMIT;

       wResponse.Success = 'Y';
       wResponse.TransactionId = NewTransId;
       wResponse.NewBalance = wFromAcct.Balance;
       wResponse.ErrorMsg = 'Transfer successful';

       RETURN wResponse;

      /END-FREE
     P ProcessTransfer...
     P                 E

      *===============================================================
      * GetAccountInfo - Read account with lock
      *===============================================================
     P GetAccountInfo  B
     D GetAccountInfo  PI                  LIKEDS(AccountInfo)
     D  pAccountId                   12A   CONST

     D wAccount        DS                  LIKEDS(AccountInfo)

      /FREE

       CHAIN pAccountId ACCTREC;

       IF %FOUND(ACCTMAST);
         wAccount.AccountId = ACCTID;
         wAccount.Balance = BALANCE;
         wAccount.AvailBalance = AVAILBAL;
         wAccount.Status = STATUS;
         wAccount.OverdraftProt = OVERDRAFT;
         wAccount.OverdraftLimit = ODLIMIT;
       ENDIF;

       RETURN wAccount;

      /END-FREE
     P GetAccountInfo  E

      *===============================================================
      * UpdateAccountBalance - Update balance atomically
      *===============================================================
     P UpdateAccountBalance...
     P                 B
     D UpdateAccountBalance...
     D                 PI              1N
     D  pAccountId                   12A   CONST
     D  pAmount                      15P 2 CONST
     D  pIsDebit                      1N   CONST

      /FREE

       CHAIN pAccountId ACCTREC;

       IF NOT %FOUND(ACCTMAST);
         RETURN *OFF;
       ENDIF;

       // Get current date/time
       GetDateTime(CurrentDate : CurrentTime);

       IF pIsDebit;
         BALANCE = BALANCE - pAmount;
         AVAILBAL = AVAILBAL - pAmount;
       ELSE;
         BALANCE = BALANCE + pAmount;
         AVAILBAL = AVAILBAL + pAmount;
       ENDIF;

       LASTTRANDT = CurrentDate;
       LASTTRANTM = CurrentTime;

       UPDATE ACCTREC;

       IF %ERROR;
         RETURN *OFF;
       ENDIF;

       RETURN *ON;

      /END-FREE
     P UpdateAccountBalance...
     P                 E

      *===============================================================
      * WriteTransactionLog - Create transaction record
      *===============================================================
     P WriteTransactionLog...
     P                 B
     D WriteTransactionLog...
     D                 PI              1N
     D  pTransaction                       LIKEDS(TransactionDS)
     D  pBalance                     15P 2 CONST
     D  pStatus                       1A   CONST
     D  pErrorCode                    5A   CONST

      /FREE

       GetDateTime(CurrentDate : CurrentTime);
       GetDateTime(PostDate : PostTime);

       TRANID = pTransaction.TransactionId;
       ACCTID = pTransaction.AccountId;
       TRANTYPE = pTransaction.TransType;
       AMOUNT = pTransaction.Amount;
       BALANCE = pBalance;
       TOACCTID = pTransaction.ToAccountId;
       TRANDATE = CurrentDate;
       TRANTIME = CurrentTime;
       POSTDATE = PostDate;
       POSTTIME = PostTime;
       DESCR = pTransaction.Description;
       REFNUM = pTransaction.ReferenceNum;
       CHANNEL = pTransaction.Channel;
       STATUS = pStatus;
       ERRORCODE = pErrorCode;
       USERID = pTransaction.UserId;
       TERMINAL = pTransaction.Terminal;
       IPADDR = pTransaction.IpAddress;
       CRTDATE = CurrentDate;
       CRTTIME = CurrentTime;

       WRITE TRANREC;

       IF %ERROR;
         RETURN *OFF;
       ENDIF;

       RETURN *ON;

      /END-FREE
     P WriteTransactionLog...
     P                 E

      *===============================================================
      * Supporting procedures (simplified implementations)
      *===============================================================
     P ValidateTransaction...
     P                 B
     D ValidateTransaction...
     D                 PI                  LIKEDS(ResponseDS)
     D  pTransaction                       LIKEDS(TransactionDS)

     D wResponse       DS                  LIKEDS(ResponseDS)

      /FREE

       wResponse.Success = 'Y';

       IF pTransaction.Amount <= 0;
         wResponse.Success = 'N';
         wResponse.ErrorCode = 'E1006';
         wResponse.ErrorMsg = 'Amount must be positive';
       ENDIF;

       RETURN wResponse;

      /END-FREE
     P ValidateTransaction...
     P                 E

     P CheckSufficientFunds...
     P                 B
     D CheckSufficientFunds...
     D                 PI              1N
     D  pAccount                           LIKEDS(AccountInfo)
     D  pAmount                      15P 2 CONST

      /FREE

       IF pAccount.AvailBalance >= pAmount;
         RETURN *ON;
       ENDIF;

       // Check overdraft protection
       IF pAccount.OverdraftProt = 'Y';
         IF (pAccount.AvailBalance + pAccount.OverdraftLimit) >= pAmount;
           RETURN *ON;
         ENDIF;
       ENDIF;

       RETURN *OFF;

      /END-FREE
     P CheckSufficientFunds...
     P                 E

     P GenerateTransactionId...
     P                 B
     D GenerateTransactionId...
     D                 PI            15A

     D wTransId        S              15A
     D wDate           S               8S 0
     D wTime           S               6S 0

      /FREE

       GetDateTime(wDate : wTime);
       wTransId = 'T' + %CHAR(wDate) + %CHAR(wTime);

       RETURN wTransId;

      /END-FREE
     P GenerateTransactionId...
     P                 E

     P GetDateTime     B
     D GetDateTime     PI
     D  pDate                         8S 0
     D  pTime                         6S 0

     D wTimestamp      S               Z

      /FREE

       wTimestamp = %TIMESTAMP();
       pDate = %DEC(%CHAR(%DATE(wTimestamp):*ISO0):8:0);
       pTime = %DEC(%SUBST(%CHAR(%TIME(wTimestamp):*HMS0):1:6):6:0);

      /END-FREE
     P GetDateTime     E
