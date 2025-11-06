# RPG/RPGLE Programming Conventions & Patterns

## Overview

This document describes the RPG/RPGLE coding standards, patterns, and idioms used in the legacy banking system. Follow these conventions when maintaining or extending RPG programs.

## File Specifications

### Physical Files (DDS)

**Naming Convention:**
- Maximum 8 characters
- Descriptive abbreviation: `CUSTMAST`, `ACCTMAST`, `TRANLOG`
- Suffix `.PF` for physical files

**Key Fields:**
- Always define unique keys
- Use composite keys when needed
- Index foreign key fields

**Example:**
```
     A          R CUSTMASTR
     A            CUSTID        10A         COLHDG('Customer' 'ID')
     A                                      TEXT('Unique customer identifier')
     A            SSN            9S 0       COLHDG('SSN')
     A                                      TEXT('Social Security Number')
     A            FNAME         50A         COLHDG('First' 'Name')
     A            LNAME         50A         COLHDG('Last' 'Name')
     A          K CUSTID
     A          K SSN
```

### Program Files (RPGLE)

**File Control Specifications:**
```rpg
FCUSTMAST  UF   E           K DISK    COMMIT
FACCTMAST  UF   E           K DISK    COMMIT
FTRANLOG   O    E             DISK    COMMIT
```

**Flags:**
- `U` = Update
- `F` = Full procedural
- `E` = Externally described
- `K` = Keyed access
- `DISK` = Database file
- `COMMIT` = Commitment control enabled

## Data Structures

### Qualified Data Structures

**Pattern:**
```rpg
D CustomerDS      DS                  QUALIFIED
D  CustomerId                   10A
D  SSN                           9S 0
D  FirstName                    50A
D  LastName                     50A
D  Email                       100A
D  Phone                        15A
D  CreditScore                   9S 0
D  RiskLevel                     1A
D  Status                        1A
```

**Benefits:**
- Namespacing prevents field name collisions
- Better organization and readability
- Use dot notation: `CustomerDS.CustomerId`

### LIKEDS for Type Reuse

```rpg
D CustomerDS      DS                  QUALIFIED
D  CustomerId                   10A
D  FirstName                    50A
// ... other fields

D Customer1       DS                  LIKEDS(CustomerDS)
D Customer2       DS                  LIKEDS(CustomerDS)
```

### Response Data Structure Pattern

```rpg
D ResponseDS      DS                  QUALIFIED
D  Success                       1A
D  ErrorCode                     5A
D  ErrorMsg                     80A
D  RecordCount                   9S 0
```

## Procedure Definitions

### Procedure Pattern

```rpg
P CreateCustomer  B                   EXPORT
D CreateCustomer  PI            10A
D  pSSN                          9S 0 CONST
D  pFirstName                   50A   CONST
D  pLastName                    50A   CONST
D  pEmail                      100A   CONST OPTIONS(*NOPASS)

D wCustomerId     S             10A
D wErrorFlag      S              1A   INZ('N')

 /FREE
  // Validate SSN is unique
  CHAIN pSSN CUSTMAST;
  IF %FOUND(CUSTMAST);
    RETURN *BLANKS;  // Duplicate SSN
  ENDIF;

  // Generate customer ID
  wCustomerId = %CHAR(%TIMESTAMP());
  wCustomerId = %SUBST(wCustomerId:1:10);

  // Create customer record
  CUSTID = wCustomerId;
  SSN = pSSN;
  FNAME = pFirstName;
  LNAME = pLastName;
  IF %PARMS >= 4;
    EMAIL = pEmail;
  ENDIF;
  STATUS = 'A';
  CRTDATE = %DEC(%CHAR(%DATE():*ISO):8:0);
  CRTTIME = %DEC(%CHAR(%TIME():*ISO):6:0);
  CRTUSER = %USER;

  WRITE CUSTMASTR;
  IF %ERROR;
    ROLLBACK;
    RETURN *BLANKS;
  ELSE;
    COMMIT;
    RETURN wCustomerId;
  ENDIF;

 /END-FREE
P CreateCustomer  E
```

**Key Elements:**
- `B` = Begin procedure
- `E` = End procedure
- `EXPORT` = Callable from other programs
- `PI` = Procedure interface
- `CONST` = Parameter passed by value (read-only)
- `OPTIONS(*NOPASS)` = Optional parameter
- `%PARMS` = Number of parameters passed

### Procedure Documentation Header

```rpg
//*============================================================
//* Procedure: ProcessTransaction
//* Description: Process deposit, withdrawal, or transfer
//*              with ACID compliance and audit logging
//* Parameters:
//*   pTransType   - Transaction type (DP/WD/TF)
//*   pAccountId   - Source account ID
//*   pAmount      - Transaction amount
//*   pTargetAcct  - Target account (for transfers only)
//* Returns: 
//*   Transaction ID on success
//*   *BLANKS on failure
//* Error Codes:
//*   E1001 - Invalid account
//*   E1002 - Insufficient funds
//*   E1003 - Account frozen
//* Author: Banking Team
//* Created: 2025-01-01
//* Modified: 2025-01-15 - Added overdraft protection
//*============================================================
```

## Naming Conventions

### Variables

**Prefixes:**
- `w` = Work/local variable (e.g., `wCustomerId`, `wBalance`)
- `p` = Parameter (e.g., `pAccountId`, `pAmount`)
- `c` = Constant (e.g., `cBaseScore`, `cMaxAttempts`)
- `g` = Global variable (avoid if possible)

**Examples:**
```rpg
D wCustomerId     S             10A
D wAccountBal     S             15P 2
D wTransDate      S              8S 0
D wTransTime      S              6S 0
D wErrorMsg       S             80A
D wRecordCount    S              9S 0

D pAccountId      S             12A
D pAmount         S             15P 2

D cBaseScore      C                   600
D cApproveThrsh   C                   680
```

### Constants

```rpg
D BASE_SCORE      C                   600
D APPROVE_THRESHOLD...
D                 C                   680
D REVIEW_THRESHOLD...
D                 C                   620
D MAX_OVERDRAFT   C                   1000.00
```

### Procedure Names

**Pattern:** PascalCase with verb-first naming
- `CreateCustomer`
- `UpdateAccountBalance`
- `CalculateCreditScore`
- `ProcessTransaction`
- `ValidateSSN`
- `GetCustomerById`

## Data Types

### Common Type Specifications

| Type | Declaration | Description | Example |
|------|-------------|-------------|---------|
| Character | `10A` | 10-byte character | Customer ID |
| Varchar | `VARCHAR(100)` | Variable-length char | Email |
| Integer | `9S 0` | 9-digit signed integer | Credit score |
| Packed Decimal | `15P 2` | 15 digits, 2 decimals | Currency amount |
| Date | `8S 0` | YYYYMMDD numeric | 20250115 |
| Time | `6S 0` | HHMMSS numeric | 143058 |
| Indicator | `1A` | Single character flag | Y/N, A/I |

### Date/Time Handling

**Current Date/Time:**
```rpg
D wCurrentDate    S              8S 0
D wCurrentTime    S              6S 0
D wTimestamp      S               Z

wTimestamp = %TIMESTAMP();
wCurrentDate = %DEC(%CHAR(%DATE():*ISO):8:0);  // YYYYMMDD
wCurrentTime = %DEC(%CHAR(%TIME():*ISO):6:0);  // HHMMSS
```

**Date Arithmetic:**
```rpg
D wDate           S               D   DATFMT(*ISO)
D wDatePlus30     S               D   DATFMT(*ISO)

wDate = %DATE();
wDatePlus30 = wDate + %DAYS(30);
```

## Built-in Functions (BIFs)

### Commonly Used BIFs

| BIF | Purpose | Example |
|-----|---------|---------|
| `%TRIM()` | Remove trailing spaces | `%TRIM(CustomerDS.FirstName)` |
| `%CHAR()` | Convert to character | `%CHAR(wCreditScore)` |
| `%DEC()` | Convert to decimal | `%DEC(wAmount:15:2)` |
| `%INT()` | Convert to integer | `%INT(wBalance)` |
| `%SCAN()` | Search string | `%SCAN('@':wEmail)` |
| `%SUBST()` | Extract substring | `%SUBST(wName:1:10)` |
| `%LEN()` | String length | `%LEN(%TRIM(wName))` |
| `%FOUND()` | Record found check | `%FOUND(CUSTMAST)` |
| `%ERROR()` | Error occurred check | `%ERROR()` |
| `%PARMS()` | Parameters passed | `%PARMS() >= 4` |
| `%USER` | Current user | `CRTUSER = %USER` |
| `%DATE()` | Current date | `%DATE()` |
| `%TIME()` | Current time | `%TIME()` |
| `%TIMESTAMP()` | Current timestamp | `%TIMESTAMP()` |

## Database Operations

### Random Access with CHAIN

```rpg
CHAIN pCustomerId CUSTMAST;
IF %FOUND(CUSTMAST);
  // Record found - process it
  wName = %TRIM(FNAME) + ' ' + %TRIM(LNAME);
ELSE;
  // Record not found - handle error
  wErrorMsg = 'Customer not found';
ENDIF;
```

### Sequential Access with SETLL/READE

```rpg
SETLL pCustomerId CUSTMAST;
READE pCustomerId CUSTMAST;
DOW NOT %EOF(CUSTMAST);
  // Process each record
  wRecordCount += 1;
  READE pCustomerId CUSTMAST;
ENDDO;
```

### Update with Record Locking

```rpg
CHAIN (pAccountId) ACCTMAST;
IF %FOUND(ACCTMAST);
  // Lock acquired - safe to update
  BALANCE = BALANCE - pAmount;
  AVAILBAL = BALANCE - HOLDAMT;
  UPDDATE = wCurrentDate;
  UPDTIME = wCurrentTime;
  UPDUSER = %USER;
  
  UPDATE ACCTMASTR;
  IF %ERROR();
    ROLLBACK;
    wSuccess = 'N';
  ELSE;
    COMMIT;
    wSuccess = 'Y';
  ENDIF;
ENDIF;
```

### Insert New Record

```rpg
CUSTID = wCustomerId;
SSN = pSSN;
FNAME = pFirstName;
LNAME = pLastName;
STATUS = 'A';
CRTDATE = wCurrentDate;
CRTTIME = wCurrentTime;
CRTUSER = %USER;

WRITE CUSTMASTR;
IF %ERROR();
  ROLLBACK;
  wErrorCode = 'E0099';
ELSE;
  COMMIT;
  wErrorCode = *BLANKS;
ENDIF;
```

### Delete Record

```rpg
CHAIN pCustomerId CUSTMAST;
IF %FOUND(CUSTMAST);
  DELETE CUSTMASTR;
  IF %ERROR();
    ROLLBACK;
  ELSE;
    COMMIT;
  ENDIF;
ENDIF;
```

## Embedded SQL

### SQL Queries

```rpg
EXEC SQL
  SELECT CUSTID, FNAME, LNAME, CREDITSCORE
  INTO :wCustomerId, :wFirstName, :wLastName, :wCreditScore
  FROM CUSTMAST
  WHERE SSN = :pSSN;

IF SQLSTATE = '00000';
  // Query successful
ELSE;
  // Handle SQL error
  wErrorMsg = 'SQL Error: ' + SQLSTATE;
ENDIF;
```

### SQL Aggregations

```rpg
EXEC SQL
  SELECT COUNT(*), COALESCE(AVG(BALANCE), 0)
  INTO :wTotalAccounts, :wAvgBalance
  FROM ACCTMAST
  WHERE CUSTID = :pCustomerId
    AND STATUS = 'A';
```

### SQL Cursor for Large Result Sets

```rpg
EXEC SQL
  DECLARE C1 CURSOR FOR
  SELECT ACCTID, ACCTTYPE, BALANCE
  FROM ACCTMAST
  WHERE CUSTID = :pCustomerId
  ORDER BY ACCTID;

EXEC SQL OPEN C1;

DOW SQLSTATE = '00000';
  EXEC SQL
    FETCH NEXT FROM C1
    INTO :wAccountId, :wAccountType, :wBalance;
  
  IF SQLSTATE = '00000';
    // Process record
    wTotalBalance += wBalance;
  ENDIF;
ENDDO;

EXEC SQL CLOSE C1;
```

### SQL with Host Variables

**Host Variable Prefix:** Always use colon (`:`) prefix
```rpg
D wCustomerId     S             10A
D wBalance        S             15P 2

EXEC SQL
  UPDATE ACCTMAST
  SET BALANCE = BALANCE + :wAmount,
      UPDDATE = :wCurrentDate,
      UPDTIME = :wCurrentTime,
      UPDUSER = :wCurrentUser
  WHERE ACCTID = :wAccountId;
```

## Commitment Control

### Transaction Pattern

```rpg
// File specs with COMMIT keyword
FCUSTMAST  UF   E           K DISK    COMMIT
FACCTMAST  UF   E           K DISK    COMMIT
FTRANLOG   O    E             DISK    COMMIT

// Transaction processing
CHAIN pAccountId ACCTMAST;
IF %FOUND(ACCTMAST) AND STATUS = 'A';
  
  // Update account balance
  BALANCE = BALANCE - pAmount;
  UPDATE ACCTMASTR;
  
  // Log transaction
  TRANID = wTransactionId;
  ACCTID = pAccountId;
  TRANTYPE = 'WD';
  AMOUNT = pAmount;
  BALAFTER = BALANCE;
  WRITE TRANLOGR;
  
  // Check for errors
  IF %ERROR();
    ROLLBACK;
    wResponse.Success = 'N';
    wResponse.ErrorCode = 'E1099';
  ELSE;
    COMMIT;
    wResponse.Success = 'Y';
  ENDIF;
  
ENDIF;
```

### Multi-File Transaction

```rpg
// Debit source account
CHAIN pSourceAcct ACCTMAST;
IF %FOUND(ACCTMAST);
  BALANCE = BALANCE - pAmount;
  UPDATE ACCTMASTR;
ENDIF;

// Credit target account
CHAIN pTargetAcct ACCTMAST;
IF %FOUND(ACCTMAST);
  BALANCE = BALANCE + pAmount;
  UPDATE ACCTMASTR;
ENDIF;

// Log transaction
WRITE TRANLOGR;

// Commit or rollback all
IF %ERROR();
  ROLLBACK;  // Undo all changes
ELSE;
  COMMIT;    // Make all changes permanent
ENDIF;
```

## Error Handling

### Check After Every Database Operation

```rpg
UPDATE ACCTMASTR;
IF %ERROR();
  ROLLBACK;
  wErrorCode = 'E1001';
  wErrorMsg = 'Failed to update account';
  RETURN wErrorCode;
ENDIF;
```

### Error Code Pattern

```rpg
D ERROR_SUCCESS   C                   '00000'
D ERROR_NOT_FOUND C                   'E0001'
D ERROR_DUPLICATE C                   'E0002'
D ERROR_INVALID   C                   'E0003'
D ERROR_INSUFF_FUNDS...
D                 C                   'E1002'
D ERROR_FROZEN    C                   'E1003'
```

### Error Response Pattern

```rpg
D ResponseDS      DS                  QUALIFIED
D  Success                       1A   INZ('N')
D  ErrorCode                     5A   INZ(*BLANKS)
D  ErrorMsg                     80A   INZ(*BLANKS)

// On error
wResponse.Success = 'N';
wResponse.ErrorCode = 'E1002';
wResponse.ErrorMsg = 'Insufficient funds for withdrawal';
RETURN wResponse;

// On success
wResponse.Success = 'Y';
wResponse.ErrorCode = *BLANKS;
wResponse.ErrorMsg = *BLANKS;
RETURN wResponse;
```

## Validation Patterns

### SSN Validation

```rpg
P ValidateSSN     B                   EXPORT
D ValidateSSN     PI             1N
D  pSSN                          9S 0 CONST

 /FREE
  // Check for all zeros
  IF pSSN = 0;
    RETURN *OFF;
  ENDIF;
  
  // Check for known invalid SSNs
  IF pSSN = 123456789;
    RETURN *OFF;
  ENDIF;
  
  // Check for reasonable range
  IF pSSN < 1000000 OR pSSN > 999999999;
    RETURN *OFF;
  ENDIF;
  
  RETURN *ON;
 /END-FREE
P ValidateSSN     E
```

### Email Validation

```rpg
P ValidateEmail   B                   EXPORT
D ValidateEmail   PI             1N
D  pEmail                      100A   CONST

D wAtPos          S              9S 0
D wDotPos         S              9S 0
D wLength         S              9S 0

 /FREE
  wEmail = %TRIM(pEmail);
  wLength = %LEN(wEmail);
  
  // Must contain @
  wAtPos = %SCAN('@':wEmail);
  IF wAtPos = 0 OR wAtPos = 1 OR wAtPos = wLength;
    RETURN *OFF;
  ENDIF;
  
  // Must contain . after @
  wDotPos = %SCAN('.':wEmail:wAtPos);
  IF wDotPos = 0 OR wDotPos = wLength;
    RETURN *OFF;
  ENDIF;
  
  RETURN *ON;
 /END-FREE
P ValidateEmail   E
```

## Audit Trail Pattern

### Always Update Audit Fields

```rpg
// On INSERT
CRTDATE = %DEC(%CHAR(%DATE():*ISO):8:0);
CRTTIME = %DEC(%CHAR(%TIME():*ISO):6:0);
CRTUSER = %USER;

// On UPDATE
UPDDATE = %DEC(%CHAR(%DATE():*ISO):8:0);
UPDTIME = %DEC(%CHAR(%TIME():*ISO):6:0);
UPDUSER = %USER;
```

### Audit Utility Procedure

```rpg
P GetDateTime     B                   EXPORT
D GetDateTime     PI
D  pDate                         8S 0
D  pTime                         6S 0

 /FREE
  pDate = %DEC(%CHAR(%DATE():*ISO):8:0);
  pTime = %DEC(%CHAR(%TIME():*ISO):6:0);
 /END-FREE
P GetDateTime     E
```

## Comments & Documentation

### File Header

```rpg
//*====================================================================
//* Program: CUSTPROC
//* Description: Customer management procedures - CRUD operations
//*              with credit score calculation and audit trail
//* Author: Banking Team
//* Created: 2025-01-01
//* Library: BANKLIB
//* Binding Directory: BANKLIB/BANKBND
//*====================================================================
//* Change Log:
//* Date       User    Description
//* 2025-01-01 DEVTEAM Initial version
//* 2025-01-15 DEVTEAM Added email validation
//*====================================================================
```

### Inline Comments

```rpg
// Calculate weighted credit score components
wPaymentScore = %INT(pPaymentHistory * 0.35);  // 35% weight
wDebtScore = %INT((100 - pDebtRatio) * 0.30);  // 30% weight
wAgeScore = %INT(pCreditAge * 0.15);           // 15% weight

// Cap scores at maximum values
IF wPaymentScore > 150;
  wPaymentScore = 150;
ENDIF;
```

## Common Idioms

### Check If Record Exists

```rpg
CHAIN pCustomerId CUSTMAST;
IF %FOUND(CUSTMAST);
  // Exists - handle duplicate
ELSE;
  // Does not exist - safe to insert
ENDIF;
```

### Count Records with SQL

```rpg
EXEC SQL
  SELECT COUNT(*)
  INTO :wRecordCount
  FROM CUSTMAST
  WHERE STATUS = 'A';
```

### Loop Through File

```rpg
SETLL *LOVAL CUSTMAST;
READ CUSTMAST;
DOW NOT %EOF(CUSTMAST);
  // Process record
  wProcessedCount += 1;
  READ CUSTMAST;
ENDDO;
```

### Optional Parameter Handling

```rpg
D CreateCustomer  PI            10A
D  pSSN                          9S 0 CONST
D  pFirstName                   50A   CONST
D  pEmail                      100A   CONST OPTIONS(*NOPASS)

 /FREE
  IF %PARMS() >= 3;
    EMAIL = pEmail;
  ELSE;
    EMAIL = *BLANKS;
  ENDIF;
 /END-FREE
```

## Performance Best Practices

1. **Use SETLL/READE for sequential access** (faster than multiple CHAIN)
2. **Create indexes** on frequently queried fields
3. **Use SQL for aggregations** (COUNT, SUM, AVG)
4. **Minimize record locking scope** - lock only when necessary
5. **Use CONST for read-only parameters** (passed by value)
6. **Avoid reading entire file** unless necessary
7. **Use commitment control** only for transactions (overhead)

## Security Best Practices

1. **Never hardcode passwords** or connection strings
2. **Validate all input parameters** before use
3. **Use parameterized SQL** (avoid string concatenation)
4. **Log security events** (authentication failures, authorization denials)
5. **Mask sensitive data in logs** (SSN, account numbers)
6. **Check authorization** before sensitive operations
