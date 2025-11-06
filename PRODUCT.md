# Legacy Banking System - Product Overview

## Product Vision

A comprehensive financial services banking platform that manages customer accounts, processes real-time transactions, performs credit risk assessment, and maintains regulatory compliance for a financial institution.

## Core Functionality

### 1. Customer Management
- Complete customer lifecycle management (create, read, update, delete)
- Customer profile with demographics and contact information
- SSN-based unique identification with validation
- Credit score tracking and risk level assessment
- Customer status management (Active/Inactive)
- Full audit trail for all customer data changes

### 2. Account Management
- Multiple account types: Checking (CK), Savings (SV), Loan (LN)
- Real-time balance tracking (current and available balance)
- Overdraft protection with configurable limits
- Interest rate management per account
- Account status controls (Active/Closed/Frozen)
- Customer-to-account relationship tracking

### 3. Transaction Processing
- **Transaction Types:**
  - Deposits (DP)
  - Withdrawals (WD)
  - Transfers (TF) between accounts
- **ACID-compliant processing:**
  - Atomic operations with commitment control
  - Isolation through record-level locking
  - Consistent state maintenance
  - Durable transaction logging
- **Real-time validation:**
  - Sufficient funds checking
  - Account status verification
  - Overdraft protection logic
- **Complete audit trail:**
  - Transaction ID tracking
  - Timestamp (date, time, milliseconds)
  - Channel and terminal identification
  - IP address logging
  - Balance before and after
  - Transaction status tracking (Pending/Complete/Reversed)

### 4. Credit Scoring & Risk Assessment
- **Multi-factor credit scoring algorithm:**
  - Payment history (35% weight)
  - Debt-to-income ratio (30% weight)
  - Credit history age (15% weight)
  - Income level (10% weight)
  - Employment stability (10% weight)
- **Score range:** 300-850 (base score: 600)
- **Risk level classification:**
  - Low Risk: 720+
  - Medium Risk: 640-719
  - High Risk: <640
- **Loan recommendations:**
  - Approve: 680+
  - Review: 620-679
  - Deny: <620
- **Interest rate determination:**
  - Tiered rates based on credit score (3.5% to 8.5%)

### 5. End-of-Day Batch Processing
- **Daily Operations:**
  - Database backup procedures
  - Interest calculation and posting
  - Monthly statement generation
  - Transaction archiving (90-day retention)
  - Batch credit score updates
  - Daily reconciliation reports
  - Balance summary reports

## Business Rules

### Customer Management
1. SSN must be unique across all customers
2. Valid email and phone number formats required
3. All customer changes must include audit information (user, date, time)
4. Customer status must be Active to open new accounts

### Account Management
1. Each account must be linked to an active customer
2. Account IDs must be unique (12-character format)
3. Overdraft protection requires explicit flag and limit
4. Frozen accounts cannot process transactions
5. Closed accounts maintain historical data

### Transaction Processing
1. Withdrawals cannot exceed available balance + overdraft limit
2. Both source and target accounts must be Active for transfers
3. All transactions must be logged before completion
4. Failed transactions must be rolled back completely
5. Transaction IDs must be unique and traceable
6. Concurrent transactions use pessimistic locking

### Credit Scoring
1. Credit scores recalculated on customer updates and monthly batch
2. Risk level automatically derived from credit score
3. Loan recommendations follow strict threshold rules
4. Interest rates aligned with risk-based pricing model

### Compliance & Audit
1. All data modifications tracked with user, date, and time
2. Transaction logs retained for regulatory requirements
3. Audit trail immutable after initial creation
4. Date/time stored in consistent format (YYYYMMDD, HHMMSS)

## Target Users

- **Bank Tellers:** Process customer transactions at branch locations
- **Customer Service Representatives:** Manage customer accounts and inquiries
- **Credit Officers:** Review loan applications and credit assessments
- **Operations Team:** Execute end-of-day processing and reconciliation
- **Compliance Officers:** Monitor audit trails and regulatory compliance
- **System Administrators:** Maintain system health and data integrity

## Key Performance Indicators

- **Transaction Processing:** Real-time processing with <2 second response time
- **System Availability:** 99.9% uptime during business hours
- **Data Integrity:** Zero transaction loss with ACID compliance
- **Audit Compliance:** 100% transaction traceability
- **Credit Score Accuracy:** Consistent multi-factor scoring algorithm

## Technology Context

### Current Implementation (Legacy)
- **Platform:** IBM i (AS/400)
- **Language:** ILE RPG/RPGLE (free-format)
- **Database:** DB2 for i with DDS file definitions
- **Transaction Control:** Commitment control with record locking
- **Batch Processing:** CL programs orchestrating batch jobs

### Target Implementation (Modernization)
- **Platform:** Java 21 with Spring Boot 3.x
- **Database:** PostgreSQL 16+ with JSONB support
- **Framework:** Spring Data JPA, Spring Security, Spring Batch
- **API:** RESTful APIs with OpenAPI documentation
- **Testing:** JUnit 5, Mockito, Testcontainers
- **Transaction Management:** Spring @Transactional with JPA

## System Constraints

1. **Data Integrity:** All financial transactions must be ACID-compliant
2. **Audit Requirements:** Complete audit trail for all data modifications
3. **Concurrency:** Support multiple concurrent users with data consistency
4. **Security:** Sensitive data (SSN, account numbers) must be protected
5. **Backward Compatibility:** During migration, support hybrid operations
6. **Regulatory Compliance:** Meet financial industry standards and regulations

## Migration Strategy

### Phase 1: Foundation
- Document legacy system architecture and business rules
- Set up Java 21 Spring Boot project structure
- Map RPG data structures to JPA entities
- Create PostgreSQL schema equivalent to DB2 tables

### Phase 2: Core Services
- Implement customer management services with tests
- Implement account management services with tests
- Implement credit scoring engine with tests
- Validate business rule parity with legacy system

### Phase 3: Transaction Processing
- Implement transaction processing with Spring transactions
- Ensure ACID compliance with PostgreSQL
- Performance testing for concurrent transactions
- Data consistency validation

### Phase 4: Batch & Integration
- Implement batch processing with Spring Batch
- Create REST APIs for external integration
- Set up monitoring and observability
- Migration utilities for data transfer from DB2 to PostgreSQL

### Phase 5: Cutover
- Parallel run validation (legacy vs. modern)
- User acceptance testing
- Production deployment with rollback plan
- Post-migration support and optimization
