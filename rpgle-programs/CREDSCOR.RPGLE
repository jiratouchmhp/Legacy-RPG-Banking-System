      *===============================================================
      * Program: CREDSCOR (Credit Scoring)
      * Description: Calculate credit score for loan applications
      * Language: RPG ILE (Free Format)
      * Created: 2010-01-15
      * Modified: 2024-11-20
      *===============================================================
      * Multi-factor credit risk calculation for FSI compliance
      *===============================================================

     H DFTACTGRP(*NO) ACTGRP(*CALLER) BNDDIR('BANKLIB/BANKBND')

      *===============================================================
      * File Specifications
      *===============================================================
     FCUSTMAST  IF   E           K DISK
     FACCTMAST  IF   E           K DISK
     FTRANLOG   IF   E           K DISK

      *===============================================================
      * Data Structures
      *===============================================================
     D CreditInput     DS                  QUALIFIED
     D  CustomerId                   10A
     D  RequestedAmt                 15P 2
     D  LoanTerm                      3S 0   // Months
     D  LoanPurpose                  30A
     D  AnnualIncome                 15P 2
     D  Employment                   30A
     D  YearsEmployed                 3S 0

     D CreditOutput    DS                  QUALIFIED
     D  CreditScore                   3S 0
     D  RiskLevel                     1A     // L M H
     D  Recommendation                1A     // A=Approve D=Deny R=Review
     D  MaxLoanAmount                15P 2
     D  SuggestedRate                 5P 4
     D  Factors                      200A
     D  ErrorCode                     5A
     D  ErrorMsg                     80A

     D PaymentHistory  DS                  QUALIFIED
     D  TotalTrans                    5S 0
     D  OnTimePercent                 5P 2
     D  AvgBalance                   15P 2
     D  MaxBalance                   15P 2
     D  OverdraftCount                3S 0
     D  MonthsHistory                 3S 0

     D DebtInfo        DS                  QUALIFIED
     D  TotalDebt                    15P 2
     D  MonthlyPayment               15P 2
     D  DebtToIncome                  5P 2
     D  ActiveAccounts                3S 0

      *===============================================================
      * Constants
      *===============================================================
     D BASE_SCORE      C                   CONST(600)
     D MAX_SCORE       C                   CONST(850)
     D MIN_SCORE       C                   CONST(300)

     D APPROVE_THRESHOLD...
     D                 C                   CONST(680)
     D REVIEW_THRESHOLD...
     D                 C                   CONST(620)

     D RISK_LOW        C                   CONST('L')
     D RISK_MEDIUM     C                   CONST('M')
     D RISK_HIGH       C                   CONST('H')

      *===============================================================
      * Standalone Variables
      *===============================================================
     D FinalScore      S               3S 0
     D TempScore       S               5P 2

      *===============================================================
      * Procedure Prototypes
      *===============================================================
     D CalculateCreditScore...
     D                 PR                  LIKEDS(CreditOutput)
     D  pInput                             LIKEDS(CreditInput)

     D GetPaymentHistory...
     D                 PR                  LIKEDS(PaymentHistory)
     D  pCustomerId                   10A   CONST

     D CalculateDebtInfo...
     D                 PR                  LIKEDS(DebtInfo)
     D  pCustomerId                   10A   CONST

     D ScorePaymentHistory...
     D                 PR             5P 2
     D  pHistory                           LIKEDS(PaymentHistory)

     D ScoreDebtRatio  PR             5P 2
     D  pDebt                              LIKEDS(DebtInfo)
     D  pIncome                      15P 2 CONST

     D ScoreAccountAge...
     D                 PR             5P 2
     D  pHistory                           LIKEDS(PaymentHistory)

     D ScoreIncome     PR             5P 2
     D  pIncome                      15P 2 CONST

     D ScoreEmployment...
     D                 PR             5P 2
     D  pYears                        3S 0 CONST

     D DetermineRiskLevel...
     D                 PR             1A
     D  pScore                        3S 0 CONST

     D DetermineRecommendation...
     D                 PR             1A
     D  pScore                        3S 0 CONST

     D CalculateMaxLoan...
     D                 PR            15P 2
     D  pScore                        3S 0 CONST
     D  pIncome                      15P 2 CONST

     D CalculateRate   PR             5P 4
     D  pScore                        3S 0 CONST

     D BuildFactorsSummary...
     D                 PR           200A
     D  pPayment                     5P 2 CONST
     D  pDebt                        5P 2 CONST
     D  pAge                         5P 2 CONST
     D  pIncome                      5P 2 CONST
     D  pEmploy                      5P 2 CONST

      *===============================================================
      * Main Procedure
      *===============================================================
      /FREE

       *INLR = *ON;
       RETURN;

      /END-FREE

      *===============================================================
      * CalculateCreditScore - Main scoring algorithm
      *===============================================================
     P CalculateCreditScore...
     P                 B                   EXPORT
     D CalculateCreditScore...
     D                 PI                  LIKEDS(CreditOutput)
     D  pInput                             LIKEDS(CreditInput)

     D wOutput         DS                  LIKEDS(CreditOutput)
     D wPayment        DS                  LIKEDS(PaymentHistory)
     D wDebt           DS                  LIKEDS(DebtInfo)

     D wPaymentScore   S               5P 2
     D wDebtScore      S               5P 2
     D wAgeScore       S               5P 2
     D wIncomeScore    S               5P 2
     D wEmployScore    S               5P 2

      /FREE

       // Initialize output
       wOutput.CreditScore = 0;
       wOutput.ErrorCode = '';
       wOutput.ErrorMsg = '';

       // Validate customer exists
       CHAIN pInput.CustomerId CUSTREC;
       IF NOT %FOUND(CUSTMAST);
         wOutput.ErrorCode = 'E2001';
         wOutput.ErrorMsg = 'Customer not found';
         RETURN wOutput;
       ENDIF;

       // Get payment history from transaction log
       wPayment = GetPaymentHistory(pInput.CustomerId);

       // Calculate debt information
       wDebt = CalculateDebtInfo(pInput.CustomerId);

       // Calculate component scores
       wPaymentScore = ScorePaymentHistory(wPayment);
       wDebtScore = ScoreDebtRatio(wDebt : pInput.AnnualIncome);
       wAgeScore = ScoreAccountAge(wPayment);
       wIncomeScore = ScoreIncome(pInput.AnnualIncome);
       wEmployScore = ScoreEmployment(pInput.YearsEmployed);

       // Weighted calculation
       // Payment history: 35%
       // Debt ratio: 30%
       // Credit age: 15%
       // Income: 10%
       // Employment: 10%

       TempScore = BASE_SCORE +
                   (wPaymentScore * 0.35) +
                   (wDebtScore * 0.30) +
                   (wAgeScore * 0.15) +
                   (wIncomeScore * 0.10) +
                   (wEmployScore * 0.10);

       // Ensure score is within bounds
       IF TempScore > MAX_SCORE;
         FinalScore = MAX_SCORE;
       ELSEIF TempScore < MIN_SCORE;
         FinalScore = MIN_SCORE;
       ELSE;
         FinalScore = %INT(TempScore);
       ENDIF;

       // Build output
       wOutput.CreditScore = FinalScore;
       wOutput.RiskLevel = DetermineRiskLevel(FinalScore);
       wOutput.Recommendation = DetermineRecommendation(FinalScore);
       wOutput.MaxLoanAmount = CalculateMaxLoan(FinalScore :
                                                pInput.AnnualIncome);
       wOutput.SuggestedRate = CalculateRate(FinalScore);
       wOutput.Factors = BuildFactorsSummary(wPaymentScore :
                                             wDebtScore :
                                             wAgeScore :
                                             wIncomeScore :
                                             wEmployScore);

       RETURN wOutput;

      /END-FREE
     P CalculateCreditScore...
     P                 E

      *===============================================================
      * GetPaymentHistory - Analyze transaction patterns
      *===============================================================
     P GetPaymentHistory...
     P                 B
     D GetPaymentHistory...
     D                 PI                  LIKEDS(PaymentHistory)
     D  pCustomerId                   10A   CONST

     D wHistory        DS                  LIKEDS(PaymentHistory)
     D wTotalTrans     S               5S 0
     D wTotalBalance   S              15P 2
     D wMaxBal         S              15P 2
     D wOverdrafts     S               3S 0
     D wAccountId      S              12A

      /FREE

       // Initialize
       wHistory.TotalTrans = 0;
       wHistory.OnTimePercent = 100.00;
       wHistory.AvgBalance = 0;
       wHistory.MaxBalance = 0;
       wHistory.OverdraftCount = 0;
       wHistory.MonthsHistory = 0;

       // Get customer's first account
       SETLL pCustomerId ACCTREC;
       READE pCustomerId ACCTREC;

       IF %FOUND(ACCTMAST);
         wAccountId = ACCTID;

         // Count transactions for this account
         EXEC SQL
           SELECT COUNT(*),
                  COALESCE(AVG(BALANCE), 0),
                  COALESCE(MAX(BALANCE), 0)
           INTO :wTotalTrans,
                :wTotalBalance,
                :wMaxBal
           FROM TRANLOG
           WHERE ACCTID = :wAccountId
             AND STATUS = 'C';

         wHistory.TotalTrans = wTotalTrans;
         wHistory.AvgBalance = wTotalBalance;
         wHistory.MaxBalance = wMaxBal;

         // Estimate months of history (simplified)
         IF wTotalTrans > 0;
           wHistory.MonthsHistory = wTotalTrans / 10;  // Assume ~10 trans/month
           IF wHistory.MonthsHistory > 120;
             wHistory.MonthsHistory = 120;  // Cap at 10 years
           ENDIF;
         ENDIF;

         // Check for negative balances (overdrafts)
         EXEC SQL
           SELECT COUNT(*)
           INTO :wOverdrafts
           FROM TRANLOG
           WHERE ACCTID = :wAccountId
             AND BALANCE < 0;

         wHistory.OverdraftCount = wOverdrafts;

         // Calculate on-time percentage
         IF wTotalTrans > 0;
           wHistory.OnTimePercent =
             ((wTotalTrans - wOverdrafts) * 100.0) / wTotalTrans;
         ENDIF;
       ENDIF;

       RETURN wHistory;

      /END-FREE
     P GetPaymentHistory...
     P                 E

      *===============================================================
      * CalculateDebtInfo - Determine debt levels
      *===============================================================
     P CalculateDebtInfo...
     P                 B
     D CalculateDebtInfo...
     D                 PI                  LIKEDS(DebtInfo)
     D  pCustomerId                   10A   CONST

     D wDebt           DS                  LIKEDS(DebtInfo)
     D wTotalBal       S              15P 2
     D wAcctCount      S               3S 0

      /FREE

       // Initialize
       wDebt.TotalDebt = 0;
       wDebt.MonthlyPayment = 0;
       wDebt.DebtToIncome = 0;
       wDebt.ActiveAccounts = 0;

       // Sum all account balances for customer
       EXEC SQL
         SELECT COALESCE(SUM(BALANCE), 0),
                COUNT(*)
         INTO :wTotalBal,
              :wAcctCount
         FROM ACCTMAST
         WHERE CUSTID = :pCustomerId
           AND STATUS = 'A'
           AND ACCTTYPE = 'LN';  // Loan accounts

       wDebt.TotalDebt = wTotalBal;
       wDebt.ActiveAccounts = wAcctCount;

       // Estimate monthly payment (simplified: 2% of total debt)
       wDebt.MonthlyPayment = wTotalBal * 0.02;

       RETURN wDebt;

      /END-FREE
     P CalculateDebtInfo...
     P                 E

      *===============================================================
      * ScorePaymentHistory - Score based on payment behavior
      *===============================================================
     P ScorePaymentHistory...
     P                 B
     D ScorePaymentHistory...
     D                 PI             5P 2
     D  pHistory                           LIKEDS(PaymentHistory)

     D wScore          S               5P 2

      /FREE

       wScore = 0;

       // On-time payment percentage (0-100 points)
       wScore = pHistory.OnTimePercent;

       // Bonus for transaction history
       IF pHistory.TotalTrans >= 100;
         wScore = wScore + 20;
       ELSEIF pHistory.TotalTrans >= 50;
         wScore = wScore + 10;
       ENDIF;

       // Penalty for overdrafts
       wScore = wScore - (pHistory.OverdraftCount * 5);

       // Ensure within bounds
       IF wScore > 150;
         wScore = 150;
       ELSEIF wScore < 0;
         wScore = 0;
       ENDIF;

       RETURN wScore;

      /END-FREE
     P ScorePaymentHistory...
     P                 E

      *===============================================================
      * ScoreDebtRatio - Score based on debt-to-income ratio
      *===============================================================
     P ScoreDebtRatio  B
     D ScoreDebtRatio  PI             5P 2
     D  pDebt                              LIKEDS(DebtInfo)
     D  pIncome                      15P 2 CONST

     D wScore          S               5P 2
     D wRatio          S               5P 2

      /FREE

       wScore = 100;  // Start with perfect score

       IF pIncome > 0;
         // Calculate debt-to-income ratio
         wRatio = (pDebt.MonthlyPayment * 12) / pIncome * 100;
         pDebt.DebtToIncome = wRatio;

         // Score based on ratio
         IF wRatio <= 20;
           wScore = 100;
         ELSEIF wRatio <= 35;
           wScore = 80;
         ELSEIF wRatio <= 43;
           wScore = 50;
         ELSE;
           wScore = 20;
         ENDIF;
       ENDIF;

       RETURN wScore;

      /END-FREE
     P ScoreDebtRatio  E

      *===============================================================
      * ScoreAccountAge - Score based on credit history length
      *===============================================================
     P ScoreAccountAge...
     P                 B
     D ScoreAccountAge...
     D                 PI             5P 2
     D  pHistory                           LIKEDS(PaymentHistory)

     D wScore          S               5P 2

      /FREE

       // Longer history = better score
       IF pHistory.MonthsHistory >= 84;  // 7+ years
         wScore = 100;
       ELSEIF pHistory.MonthsHistory >= 60;  // 5+ years
         wScore = 80;
       ELSEIF pHistory.MonthsHistory >= 36;  // 3+ years
         wScore = 60;
       ELSEIF pHistory.MonthsHistory >= 12;  // 1+ year
         wScore = 40;
       ELSE;
         wScore = 20;
       ENDIF;

       RETURN wScore;

      /END-FREE
     P ScoreAccountAge...
     P                 E

      *===============================================================
      * ScoreIncome - Score based on annual income
      *===============================================================
     P ScoreIncome     B
     D ScoreIncome     PI             5P 2
     D  pIncome                      15P 2 CONST

     D wScore          S               5P 2

      /FREE

       IF pIncome >= 100000;
         wScore = 100;
       ELSEIF pIncome >= 75000;
         wScore = 80;
       ELSEIF pIncome >= 50000;
         wScore = 60;
       ELSEIF pIncome >= 30000;
         wScore = 40;
       ELSE;
         wScore = 20;
       ENDIF;

       RETURN wScore;

      /END-FREE
     P ScoreIncome     E

      *===============================================================
      * ScoreEmployment - Score based on employment stability
      *===============================================================
     P ScoreEmployment...
     P                 B
     D ScoreEmployment...
     D                 PI             5P 2
     D  pYears                        3S 0 CONST

     D wScore          S               5P 2

      /FREE

       IF pYears >= 10;
         wScore = 100;
       ELSEIF pYears >= 5;
         wScore = 80;
       ELSEIF pYears >= 2;
         wScore = 60;
       ELSEIF pYears >= 1;
         wScore = 40;
       ELSE;
         wScore = 20;
       ENDIF;

       RETURN wScore;

      /END-FREE
     P ScoreEmployment...
     P                 E

      *===============================================================
      * Supporting procedures for decision-making
      *===============================================================
     P DetermineRiskLevel...
     P                 B
     D DetermineRiskLevel...
     D                 PI             1A
     D  pScore                        3S 0 CONST

      /FREE

       IF pScore >= 720;
         RETURN RISK_LOW;
       ELSEIF pScore >= 640;
         RETURN RISK_MEDIUM;
       ELSE;
         RETURN RISK_HIGH;
       ENDIF;

      /END-FREE
     P DetermineRiskLevel...
     P                 E

     P DetermineRecommendation...
     P                 B
     D DetermineRecommendation...
     D                 PI             1A
     D  pScore                        3S 0 CONST

      /FREE

       IF pScore >= APPROVE_THRESHOLD;
         RETURN 'A';  // Approve
       ELSEIF pScore >= REVIEW_THRESHOLD;
         RETURN 'R';  // Review
       ELSE;
         RETURN 'D';  // Deny
       ENDIF;

      /END-FREE
     P DetermineRecommendation...
     P                 E

     P CalculateMaxLoan...
     P                 B
     D CalculateMaxLoan...
     D                 PI            15P 2
     D  pScore                        3S 0 CONST
     D  pIncome                      15P 2 CONST

     D wMaxLoan        S              15P 2

      /FREE

       // Max loan based on income and score
       IF pScore >= 750;
         wMaxLoan = pIncome * 5;  // 5x income
       ELSEIF pScore >= 700;
         wMaxLoan = pIncome * 4;
       ELSEIF pScore >= 650;
         wMaxLoan = pIncome * 3;
       ELSE;
         wMaxLoan = pIncome * 2;
       ENDIF;

       RETURN wMaxLoan;

      /END-FREE
     P CalculateMaxLoan...
     P                 E

     P CalculateRate   B
     D CalculateRate   PI             5P 4
     D  pScore                        3S 0 CONST

     D wRate           S               5P 4

      /FREE

       // Interest rate based on credit score
       IF pScore >= 760;
         wRate = 3.5;
       ELSEIF pScore >= 720;
         wRate = 4.0;
       ELSEIF pScore >= 680;
         wRate = 5.0;
       ELSEIF pScore >= 640;
         wRate = 6.5;
       ELSE;
         wRate = 8.5;
       ENDIF;

       RETURN wRate;

      /END-FREE
     P CalculateRate   E

     P BuildFactorsSummary...
     P                 B
     D BuildFactorsSummary...
     D                 PI           200A
     D  pPayment                     5P 2 CONST
     D  pDebt                        5P 2 CONST
     D  pAge                         5P 2 CONST
     D  pIncome                      5P 2 CONST
     D  pEmploy                      5P 2 CONST

     D wSummary        S             200A

      /FREE

       wSummary = 'Payment:' + %TRIM(%CHAR(pPayment)) +
                  ' Debt:' + %TRIM(%CHAR(pDebt)) +
                  ' Age:' + %TRIM(%CHAR(pAge)) +
                  ' Income:' + %TRIM(%CHAR(pIncome)) +
                  ' Employment:' + %TRIM(%CHAR(pEmploy));

       RETURN wSummary;

      /END-FREE
     P BuildFactorsSummary...
     P                 E
