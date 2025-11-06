# Legacy Banking System - Copilot Instructions

## Project Overview

This is a legacy banking system originally built on IBM i (AS/400) using RPG/RPGLE, being modernized to Java 21 with Spring Boot 3.x and PostgreSQL.

## Core Documentation

Always reference these documents for project context:

* [Product Vision and Goals](../PRODUCT.md): Business requirements, features, and migration strategy
* [System Architecture and Design Principles](../ARCHITECTURE.md): System design, data models, and technology stack
* [Contributing Guidelines](../CONTRIBUTING.md): Development workflow, testing standards, and code review checklist
* [RPG Conventions](../RPG-CONVENTIONS.md): Legacy RPG/RPGLE coding patterns and idioms

**Important:** Suggest updating these documents if you find incomplete or conflicting information during your work.

## System Context

### Application Domain
Financial services banking platform managing:
- Customer accounts with credit scoring
- Real-time transaction processing (deposits, withdrawals, transfers)
- ACID-compliant operations with commitment control
- End-of-day batch processing
- Comprehensive audit trails for regulatory compliance

### Current State (Legacy)
- **Platform:** IBM i (AS/400)
- **Language:** ILE RPG/RPGLE free-format
- **Database:** DB2 for i with DDS file definitions
- **Files:** `CUSTMAST.PF`, `ACCTMAST.PF`, `TRANLOG.PF`
- **Programs:** `CUSTPROC.RPGLE`, `POSTTRAN.RPGLE`, `CREDSCOR.RPGLE`, `EODPROC.CLLE`

### Target State (Modern)
- **Language:** Java 21 (LTS) with Virtual Threads
- **Framework:** Spring Boot 3.x (latest stable)
- **Database:** PostgreSQL 16+ with JSONB support
- **Architecture:** Layered (Controller → Service → Repository → Entity)
- **Testing:** JUnit 5, Mockito, Testcontainers
- **API:** RESTful with OpenAPI documentation
- **Batch:** Spring Batch 5.x

## Primary Use Cases

### Use Case 1: Legacy RPG Maintenance
When maintaining or extending the existing RPG codebase:
- Follow conventions in `RPG-CONVENTIONS.md`
- Use free-format RPG syntax (`/FREE` ... `/END-FREE`)
- Enable commitment control for all database operations
- Update audit fields (created/updated date, time, user)
- Include comprehensive error handling with rollback
- Test in development environment before production

### Use Case 2: Java Spring Boot Conversion
When converting RPG programs to Java Spring Boot:
- Map RPG data structures to JPA entities with proper relationships
- Convert RPG procedures to Spring service methods
- Implement comprehensive unit tests (JUnit 5) and integration tests (Testcontainers)
- Follow TDD approach: write test first, implement, refactor
- Maintain business logic parity with legacy system
- Use Spring Data JPA for data access
- Apply Spring `@Transactional` for transaction management
- Convert DB2 tables to PostgreSQL with appropriate data types

## Code Generation Rules

### General Rules
1. **No placeholders:** Always generate complete, production-ready code
2. **Comprehensive tests:** Every service method must have unit tests
3. **Error handling:** Include proper exception handling and validation
4. **Logging:** Add appropriate log statements (SLF4J)
5. **Documentation:** Include Javadoc for public methods in Java, procedure headers in RPG
6. **Security:** Never log sensitive data (mask SSN, account numbers)

### Java Specific Rules
1. **Java Version:** Target Java 21 with modern features (records, switch expressions, virtual threads)
2. **Spring Boot Version:** Use Spring Boot 3.2.x or later
3. **Project Structure:**
   ```
   com.bank
   ├── customer
   │   ├── entity
   │   ├── repository
   │   ├── service
   │   ├── controller
   │   └── dto
   ├── account
   │   ├── entity
   │   ├── repository
   │   ├── service
   │   ├── controller
   │   └── dto
   └── transaction
       ├── entity
       ├── repository
       ├── service
       ├── controller
       └── dto
   ```
4. **Naming Conventions:**
   - Classes: PascalCase (e.g., `CustomerService`)
   - Methods: camelCase (e.g., `calculateCreditScore`)
   - Constants: UPPER_SNAKE_CASE (e.g., `BASE_CREDIT_SCORE`)
   - Packages: lowercase (e.g., `com.bank.customer.service`)
5. **Lombok Usage:** Use `@Data`, `@Builder`, `@RequiredArgsConstructor`, `@Slf4j`
6. **Transaction Management:** Use `@Transactional` on service methods that modify data
7. **Validation:** Use Bean Validation annotations (`@NotNull`, `@Positive`, `@Email`)
8. **DTOs:** Always use DTOs for API requests/responses, never expose entities directly

### PostgreSQL Specific Rules
1. **Schema Migrations:** Use Flyway or Liquibase with versioned migrations
2. **Naming Convention:** 
   - Tables: lowercase plural (e.g., `customers`, `accounts`, `transactions`)
   - Columns: snake_case (e.g., `customer_id`, `credit_score`, `created_date`)
   - Indexes: `idx_{table}_{column}` (e.g., `idx_customers_ssn`)
   - Foreign Keys: `fk_{table}_{ref_table}` (e.g., `fk_accounts_customers`)
3. **Data Type Mapping:**
   - RPG `10A` → PostgreSQL `VARCHAR(10)`
   - RPG `9S 0` → PostgreSQL `VARCHAR(11)` (for SSN with formatting)
   - RPG `15P 2` → PostgreSQL `DECIMAL(15,2)` or `NUMERIC(15,2)`
   - RPG `8S 0` date → PostgreSQL `DATE`
   - RPG `6S 0` time → PostgreSQL `TIME`
   - Single-char flags → PostgreSQL `CHAR(1)` with CHECK constraint
4. **Constraints:** Define NOT NULL, UNIQUE, CHECK, and foreign key constraints
5. **Indexes:** Create indexes on primary keys, foreign keys, and frequently queried columns
6. **Partitioning:** Consider table partitioning for large transaction tables (by date)

### RPG Specific Rules
1. **Free-Format Only:** Use `/FREE` ... `/END-FREE` blocks exclusively
2. **Qualified DS:** Always use `QUALIFIED` keyword on data structures
3. **Commitment Control:** Enable `COMMIT` keyword on file specs for all transactional files
4. **Error Checking:** Check `%ERROR()` after every database operation
5. **Record Locking:** Use `CHAIN` before `UPDATE` to acquire lock
6. **Audit Trail:** Always populate created/updated date, time, user fields
7. **Built-in Functions:** Use BIFs (`%TRIM`, `%FOUND`, `%ERROR`, `%USER`, etc.)
8. **Procedures:** Export reusable procedures with clear interfaces

## Data Mapping Reference

### Customer Data
| Legacy (CUSTMAST) | Java Entity | PostgreSQL |
|-------------------|-------------|------------|
| CUSTID (10A) | customerId (String) | customer_id VARCHAR(10) PRIMARY KEY |
| SSN (9S 0) | ssn (String) | ssn VARCHAR(11) UNIQUE NOT NULL |
| FNAME (50A) | firstName (String) | first_name VARCHAR(50) NOT NULL |
| LNAME (50A) | lastName (String) | last_name VARCHAR(50) NOT NULL |
| EMAIL (100A) | email (String) | email VARCHAR(100) |
| PHONE (15A) | phone (String) | phone VARCHAR(15) |
| CREDITSCORE (9S 0) | creditScore (Integer) | credit_score INTEGER |
| RISKLVL (1A) | riskLevel (RiskLevel enum) | risk_level CHAR(1) CHECK IN ('L','M','H') |
| STATUS (1A) | status (CustomerStatus enum) | status CHAR(1) CHECK IN ('A','I') |
| CRTDATE (8S 0) | createdDate (LocalDate) | created_date DATE NOT NULL |
| CRTTIME (6S 0) | createdTime (LocalTime) | created_time TIME NOT NULL |
| CRTUSER (20A) | createdUser (String) | created_user VARCHAR(20) NOT NULL |

### Account Data
| Legacy (ACCTMAST) | Java Entity | PostgreSQL |
|-------------------|-------------|------------|
| ACCTID (12A) | accountId (String) | account_id VARCHAR(12) PRIMARY KEY |
| CUSTID (10A) | customer (Customer) | customer_id VARCHAR(10) FK REFERENCES customers |
| ACCTTYPE (2A) | accountType (AccountType enum) | account_type VARCHAR(2) CHECK IN ('CK','SV','LN') |
| BALANCE (15P 2) | balance (BigDecimal) | balance DECIMAL(15,2) NOT NULL |
| AVAILBAL (15P 2) | availableBalance (BigDecimal) | available_balance DECIMAL(15,2) |
| OVERDRAFT (1A) | overdraftProtection (Boolean) | overdraft_protection BOOLEAN DEFAULT FALSE |
| OVRDLIMIT (15P 2) | overdraftLimit (BigDecimal) | overdraft_limit DECIMAL(15,2) DEFAULT 0 |
| INTRATE (5P 4) | interestRate (BigDecimal) | interest_rate DECIMAL(5,4) |
| STATUS (1A) | status (AccountStatus enum) | status CHAR(1) CHECK IN ('A','C','F') |

### Transaction Data
| Legacy (TRANLOG) | Java Entity | PostgreSQL |
|-------------------|-------------|------------|
| TRANID (15A) | transactionId (String) | transaction_id VARCHAR(15) PRIMARY KEY |
| ACCTID (12A) | account (Account) | account_id VARCHAR(12) FK REFERENCES accounts |
| TRANTYPE (2A) | transactionType (TransactionType enum) | transaction_type VARCHAR(2) CHECK IN ('DP','WD','TF') |
| AMOUNT (15P 2) | amount (BigDecimal) | amount DECIMAL(15,2) NOT NULL |
| BALAFTER (15P 2) | balanceAfter (BigDecimal) | balance_after DECIMAL(15,2) |
| TRANDATE (8S 0) | transactionDate (LocalDate) | transaction_date DATE NOT NULL |
| TRANTIME (6S 0) | transactionTime (LocalTime) | transaction_time TIME NOT NULL |
| STATUS (1A) | status (TransactionStatus enum) | status CHAR(1) CHECK IN ('P','C','R') |

## Testing Requirements

### Unit Tests (Java)
- **Coverage:** Minimum 80% overall, 90% for service layer
- **Framework:** JUnit 5 with AssertJ assertions
- **Mocking:** Mockito for dependencies
- **Naming:** `should[ExpectedBehavior]When[StateUnderTest]` or `[method]_[scenario]_[expectedResult]`
- **Structure:** Given-When-Then pattern
- **Required for:** All service methods, validation logic, business rules

### Integration Tests (Java)
- **Framework:** Spring Boot Test with Testcontainers
- **Database:** Real PostgreSQL container (not H2)
- **Coverage:** Repository methods, transaction boundaries, end-to-end API flows
- **Cleanup:** Use `@Transactional` with rollback or manual cleanup

### Example Test Structure:
```java
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {
    
    @Mock
    private CustomerRepository customerRepository;
    
    @InjectMocks
    private CustomerService customerService;
    
    @Test
    @DisplayName("Should create customer successfully with unique SSN")
    void shouldCreateCustomerSuccessfully() {
        // Given
        CreateCustomerRequest request = // ... setup
        when(customerRepository.existsBySsn(anyString())).thenReturn(false);
        
        // When
        Customer result = customerService.createCustomer(request);
        
        // Then
        assertThat(result).isNotNull();
        verify(customerRepository).save(any(Customer.class));
    }
}
```

## Business Rules to Preserve

### Credit Scoring Algorithm
```
Base Score: 600
+ Payment History (0-150 points, 35% weight)
+ Debt Ratio (0-100 points, 30% weight)  
+ Credit Age (20-100 points, 15% weight)
+ Income Level (20-100 points, 10% weight)
+ Employment (20-100 points, 10% weight)
= Total Score (300-850)

Risk Levels:
- Low (L): 720+
- Medium (M): 640-719
- High (H): <640

Loan Recommendations:
- Approve: 680+
- Review: 620-679
- Deny: <620

Interest Rate Tiers:
- 760+: 3.5%
- 720-759: 4.0%
- 680-719: 5.0%
- 640-679: 6.5%
- <640: 8.5%
```

### Transaction Processing Rules
1. **Withdrawals:** Cannot exceed available balance + overdraft limit
2. **Transfers:** Both source and target accounts must be Active
3. **All transactions:** Must be logged before completion
4. **Failed transactions:** Complete rollback required
5. **Concurrent access:** Use pessimistic locking
6. **Transaction IDs:** Must be unique and traceable

### Audit Trail Requirements
- All data modifications tracked with user, date, and time
- Immutable after initial creation
- Complete history for regulatory compliance

## Performance Considerations

### Java Performance
- Use `@Transactional(readOnly = true)` for read operations
- Implement pagination with `Pageable` for large result sets
- Use `@EntityGraph` or JOIN FETCH to avoid N+1 queries
- Enable second-level cache for read-heavy entities
- Use batch operations for bulk inserts/updates
- Monitor slow queries with `spring.jpa.show-sql=true` in development

### PostgreSQL Performance
- Create appropriate indexes (primary keys, foreign keys, query columns)
- Use connection pooling (HikariCP with optimal settings)
- Consider table partitioning for transactions (by date)
- Use EXPLAIN ANALYZE to optimize slow queries
- Enable query logging for performance analysis

## Security Requirements

1. **Authentication:** Spring Security with role-based access control
2. **Authorization:** Method-level security with `@PreAuthorize`
3. **Data Protection:** 
   - Mask sensitive data in logs (SSN: show only last 4 digits)
   - Never log account numbers, passwords, or full SSN
   - Use parameterized queries (JPA handles automatically)
4. **Encryption:**
   - TLS/SSL for all connections
   - BCrypt for password hashing
   - Database encryption at rest (PostgreSQL TDE)
5. **Validation:** 
   - Input validation at controller layer
   - Business rule validation at service layer
   - Database constraints as final safeguard

## Migration Strategy

### Phase 1: Foundation
1. Set up Java 21 + Spring Boot 3.x project
2. Create PostgreSQL schema matching DB2 structure
3. Implement base entities with JPA annotations
4. Set up Flyway/Liquibase migrations

### Phase 2: Core Services
1. Convert CUSTPROC.RPGLE → CustomerService + tests
2. Convert CREDSCOR.RPGLE → CreditScoreService + tests
3. Validate business rule parity with legacy

### Phase 3: Transactions
1. Convert POSTTRAN.RPGLE → TransactionService + tests
2. Ensure ACID compliance with Spring transactions
3. Performance testing for concurrent operations

### Phase 4: Batch & APIs
1. Convert EODPROC.CLLE → Spring Batch jobs
2. Create REST APIs for all operations
3. OpenAPI documentation

### Phase 5: Cutover
1. Data migration from DB2 to PostgreSQL
2. Parallel run validation
3. Gradual traffic migration
4. Decommission legacy system

## Common Pitfalls to Avoid

### Java Development
- ❌ Exposing entities directly in REST APIs (use DTOs)
- ❌ Ignoring N+1 query problems
- ❌ Not using `@Transactional` for operations that modify data
- ❌ Hardcoding values (use application.yml or constants)
- ❌ Logging sensitive data without masking
- ❌ Using H2 for integration tests (use Testcontainers with PostgreSQL)

### RPG Development
- ❌ Forgetting to enable commitment control
- ❌ Not checking `%ERROR()` after database operations
- ❌ Updating records without acquiring lock first (CHAIN before UPDATE)
- ❌ Not updating audit trail fields
- ❌ Using old fixed-format syntax

### Data Migration
- ❌ Assuming direct data type mapping (validate conversions)
- ❌ Ignoring date/time format differences
- ❌ Not validating data integrity after migration
- ❌ Missing indexes or constraints in PostgreSQL

## When to Ask for Clarification

1. Business rule ambiguity or conflicts with documentation
2. Security-sensitive operations requiring policy decisions
3. Major architectural decisions (caching strategy, API design)
4. Database schema changes affecting multiple tables
5. Performance requirements for specific operations
6. Rollback strategy for failed migrations

## Workflow Best Practices

1. **Read relevant documentation first:** Check PRODUCT.md, ARCHITECTURE.md, or RPG-CONVENTIONS.md
2. **Create a plan for complex work:** Outline steps before implementation
3. **Write tests first:** Follow TDD for Java development
4. **Validate business logic:** Ensure parity with legacy system
5. **Run tests frequently:** After each implementation step
6. **Check for errors:** Review compilation/test errors immediately
7. **Update documentation:** If you find gaps or conflicts

---

**Remember:** This is a financial services application where data integrity, security, and audit compliance are paramount. When in doubt, favor safety and correctness over speed or convenience.
