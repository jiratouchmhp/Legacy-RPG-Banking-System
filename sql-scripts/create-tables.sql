-- ===============================================================
-- DB2 for i SQL Script: Create Tables (Alternative to DDS)
-- Description: SQL DDL equivalents of DDS physical files
-- Database: DB2 for i
-- Created: 2024-11-20
-- ===============================================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS BANKLIB.TRANLOG;
DROP TABLE IF EXISTS BANKLIB.ACCTMAST;
DROP TABLE IF EXISTS BANKLIB.CUSTMAST;

-- ===============================================================
-- Customer Master Table
-- ===============================================================
CREATE TABLE BANKLIB.CUSTMAST (
    CUSTID      VARCHAR(10)     NOT NULL,
    SSN         DECIMAL(9, 0)   NOT NULL,
    FNAME       VARCHAR(25)     NOT NULL,
    LNAME       VARCHAR(25)     NOT NULL,
    MNAME       CHAR(1),
    DOB         DECIMAL(8, 0)   NOT NULL,
    EMAIL       VARCHAR(50),
    PHONE       DECIMAL(10, 0),
    ADDR1       VARCHAR(40),
    ADDR2       VARCHAR(40),
    CITY        VARCHAR(30),
    STATE       CHAR(2),
    ZIP         DECIMAL(9, 0),
    COUNTRY     CHAR(3)         DEFAULT 'USA',
    STATUS      CHAR(1)         NOT NULL DEFAULT 'A',
    CREDSCOR    DECIMAL(3, 0)   DEFAULT 650,
    RISKLVL     CHAR(1)         DEFAULT 'M',
    CRTDATE     DECIMAL(8, 0)   NOT NULL,
    CRTTIME     DECIMAL(6, 0)   NOT NULL,
    CRTUSER     VARCHAR(10)     NOT NULL,
    UPDDATE     DECIMAL(8, 0),
    UPDTIME     DECIMAL(6, 0),
    UPDUSER     VARCHAR(10),
    
    CONSTRAINT PK_CUSTMAST PRIMARY KEY (CUSTID),
    CONSTRAINT CHK_STATUS CHECK (STATUS IN ('A', 'I')),
    CONSTRAINT CHK_RISKLVL CHECK (RISKLVL IN ('L', 'M', 'H')),
    CONSTRAINT CHK_CREDSCOR CHECK (CREDSCOR BETWEEN 300 AND 850)
);

-- Create indexes for customer searches
CREATE UNIQUE INDEX BANKLIB.IDX_CUST_SSN ON BANKLIB.CUSTMAST(SSN);
CREATE INDEX BANKLIB.IDX_CUST_NAME ON BANKLIB.CUSTMAST(LNAME, FNAME);
CREATE INDEX BANKLIB.IDX_CUST_STATUS ON BANKLIB.CUSTMAST(STATUS);

LABEL ON TABLE BANKLIB.CUSTMAST IS 'Customer Master';
LABEL ON COLUMN BANKLIB.CUSTMAST.CUSTID IS 'Customer ID';
LABEL ON COLUMN BANKLIB.CUSTMAST.SSN IS 'Social Security Number';

-- ===============================================================
-- Account Master Table
-- ===============================================================
CREATE TABLE BANKLIB.ACCTMAST (
    ACCTID      VARCHAR(12)     NOT NULL,
    CUSTID      VARCHAR(10)     NOT NULL,
    ACCTTYPE    CHAR(2)         NOT NULL,
    BALANCE     DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    AVAILBAL    DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    CURRENCY    CHAR(3)         DEFAULT 'USD',
    STATUS      CHAR(1)         NOT NULL DEFAULT 'A',
    INTRATE     DECIMAL(5, 4)   DEFAULT 0,
    OVERDRAFT   CHAR(1)         DEFAULT 'N',
    ODLIMIT     DECIMAL(15, 2)  DEFAULT 0,
    LASTTRANDT  DECIMAL(8, 0),
    LASTTRANTM  DECIMAL(6, 0),
    OPENDATE    DECIMAL(8, 0)   NOT NULL,
    CLOSEDATE   DECIMAL(8, 0),
    BRANCH      VARCHAR(6),
    ACCTOFFICER VARCHAR(10),
    CRTDATE     DECIMAL(8, 0)   NOT NULL,
    CRTTIME     DECIMAL(6, 0)   NOT NULL,
    CRTUSER     VARCHAR(10)     NOT NULL,
    UPDDATE     DECIMAL(8, 0),
    UPDTIME     DECIMAL(6, 0),
    UPDUSER     VARCHAR(10),
    
    CONSTRAINT PK_ACCTMAST PRIMARY KEY (ACCTID),
    CONSTRAINT FK_ACCT_CUST FOREIGN KEY (CUSTID) 
        REFERENCES BANKLIB.CUSTMAST(CUSTID),
    CONSTRAINT CHK_ACCT_TYPE CHECK (ACCTTYPE IN ('CK', 'SV', 'LN')),
    CONSTRAINT CHK_ACCT_STATUS CHECK (STATUS IN ('A', 'C', 'F')),
    CONSTRAINT CHK_OVERDRAFT CHECK (OVERDRAFT IN ('Y', 'N'))
);

-- Create indexes for account lookups
CREATE INDEX BANKLIB.IDX_ACCT_CUST ON BANKLIB.ACCTMAST(CUSTID);
CREATE INDEX BANKLIB.IDX_ACCT_TYPE ON BANKLIB.ACCTMAST(ACCTTYPE, STATUS);

LABEL ON TABLE BANKLIB.ACCTMAST IS 'Account Master';
LABEL ON COLUMN BANKLIB.ACCTMAST.ACCTID IS 'Account Number';

-- ===============================================================
-- Transaction Log Table
-- ===============================================================
CREATE TABLE BANKLIB.TRANLOG (
    TRANID      VARCHAR(15)     NOT NULL,
    ACCTID      VARCHAR(12)     NOT NULL,
    TRANTYPE    CHAR(2)         NOT NULL,
    AMOUNT      DECIMAL(15, 2)  NOT NULL,
    BALANCE     DECIMAL(15, 2)  NOT NULL,
    TOACCTID    VARCHAR(12),
    TRANDATE    DECIMAL(8, 0)   NOT NULL,
    TRANTIME    DECIMAL(6, 0)   NOT NULL,
    POSTDATE    DECIMAL(8, 0)   NOT NULL,
    POSTTIME    DECIMAL(6, 0)   NOT NULL,
    DESCR       VARCHAR(50),
    REFNUM      VARCHAR(20),
    CHANNEL     CHAR(3),
    STATUS      CHAR(1)         NOT NULL DEFAULT 'P',
    ERRORCODE   VARCHAR(5),
    USERID      VARCHAR(10),
    TERMINAL    VARCHAR(8),
    IPADDR      VARCHAR(15),
    CRTDATE     DECIMAL(8, 0)   NOT NULL,
    CRTTIME     DECIMAL(6, 0)   NOT NULL,
    
    CONSTRAINT PK_TRANLOG PRIMARY KEY (TRANID),
    CONSTRAINT FK_TRAN_ACCT FOREIGN KEY (ACCTID) 
        REFERENCES BANKLIB.ACCTMAST(ACCTID),
    CONSTRAINT CHK_TRAN_TYPE CHECK (TRANTYPE IN ('DP', 'WD', 'TF')),
    CONSTRAINT CHK_TRAN_STATUS CHECK (STATUS IN ('P', 'C', 'R')),
    CONSTRAINT CHK_AMOUNT CHECK (AMOUNT >= 0)
);

-- Create indexes for transaction queries
CREATE INDEX BANKLIB.IDX_TRAN_ACCT ON BANKLIB.TRANLOG(ACCTID, TRANDATE);
CREATE INDEX BANKLIB.IDX_TRAN_DATE ON BANKLIB.TRANLOG(TRANDATE);
CREATE INDEX BANKLIB.IDX_TRAN_STATUS ON BANKLIB.TRANLOG(STATUS);

LABEL ON TABLE BANKLIB.TRANLOG IS 'Transaction Log';
LABEL ON COLUMN BANKLIB.TRANLOG.TRANID IS 'Transaction ID';

-- ===============================================================
-- Grant permissions (adjust as needed)
-- ===============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON BANKLIB.CUSTMAST TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON BANKLIB.ACCTMAST TO PUBLIC;
GRANT SELECT, INSERT ON BANKLIB.TRANLOG TO PUBLIC;

-- ===============================================================
-- Enable journaling for commitment control
-- ===============================================================
-- Note: This would typically be done through CL commands:
-- STRJRNPF FILE(BANKLIB/CUSTMAST) JRN(BANKLIB/BANKJRN)
-- STRJRNPF FILE(BANKLIB/ACCTMAST) JRN(BANKLIB/BANKJRN)
-- STRJRNPF FILE(BANKLIB/TRANLOG) JRN(BANKLIB/BANKJRN)

COMMIT;
