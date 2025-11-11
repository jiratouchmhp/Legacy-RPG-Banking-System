---
title: [Short descriptive title of the feature]
version: 1.0
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
---

# Implementation Plan: [Feature Name]

## Overview

Brief description of what's being converted from RPG to Java Spring Boot. Include:
- Which RPG program(s) are being converted
- High-level purpose and business value
- Key business logic that must be preserved
- Expected outcomes

## Architecture and Design

### Entity Design

#### Entity: [EntityName]

**Purpose:** Brief description of what this entity represents

**RPG Mapping:**
- RPG Data Structure: `[DataStructureName]`
- RPG File: `[FileName].PF`

**Fields:**

| Java Field | Type | PostgreSQL Column | RPG Field | Notes |
|-----------|------|-------------------|-----------|-------|
| customerId | String | customer_id VARCHAR(10) PRIMARY KEY | CUSTID (10A) | Unique identifier |
| ssn | String | ssn VARCHAR(11) UNIQUE NOT NULL | SSN (9S 0) | Format: ###-##-#### |
| firstName | String | first_name VARCHAR(50) NOT NULL | FNAME (50A) | |
| creditScore | Integer | credit_score INTEGER | CREDITSCORE (9S 0) | Range: 300-850 |

**JPA Annotations:**
- Extends `AuditableEntity` for audit trail
- `@Table(name = "entity_name")`
- Appropriate constraints and indexes

**Relationships:**
- Relationship type (OneToMany, ManyToOne, etc.)
- Related entities
- Cascade and fetch strategies

### Service Layer Design

#### Service: [ServiceName]

**Purpose:** Brief description of service responsibilities

**RPG Mapping:**
- RPG Program: `[ProgramName].RPGLE`
- Procedures being converted: `[ProcedureName1]`, `[ProcedureName2]`

**Key Methods:**

##### Method: `createCustomer(CreateCustomerRequest request)`

**RPG Equivalent:** `CreateCustomer` procedure

**Purpose:** Create new customer with validation and credit score calculation

**Parameters:**
- `request`: CreateCustomerRequest DTO containing customer data

**Returns:** `Customer` entity

**Business Logic:**
1. Validate SSN is unique (matches RPG CHAIN check)
2. Generate customer ID (replaces RPG ID generation logic)
3. Set status to ACTIVE (matches RPG STATUS = 'A')
4. Save customer (matches RPG WRITE operation)
5. Calculate credit score (calls CreditScoreService)
6. Audit fields set automatically via JPA auditing

**Error Handling:**
- `DuplicateSSNException` if SSN exists (RPG error code E0002)
- `ValidationException` for invalid data (RPG error code E0003)

**Transaction Boundary:** `@Transactional` at method level

**RPG Business Rules Preserved:**
- SSN uniqueness check before insert
- Automatic audit field population
- Rollback on any error
- Credit score calculation triggered on creation

### Repository Layer Design

#### Repository: [RepositoryName]

**Extends:** `JpaRepository<Entity, IDType>`

**Custom Query Methods:**
```java
boolean existsBySsn(String ssn);
Optional<Customer> findBySsn(String ssn);
List<Customer> findByStatus(CustomerStatus status);
```

**Custom Queries (if needed):**
```java
@Query("SELECT c FROM Customer c LEFT JOIN FETCH c.accounts WHERE c.customerId = :id")
Optional<Customer> findByIdWithAccounts(@Param("id") String customerId);
```

### Controller Design (if applicable)

#### Controller: [ControllerName]

**Base Path:** `/api/v1/[resource]`

**Endpoints:**

| Method | Path | Request Body | Response | Description |
|--------|------|--------------|----------|-------------|
| POST | `/customers` | CreateCustomerRequest | CustomerResponse | Create customer |
| GET | `/customers/{id}` | - | CustomerResponse | Get customer by ID |
| PUT | `/customers/{id}` | UpdateCustomerRequest | CustomerResponse | Update customer |

**DTOs:**
- Request DTOs with validation annotations
- Response DTOs (never expose entities)
- Error response DTO for exceptions

### Database Schema

#### Table: [table_name]

```sql
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    ssn VARCHAR(11) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(15),
    credit_score INTEGER,
    risk_level CHAR(1) CHECK (risk_level IN ('L', 'M', 'H')),
    status CHAR(1) DEFAULT 'A' CHECK (status IN ('A', 'I')),
    created_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_time TIME NOT NULL DEFAULT CURRENT_TIME,
    created_user VARCHAR(20) NOT NULL,
    updated_date DATE,
    updated_time TIME,
    updated_user VARCHAR(20)
);

CREATE INDEX idx_customers_ssn ON customers(ssn);
CREATE INDEX idx_customers_status ON customers(status) WHERE status = 'A';
CREATE INDEX idx_customers_credit_score ON customers(credit_score);
```

**Constraints:**
- Primary key on `customer_id`
- Unique constraint on `ssn`
- Check constraints on `risk_level` and `status`
- NOT NULL constraints on required fields

**Indexes:**
- `idx_customers_ssn`: For SSN lookups
- `idx_customers_status`: For active customer queries
- `idx_customers_credit_score`: For credit score filtering

**Migration File:** `V1__create_customers_table.sql`

## Business Logic Preservation

### RPG Procedure → Java Method Mapping

#### RPG: `CreateCustomer` → Java: `CustomerService.createCustomer()`

**RPG Logic:**
```rpg
P CreateCustomer  B                   EXPORT
D CreateCustomer  PI            10A
D  pSSN                          9S 0 CONST
D  pFirstName                   50A   CONST
D  pLastName                    50A   CONST

 /FREE
  CHAIN pSSN CUSTMAST;
  IF %FOUND(CUSTMAST);
    RETURN *BLANKS;  // Duplicate
  ENDIF;
  
  wCustomerId = GenerateId();
  CUSTID = wCustomerId;
  SSN = pSSN;
  FNAME = pFirstName;
  LNAME = pLastName;
  STATUS = 'A';
  CRTDATE = wCurrentDate;
  CRTUSER = %USER;
  
  WRITE CUSTMASTR;
  IF %ERROR();
    ROLLBACK;
    RETURN *BLANKS;
  ELSE;
    COMMIT;
    RETURN wCustomerId;
  ENDIF;
 /END-FREE
P CreateCustomer  E
```

**Java Implementation:**
```java
@Transactional
public Customer createCustomer(CreateCustomerRequest request) {
    // Line 1-3: CHAIN + %FOUND check
    if (customerRepository.existsBySsn(request.getSsn())) {
        throw new DuplicateSSNException("Customer with SSN already exists");
    }
    
    // Line 5-11: Record population
    Customer customer = Customer.builder()
            .customerId(generateCustomerId())  // wCustomerId = GenerateId()
            .ssn(request.getSsn())              // SSN = pSSN
            .firstName(request.getFirstName())  // FNAME = pFirstName
            .lastName(request.getLastName())    // LNAME = pLastName
            .status(CustomerStatus.ACTIVE)      // STATUS = 'A'
            // CRTDATE, CRTUSER handled by JPA auditing
            .build();
    
    // Line 13-18: WRITE with error handling
    // Spring @Transactional handles COMMIT/ROLLBACK
    return customerRepository.save(customer);
}
```

**Business Rules Preserved:**
1. ✅ SSN uniqueness check before insert
2. ✅ Active status on creation
3. ✅ Audit trail (date, user) automatically set
4. ✅ Transaction rollback on error
5. ✅ Return value indicates success/failure

### Credit Scoring Algorithm

**RPG Logic:**
```rpg
wBaseScore = 600;
wPaymentScore = CalculatePaymentHistory(pCustomerId);  // 35% weight
wDebtScore = CalculateDebtRatio(pCustomerId);          // 30% weight
wAgeScore = CalculateCreditAge(pCustomerId);           // 15% weight
wIncomeScore = CalculateIncomeLevel(pCustomerId);      // 10% weight
wEmployScore = CalculateEmployment(pCustomerId);       // 10% weight

wTotalScore = wBaseScore + wPaymentScore + wDebtScore + wAgeScore + wIncomeScore + wEmployScore;

IF wTotalScore >= 720;
  wRiskLevel = 'L';
ELSEIF wTotalScore >= 640;
  wRiskLevel = 'M';
ELSE;
  wRiskLevel = 'H';
ENDIF;
```

**Java Implementation:**
```java
private static final int BASE_SCORE = 600;

public CreditScoreResult calculateCreditScore(Customer customer) {
    int paymentScore = calculatePaymentHistory(customer);  // 35% weight, 0-150 points
    int debtScore = calculateDebtRatio(customer);          // 30% weight, 0-100 points
    int ageScore = calculateCreditAge(customer);           // 15% weight, 20-100 points
    int incomeScore = calculateIncomeLevel(customer);      // 10% weight, 20-100 points
    int employScore = calculateEmployment(customer);       // 10% weight, 20-100 points
    
    int totalScore = BASE_SCORE + paymentScore + debtScore + ageScore + incomeScore + employScore;
    
    RiskLevel riskLevel;
    if (totalScore >= 720) {
        riskLevel = RiskLevel.LOW;
    } else if (totalScore >= 640) {
        riskLevel = RiskLevel.MEDIUM;
    } else {
        riskLevel = RiskLevel.HIGH;
    }
    
    return new CreditScoreResult(totalScore, riskLevel);
}
```

**Calculation Parity:**
- ✅ Base score: 600
- ✅ Payment history: 0-150 points (35% weight)
- ✅ Debt ratio: 0-100 points (30% weight)
- ✅ Credit age: 20-100 points (15% weight)
- ✅ Income: 20-100 points (10% weight)
- ✅ Employment: 20-100 points (10% weight)
- ✅ Risk thresholds: 720+ (Low), 640-719 (Medium), <640 (High)

## Data Migration Strategy

### Phase 1: Schema Creation
1. Create Flyway migration: `V1__create_customers_table.sql`
2. Apply to development PostgreSQL database
3. Verify constraints and indexes created correctly

### Phase 2: Data Type Mapping

| RPG Type | RPG Example | PostgreSQL Type | Java Type | Conversion Logic |
|----------|-------------|-----------------|-----------|------------------|
| 10A | CUSTID | VARCHAR(10) | String | Direct mapping |
| 9S 0 | SSN | VARCHAR(11) | String | Format: ###-##-#### |
| 15P 2 | BALANCE | DECIMAL(15,2) | BigDecimal | Preserve precision |
| 8S 0 | CRTDATE | DATE | LocalDate | Convert YYYYMMDD → ISO-8601 |
| 6S 0 | CRTTIME | TIME | LocalTime | Convert HHMMSS → ISO-8601 |
| 1A | STATUS | CHAR(1) | Enum | Map to enum values |

### Phase 3: ETL Process
1. Extract data from DB2 for i: `SELECT * FROM CUSTMAST`
2. Transform:
   - Convert dates: 20250115 → 2025-01-15
   - Convert times: 143058 → 14:30:58
   - Format SSN: 123456789 → 123-45-6789
   - Map status codes to enum values
3. Load into PostgreSQL: Bulk INSERT with proper constraints
4. Validate:
   - Row count matches
   - Data integrity checks (foreign keys, constraints)
   - Sample data verification

### Phase 4: Validation
- Compare record counts: DB2 vs PostgreSQL
- Verify data integrity: Primary keys, foreign keys, unique constraints
- Test queries: Ensure same results from both databases
- Performance testing: Query response times

## Testing Strategy

### Unit Tests

#### CustomerServiceTest

**Test Coverage:** 90%+ target

**Test Cases:**

1. **Happy Path:**
   - `shouldCreateCustomerSuccessfully()` - Valid customer creation
   - `shouldGetCustomerById()` - Retrieve existing customer
   - `shouldUpdateCustomerSuccessfully()` - Update customer data

2. **Error Cases:**
   - `shouldThrowDuplicateSSNException()` - SSN already exists
   - `shouldThrowCustomerNotFoundException()` - Customer not found
   - `shouldThrowValidationException()` - Invalid data format

3. **Edge Cases:**
   - `shouldHandleNullEmail()` - Optional fields as null
   - `shouldHandleMaxLengthFields()` - Boundary values
   - `shouldHandleSpecialCharacters()` - Names with apostrophes, hyphens

4. **Business Logic:**
   - `shouldCalculateCreditScoreCorrectly()` - Verify algorithm
   - `shouldSetActiveStatusOnCreation()` - Status default value
   - `shouldPopulateAuditFields()` - Created date, time, user

**Example Test:**
```java
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {
    
    @Mock
    private CustomerRepository customerRepository;
    
    @InjectMocks
    private CustomerService customerService;
    
    @Test
    @DisplayName("Should create customer successfully with valid data")
    void shouldCreateCustomerSuccessfully() {
        // Given
        CreateCustomerRequest request = CreateCustomerRequest.builder()
                .ssn("123-45-6789")
                .firstName("John")
                .lastName("Doe")
                .build();
        
        when(customerRepository.existsBySsn(anyString())).thenReturn(false);
        when(customerRepository.save(any(Customer.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        
        // When
        Customer result = customerService.createCustomer(request);
        
        // Then
        assertThat(result).isNotNull();
        assertThat(result.getFirstName()).isEqualTo("John");
        verify(customerRepository).save(any(Customer.class));
    }
}
```

### Integration Tests

#### CustomerServiceIntegrationTest

**Framework:** Spring Boot Test with Testcontainers

**Test Cases:**

1. **End-to-End Flow:**
   - `shouldCreateAndRetrieveCustomer()` - Full CRUD cycle
   - `shouldEnforceUniqueSSNConstraint()` - Database constraint
   - `shouldCascadeDeleteAccounts()` - Relationship cascade

2. **Transaction Tests:**
   - `shouldRollbackOnError()` - Verify transaction rollback
   - `shouldCommitOnSuccess()` - Verify transaction commit
   - `shouldHandleConcurrentUpdates()` - Pessimistic locking

3. **Performance Tests:**
   - `shouldHandleBulkInserts()` - Batch operations
   - `shouldQueryWithinPerformanceLimits()` - Query optimization

**Example Test:**
```java
@SpringBootTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class CustomerServiceIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");
    
    @Autowired
    private CustomerService customerService;
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Test
    void shouldCreateAndRetrieveCustomer() {
        // Given
        CreateCustomerRequest request = // ... setup
        
        // When
        Customer created = customerService.createCustomer(request);
        Customer retrieved = customerService.getCustomerById(created.getCustomerId());
        
        // Then
        assertThat(retrieved).isNotNull();
        assertThat(retrieved.getFirstName()).isEqualTo(created.getFirstName());
    }
}
```

### Test Data

**Valid Test Data:**
```java
CreateCustomerRequest validRequest = CreateCustomerRequest.builder()
        .ssn("123-45-6789")
        .firstName("John")
        .lastName("Doe")
        .email("john.doe@example.com")
        .phone("(555) 123-4567")
        .build();
```

**Invalid Test Data:**
```java
// Invalid SSN format
.ssn("12345678")

// Missing required field
.firstName(null)

// Exceeds max length
.firstName("a".repeat(51))

// Invalid email format
.email("invalid-email")
```

## Tasks

Breaking down implementation into manageable, testable chunks:

### Database Setup
- [ ] Create Flyway migration `V1__create_customers_table.sql` with PostgreSQL schema
- [ ] Create Flyway migration `V2__create_accounts_table.sql` with foreign key to customers
- [ ] Test migrations on development PostgreSQL database
- [ ] Verify indexes and constraints are created correctly

### Entity Layer
- [ ] Create `AuditableEntity` base class with JPA auditing configuration
- [ ] Create `Customer` entity with JPA annotations and relationships
- [ ] Create `Account` entity with JPA annotations
- [ ] Create enums: `CustomerStatus`, `RiskLevel`, `AccountType`
- [ ] Configure JPA auditing in application configuration

### Repository Layer
- [ ] Create `CustomerRepository` interface extending JpaRepository
- [ ] Add custom query methods: `existsBySsn`, `findBySsn`
- [ ] Create `AccountRepository` interface
- [ ] Write repository integration tests with Testcontainers

### Service Layer - Part 1: Customer Management
- [ ] Create `CreateCustomerRequest` DTO with validation annotations
- [ ] Write unit test: `shouldCreateCustomerSuccessfully()`
- [ ] Implement `CustomerService.createCustomer()` method
- [ ] Write unit test: `shouldThrowDuplicateSSNException()`
- [ ] Implement SSN uniqueness validation
- [ ] Write unit test: `shouldGetCustomerById()`
- [ ] Implement `CustomerService.getCustomerById()` method
- [ ] Verify 90%+ test coverage for CustomerService

### Service Layer - Part 2: Credit Scoring
- [ ] Write unit test: `shouldCalculateCreditScoreCorrectly()`
- [ ] Implement `CreditScoreService.calculateCreditScore()` method
- [ ] Write unit tests for each scoring factor (payment, debt, age, income, employment)
- [ ] Implement risk level determination logic
- [ ] Verify scoring algorithm matches RPG implementation exactly

### Exception Handling
- [ ] Create custom exceptions: `DuplicateSSNException`, `CustomerNotFoundException`
- [ ] Create `ErrorResponse` DTO
- [ ] Implement `GlobalExceptionHandler` with @RestControllerAdvice
- [ ] Map exception types to HTTP status codes and error codes
- [ ] Write tests for exception handling

### Controller Layer (if REST API needed)
- [ ] Create `CustomerResponse` DTO
- [ ] Create `CustomerController` with REST endpoints
- [ ] Write integration tests with MockMvc or TestRestTemplate
- [ ] Add OpenAPI annotations for API documentation
- [ ] Test validation error responses

### Integration Tests
- [ ] Set up Testcontainers PostgreSQL configuration
- [ ] Write end-to-end test: `shouldCreateAndRetrieveCustomer()`
- [ ] Write transaction test: `shouldRollbackOnError()`
- [ ] Write concurrency test: `shouldHandleConcurrentUpdates()`
- [ ] Verify integration test coverage for all critical paths

### Documentation & Configuration
- [ ] Add Javadoc to all public service methods
- [ ] Configure application.yml for development environment
- [ ] Configure application-test.yml for test environment
- [ ] Document data migration process
- [ ] Update ARCHITECTURE.md if design decisions made

## Open Questions

1. **Credit Score Calculation:** What data sources should be used for payment history, debt ratio, and other scoring factors? (RPG uses existing account data - confirm this is sufficient)

2. **API Authentication:** What authentication mechanism should be used for REST APIs? (JWT, OAuth2, Basic Auth, or defer to API Gateway?)

3. **Caching Strategy:** Should customer and credit score data be cached? If so, what cache provider (Redis, Caffeine) and TTL settings?

4. **Performance Requirements:** What are the expected transaction volumes and response time requirements? (Need SLA targets for optimization decisions)

5. **Data Migration Timing:** Should data migration happen before code deployment (big bang) or support dual-write period for gradual cutover?

## Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Business logic mismatch | High | Medium | Comprehensive unit tests comparing RPG and Java results side-by-side |
| Data migration errors | High | Medium | Thorough validation with checksums and sample verification |
| Performance degradation | Medium | Low | Load testing with Testcontainers, optimize queries with indexes |
| Incomplete error handling | Medium | Low | Test all error paths, match RPG error codes |
| Date/time conversion bugs | Medium | Medium | Extensive test cases for date formats, time zones |

## Success Criteria

Implementation is complete when:
- ✅ All unit tests pass with 90%+ service layer coverage
- ✅ All integration tests pass with Testcontainers
- ✅ Business logic produces identical results to RPG implementation
- ✅ Database schema matches requirements with proper constraints
- ✅ Error handling covers all RPG error codes
- ✅ Audit trail is complete and accurate
- ✅ Transaction boundaries are correct (@Transactional applied appropriately)
- ✅ Code review checklist passes
- ✅ Documentation is complete (Javadoc, README updates)
- ✅ No sensitive data in logs (SSN masked, account numbers protected)
