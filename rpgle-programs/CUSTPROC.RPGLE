      *===============================================================
      * Program: CUSTPROC (Customer Processing)
      * Description: Customer Master CRUD operations for FSI banking
      * Language: RPG ILE (Free Format)
      * Created: 2010-01-15
      * Modified: 2024-11-20
      *===============================================================
      * This program demonstrates typical RPG pattern for database
      * operations including validation, error handling, and audit
      *===============================================================

     H DFTACTGRP(*NO) ACTGRP(*CALLER) BNDDIR('BANKLIB/BANKBND')

      *===============================================================
      * File Specifications
      *===============================================================
     FCUSTMAST  UF   E           K DISK    COMMIT

      *===============================================================
      * Data Structures
      *===============================================================
     D CustomerDS      DS                  QUALIFIED
     D  CustomerId                   10A
     D  SSN                           9S 0
     D  FirstName                    25A
     D  LastName                     25A
     D  MiddleInit                    1A
     D  DateOfBirth                   8S 0
     D  Email                        50A
     D  Phone                        10S 0
     D  Address1                     40A
     D  Address2                     40A
     D  City                         30A
     D  State                         2A
     D  ZipCode                       9S 0
     D  Country                       3A
     D  Status                        1A
     D  CreditScore                   3S 0
     D  RiskLevel                     1A

     D ResponseDS      DS                  QUALIFIED
     D  Success                       1A
     D  ErrorCode                     5A
     D  ErrorMsg                     80A

     D ValidationDS    DS                  QUALIFIED
     D  ValidSSN                      1N
     D  ValidEmail                    1N
     D  ValidPhone                    1N
     D  ValidZip                      1N
     D  DuplicateSSN                  1N

      *===============================================================
      * Standalone Variables
      *===============================================================
     D CurrentDate     S               8S 0
     D CurrentTime     S               6S 0
     D CurrentUser     S              10A
     D Operation       S              10A
     D ErrorFound      S               1N

      *===============================================================
      * Procedure Prototypes
      *===============================================================
     D CreateCustomer  PR                  LIKE(ResponseDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D UpdateCustomer  PR                  LIKE(ResponseDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D GetCustomer     PR                  LIKE(CustomerDS)
     D  pCustomerId                   10A   CONST

     D DeleteCustomer  PR                  LIKE(ResponseDS)
     D  pCustomerId                   10A   CONST

     D ValidateCustomer...
     D                 PR                  LIKEDS(ValidationDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D ValidateSSN     PR              1N
     D  pSSN                          9S 0 CONST

     D ValidateEmail   PR              1N
     D  pEmail                       50A   CONST

     D CheckDuplicateSSN...
     D                 PR              1N
     D  pSSN                          9S 0 CONST
     D  pCustomerId                   10A   CONST

     D GenerateCustomerId...
     D                 PR            10A

     D CalculateCreditScore...
     D                 PR             3S 0
     D  pCustomer                          LIKEDS(CustomerDS)

     D GetCurrentDateTime...
     D                 PR
     D  pDate                         8S 0
     D  pTime                         6S 0

      *===============================================================
      * Main Procedure - Entry Point
      *===============================================================
      /FREE

       // This is a called program, not a main program
       // Main entry point would call these procedures based on operation

       *INLR = *ON;
       RETURN;

      /END-FREE

      *===============================================================
      * CreateCustomer - Add new customer to database
      *===============================================================
     P CreateCustomer  B                   EXPORT
     D CreateCustomer  PI                  LIKE(ResponseDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D wResponse       DS                  LIKEDS(ResponseDS)
     D wValidation     DS                  LIKEDS(ValidationDS)
     D wCustomerId     S              10A

      /FREE

       // Initialize response
       wResponse.Success = 'N';
       wResponse.ErrorCode = '';
       wResponse.ErrorMsg = '';

       // Validate customer data
       wValidation = ValidateCustomer(pCustomer);

       IF NOT wValidation.ValidSSN;
         wResponse.ErrorCode = 'E0001';
         wResponse.ErrorMsg = 'Invalid SSN format';
         RETURN wResponse;
       ENDIF;

       IF NOT wValidation.ValidEmail;
         wResponse.ErrorCode = 'E0002';
         wResponse.ErrorMsg = 'Invalid email format';
         RETURN wResponse;
       ENDIF;

       IF NOT wValidation.ValidPhone;
         wResponse.ErrorCode = 'E0003';
         wResponse.ErrorMsg = 'Invalid phone number';
         RETURN wResponse;
       ENDIF;

       IF wValidation.DuplicateSSN;
         wResponse.ErrorCode = 'E0004';
         wResponse.ErrorMsg = 'SSN already exists';
         RETURN wResponse;
       ENDIF;

       // Generate new customer ID
       wCustomerId = GenerateCustomerId();

       // Get current date/time and user
       GetCurrentDateTime(CurrentDate : CurrentTime);
       CurrentUser = %USER;

       // Calculate credit score
       pCustomer.CreditScore = CalculateCreditScore(pCustomer);

       // Determine risk level based on credit score
       IF pCustomer.CreditScore >= 700;
         pCustomer.RiskLevel = 'L';
       ELSEIF pCustomer.CreditScore >= 600;
         pCustomer.RiskLevel = 'M';
       ELSE;
         pCustomer.RiskLevel = 'H';
       ENDIF;

       // Write record to database
       CUSTID = wCustomerId;
       SSN = pCustomer.SSN;
       FNAME = pCustomer.FirstName;
       LNAME = pCustomer.LastName;
       MNAME = pCustomer.MiddleInit;
       DOB = pCustomer.DateOfBirth;
       EMAIL = pCustomer.Email;
       PHONE = pCustomer.Phone;
       ADDR1 = pCustomer.Address1;
       ADDR2 = pCustomer.Address2;
       CITY = pCustomer.City;
       STATE = pCustomer.State;
       ZIP = pCustomer.ZipCode;
       COUNTRY = pCustomer.Country;
       STATUS = 'A';  // Active
       CREDSCOR = pCustomer.CreditScore;
       RISKLVL = pCustomer.RiskLevel;
       CRTDATE = CurrentDate;
       CRTTIME = CurrentTime;
       CRTUSER = CurrentUser;
       UPDDATE = CurrentDate;
       UPDTIME = CurrentTime;
       UPDUSER = CurrentUser;

       WRITE CUSTREC;

       IF %ERROR;
         wResponse.ErrorCode = 'E0099';
         wResponse.ErrorMsg = 'Database write error';
         ROLLBACK;
       ELSE;
         wResponse.Success = 'Y';
         wResponse.ErrorMsg = 'Customer created: ' + wCustomerId;
         COMMIT;
       ENDIF;

       RETURN wResponse;

      /END-FREE
     P CreateCustomer  E

      *===============================================================
      * UpdateCustomer - Update existing customer
      *===============================================================
     P UpdateCustomer  B                   EXPORT
     D UpdateCustomer  PI                  LIKE(ResponseDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D wResponse       DS                  LIKEDS(ResponseDS)
     D wValidation     DS                  LIKEDS(ValidationDS)

      /FREE

       wResponse.Success = 'N';

       // Validate customer data
       wValidation = ValidateCustomer(pCustomer);

       IF NOT wValidation.ValidEmail;
         wResponse.ErrorCode = 'E0002';
         wResponse.ErrorMsg = 'Invalid email format';
         RETURN wResponse;
       ENDIF;

       // Read and lock record
       CHAIN pCustomer.CustomerId CUSTREC;

       IF NOT %FOUND(CUSTMAST);
         wResponse.ErrorCode = 'E0005';
         wResponse.ErrorMsg = 'Customer not found';
         RETURN wResponse;
       ENDIF;

       // Get current date/time
       GetCurrentDateTime(CurrentDate : CurrentTime);
       CurrentUser = %USER;

       // Update fields
       FNAME = pCustomer.FirstName;
       LNAME = pCustomer.LastName;
       MNAME = pCustomer.MiddleInit;
       EMAIL = pCustomer.Email;
       PHONE = pCustomer.Phone;
       ADDR1 = pCustomer.Address1;
       ADDR2 = pCustomer.Address2;
       CITY = pCustomer.City;
       STATE = pCustomer.State;
       ZIP = pCustomer.ZipCode;
       STATUS = pCustomer.Status;
       UPDDATE = CurrentDate;
       UPDTIME = CurrentTime;
       UPDUSER = CurrentUser;

       UPDATE CUSTREC;

       IF %ERROR;
         wResponse.ErrorCode = 'E0099';
         wResponse.ErrorMsg = 'Database update error';
         ROLLBACK;
       ELSE;
         wResponse.Success = 'Y';
         wResponse.ErrorMsg = 'Customer updated successfully';
         COMMIT;
       ENDIF;

       RETURN wResponse;

      /END-FREE
     P UpdateCustomer  E

      *===============================================================
      * GetCustomer - Retrieve customer by ID
      *===============================================================
     P GetCustomer     B                   EXPORT
     D GetCustomer     PI                  LIKE(CustomerDS)
     D  pCustomerId                   10A   CONST

     D wCustomer       DS                  LIKEDS(CustomerDS)

      /FREE

       CHAIN pCustomerId CUSTREC;

       IF %FOUND(CUSTMAST);
         wCustomer.CustomerId = CUSTID;
         wCustomer.SSN = SSN;
         wCustomer.FirstName = FNAME;
         wCustomer.LastName = LNAME;
         wCustomer.MiddleInit = MNAME;
         wCustomer.DateOfBirth = DOB;
         wCustomer.Email = EMAIL;
         wCustomer.Phone = PHONE;
         wCustomer.Address1 = ADDR1;
         wCustomer.Address2 = ADDR2;
         wCustomer.City = CITY;
         wCustomer.State = STATE;
         wCustomer.ZipCode = ZIP;
         wCustomer.Country = COUNTRY;
         wCustomer.Status = STATUS;
         wCustomer.CreditScore = CREDSCOR;
         wCustomer.RiskLevel = RISKLVL;
       ENDIF;

       RETURN wCustomer;

      /END-FREE
     P GetCustomer     E

      *===============================================================
      * ValidateCustomer - Comprehensive validation
      *===============================================================
     P ValidateCustomer...
     P                 B
     D ValidateCustomer...
     D                 PI                  LIKEDS(ValidationDS)
     D  pCustomer                          LIKEDS(CustomerDS)

     D wValidation     DS                  LIKEDS(ValidationDS)

      /FREE

       wValidation.ValidSSN = ValidateSSN(pCustomer.SSN);
       wValidation.ValidEmail = ValidateEmail(pCustomer.Email);
       wValidation.ValidPhone = (pCustomer.Phone > 1000000000);
       wValidation.ValidZip = (pCustomer.ZipCode > 10000);
       wValidation.DuplicateSSN =
         CheckDuplicateSSN(pCustomer.SSN : pCustomer.CustomerId);

       RETURN wValidation;

      /END-FREE
     P ValidateCustomer...
     P                 E

      *===============================================================
      * ValidateSSN - Check SSN format (simple Luhn check simulation)
      *===============================================================
     P ValidateSSN     B
     D ValidateSSN     PI              1N
     D  pSSN                          9S 0 CONST

      /FREE

       // Simple validation: 9 digits, not all zeros
       IF pSSN > 100000000 AND pSSN < 999999999;
         RETURN *ON;
       ENDIF;

       RETURN *OFF;

      /END-FREE
     P ValidateSSN     E

      *===============================================================
      * ValidateEmail - Basic email format check
      *===============================================================
     P ValidateEmail   B
     D ValidateEmail   PI              1N
     D  pEmail                       50A   CONST

      /FREE

       // Simple check for @ symbol and minimum length
       IF %SCAN('@' : pEmail) > 0 AND %LEN(%TRIM(pEmail)) > 5;
         RETURN *ON;
       ENDIF;

       RETURN *OFF;

      /END-FREE
     P ValidateEmail   E

      *===============================================================
      * CheckDuplicateSSN - Verify SSN uniqueness
      *===============================================================
     P CheckDuplicateSSN...
     P                 B
     D CheckDuplicateSSN...
     D                 PI              1N
     D  pSSN                          9S 0 CONST
     D  pCustomerId                   10A   CONST

      /FREE

       // Use SQL to check for duplicate SSN
       EXEC SQL
         SELECT COUNT(*)
         INTO :ErrorFound
         FROM CUSTMAST
         WHERE SSN = :pSSN
           AND CUSTID <> :pCustomerId;

       IF ErrorFound > 0;
         RETURN *ON;
       ENDIF;

       RETURN *OFF;

      /END-FREE
     P CheckDuplicateSSN...
     P                 E

      *===============================================================
      * GenerateCustomerId - Create unique customer ID
      *===============================================================
     P GenerateCustomerId...
     P                 B
     D GenerateCustomerId...
     D                 PI            10A

     D wCustomerId     S              10A
     D wCounter        S              10S 0
     D wDate           S               8S 0
     D wTime           S               6S 0

      /FREE

       // Generate ID: CUST + YYMMDD + sequence
       GetCurrentDateTime(wDate : wTime);
       wCustomerId = 'C' + %CHAR(wDate) + %CHAR(wTime);

       RETURN wCustomerId;

      /END-FREE
     P GenerateCustomerId...
     P                 E

      *===============================================================
      * CalculateCreditScore - Basic credit scoring algorithm
      *===============================================================
     P CalculateCreditScore...
     P                 B
     D CalculateCreditScore...
     D                 PI             3S 0
     D  pCustomer                          LIKEDS(CustomerDS)

     D wScore          S              3S 0

      /FREE

       // Simplified credit scoring
       wScore = 650;  // Base score

       // Placeholder for actual credit bureau integration
       // In real system: call external service, check payment history, etc.

       RETURN wScore;

      /END-FREE
     P CalculateCreditScore...
     P                 E

      *===============================================================
      * GetCurrentDateTime - Get system date and time
      *===============================================================
     P GetCurrentDateTime...
     P                 B
     D GetCurrentDateTime...
     D                 PI
     D  pDate                         8S 0
     D  pTime                         6S 0

     D wTimestamp      S               Z
     D wDateChar       S              10A
     D wTimeChar       S               8A

      /FREE

       wTimestamp = %TIMESTAMP();
       wDateChar = %CHAR(wTimestamp);

       // Extract YYYYMMDD
       pDate = %DEC(%SUBST(wDateChar:1:4) +
                     %SUBST(wDateChar:6:2) +
                     %SUBST(wDateChar:9:2) : 8 : 0);

       // Extract HHMMSS
       wTimeChar = %SUBST(wDateChar:12:8);
       pTime = %DEC(%SUBST(wTimeChar:1:2) +
                     %SUBST(wTimeChar:4:2) +
                     %SUBST(wTimeChar:7:2) : 6 : 0);

      /END-FREE
     P GetCurrentDateTime...
     P                 E
