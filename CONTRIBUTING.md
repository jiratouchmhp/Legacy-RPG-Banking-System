# Contributing Guidelines - Legacy Banking System

## Development Workflow

### For Legacy RPG Maintenance

1. **Understand the Context**
   - Review `PRODUCT.md` for business requirements
   - Review `ARCHITECTURE.md` for system design
   - Review `RPG-CONVENTIONS.md` for RPG-specific patterns
   - Read related program documentation in comments

2. **Make Changes**
   - Follow RPG naming conventions (see RPG-CONVENTIONS.md)
   - Use free-format RPG syntax (`/FREE` ... `/END-FREE`)
   - Include comprehensive inline comments
   - Update procedure documentation headers
   - Maintain commitment control for all database operations

3. **Test Changes**
   - Compile program: `CRTBNDRPG PGM(BANKLIB/PROGNAME) SRCFILE(QRPGLESRC)`
   - Test in development environment first
   - Verify audit trail updates correctly
   - Test error handling with invalid data
   - Verify transaction rollback scenarios

4. **Document Changes**
   - Update program header with change description
   - Update inline comments for modified logic
   - Document any new business rules
   - Update this guide if new patterns introduced

### For Java Spring Boot Development

1. **Setup Development Environment**
   - Install Java 21 (OpenJDK or Oracle JDK)
   - Install Maven 3.9+ or Gradle 8.5+
   - Install Docker for Testcontainers
   - Use IntelliJ IDEA or VS Code with Java extensions

2. **Follow TDD Approach**
   - Write test first (unit or integration)
   - Implement minimal code to pass test
   - Refactor while keeping tests green
   - Maintain test coverage >80%

3. **Code Organization**
   - Follow package structure: `com.bank.[domain].[layer]`
   - Place entities in `entity` package
   - Place repositories in `repository` package
   - Place services in `service` package
   - Place controllers in `controller` package
   - Place DTOs in `dto` package

4. **Commit Changes**
   - Write descriptive commit messages
   - Reference issue numbers when applicable
   - Keep commits focused and atomic
   - Sign commits if required by team policy

## Code Style & Standards

### Java Code Style

#### Naming Conventions
- **Classes:** PascalCase (e.g., `CustomerService`, `TransactionRepository`)
- **Methods:** camelCase (e.g., `calculateCreditScore`, `processTransaction`)
- **Constants:** UPPER_SNAKE_CASE (e.g., `BASE_CREDIT_SCORE`, `MAX_OVERDRAFT_LIMIT`)
- **Variables:** camelCase (e.g., `customerId`, `accountBalance`)
- **Packages:** lowercase (e.g., `com.bank.customer.service`)

#### Formatting
- **Indentation:** 4 spaces (no tabs)
- **Line Length:** 120 characters max
- **Braces:** Opening brace on same line (K&R style)
- **Imports:** Group by java.*, javax.*, external libs, project
- **Use:** Lombok annotations to reduce boilerplate

#### Example:
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerService {
    
    private static final int BASE_CREDIT_SCORE = 600;
    
    private final CustomerRepository customerRepository;
    private final CreditScoreService creditScoreService;
    
    @Transactional
    public Customer createCustomer(CreateCustomerRequest request) {
        log.info("Creating customer with SSN: {}", maskSSN(request.getSsn()));
        
        validateUniqueSSN(request.getSsn());
        
        Customer customer = Customer.builder()
                .customerId(generateCustomerId())
                .ssn(request.getSsn())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .status(CustomerStatus.ACTIVE)
                .build();
        
        Customer savedCustomer = customerRepository.save(customer);
        creditScoreService.calculateAndSaveScore(savedCustomer);
        
        return savedCustomer;
    }
    
    private void validateUniqueSSN(String ssn) {
        if (customerRepository.existsBySsn(ssn)) {
            throw new DuplicateSSNException("Customer with SSN already exists");
        }
    }
}
```

### RPG Code Style

See `RPG-CONVENTIONS.md` for detailed RPG conventions.

## Testing Standards

### Unit Tests (Java)

**Required for:**
- All service methods
- Complex business logic
- Validation methods
- Utility functions

**Pattern:**
```java
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {
    
    @Mock
    private CustomerRepository customerRepository;
    
    @Mock
    private CreditScoreService creditScoreService;
    
    @InjectMocks
    private CustomerService customerService;
    
    @Test
    @DisplayName("Should create customer successfully with valid data")
    void shouldCreateCustomerSuccessfully() {
        // Given
        CreateCustomerRequest request = CreateCustomerRequest.builder()
                .ssn("123456789")
                .firstName("John")
                .lastName("Doe")
                .build();
        
        when(customerRepository.existsBySsn(anyString())).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(i -> i.getArgument(0));
        
        // When
        Customer result = customerService.createCustomer(request);
        
        // Then
        assertThat(result).isNotNull();
        assertThat(result.getFirstName()).isEqualTo("John");
        verify(customerRepository).save(any(Customer.class));
        verify(creditScoreService).calculateAndSaveScore(any(Customer.class));
    }
    
    @Test
    @DisplayName("Should throw DuplicateSSNException when SSN already exists")
    void shouldThrowExceptionForDuplicateSSN() {
        // Given
        CreateCustomerRequest request = CreateCustomerRequest.builder()
                .ssn("123456789")
                .build();
        
        when(customerRepository.existsBySsn(anyString())).thenReturn(true);
        
        // When/Then
        assertThatThrownBy(() -> customerService.createCustomer(request))
                .isInstanceOf(DuplicateSSNException.class)
                .hasMessageContaining("Customer with SSN already exists");
    }
}
```

### Integration Tests (Java)

**Required for:**
- Repository methods
- Transaction boundaries
- End-to-end API flows
- Database constraints

**Pattern with Testcontainers:**
```java
@SpringBootTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class TransactionServiceIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("banktest")
            .withUsername("test")
            .withPassword("test");
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
    
    @Autowired
    private TransactionService transactionService;
    
    @Autowired
    private AccountRepository accountRepository;
    
    @Test
    @DisplayName("Should process withdrawal and update balance atomically")
    void shouldProcessWithdrawalAtomically() {
        // Given
        Account account = createTestAccount("ACC123", new BigDecimal("1000.00"));
        accountRepository.save(account);
        
        // When
        TransactionResult result = transactionService.processWithdrawal(
                "ACC123", new BigDecimal("100.00"));
        
        // Then
        assertThat(result.isSuccess()).isTrue();
        Account updatedAccount = accountRepository.findById("ACC123").orElseThrow();
        assertThat(updatedAccount.getBalance()).isEqualByComparingTo("900.00");
    }
}
```

### Test Coverage Requirements
- **Overall Coverage:** Minimum 80%
- **Service Layer:** Minimum 90%
- **Controller Layer:** Minimum 75%
- **Repository Layer:** Covered by integration tests
- **Critical Business Logic:** 100%

## Database Migrations

### Flyway/Liquibase Usage

**File Naming:** `V{version}__{description}.sql`
- Example: `V1__create_customers_table.sql`
- Example: `V2__add_credit_score_index.sql`

**Best Practices:**
- Never modify existing migrations
- Always create new migration for schema changes
- Include both UP and DOWN migrations if using Liquibase
- Test migrations on development data first
- Include rollback plan for production migrations

**Example Migration:**
```sql
-- V1__create_customers_table.sql
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    ssn VARCHAR(11) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(15),
    credit_score INTEGER,
    risk_level VARCHAR(1) CHECK (risk_level IN ('L', 'M', 'H')),
    status VARCHAR(1) DEFAULT 'A' CHECK (status IN ('A', 'I')),
    created_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_time TIME NOT NULL DEFAULT CURRENT_TIME,
    created_user VARCHAR(20) NOT NULL,
    updated_date DATE,
    updated_time TIME,
    updated_user VARCHAR(20)
);

CREATE INDEX idx_customers_ssn ON customers(ssn);
CREATE INDEX idx_customers_status ON customers(status) WHERE status = 'A';
```

## Code Review Checklist

### Java Code Review
- [ ] Code follows naming conventions
- [ ] Tests are included and pass
- [ ] Test coverage meets requirements (>80%)
- [ ] No hardcoded values (use properties/constants)
- [ ] Proper exception handling
- [ ] Transaction boundaries are correct
- [ ] Logging is appropriate (info, debug, error)
- [ ] No sensitive data in logs (mask SSN, account numbers)
- [ ] DTOs used for API requests/responses (not entities)
- [ ] Database queries are optimized (no N+1 queries)
- [ ] Javadoc for public methods
- [ ] No TODO comments left in production code

### RPG Code Review
- [ ] Free-format syntax used
- [ ] Commitment control enabled on files
- [ ] Error checking after all database operations
- [ ] Audit fields updated (user, date, time)
- [ ] Procedure documentation headers complete
- [ ] No SQL injection vulnerabilities in dynamic SQL
- [ ] Record locking before updates
- [ ] Transaction rolled back on errors
- [ ] Constants defined for magic values
- [ ] Comments explain business logic

## Documentation Requirements

### Code Documentation

**Java:**
- Public API methods must have Javadoc
- Complex algorithms need inline comments
- Each class should have a class-level Javadoc

```java
/**
 * Service for managing customer lifecycle operations.
 * Handles customer creation, updates, credit score calculation,
 * and maintains complete audit trail for all operations.
 *
 * @author Banking Team
 * @since 1.0.0
 */
@Service
public class CustomerService {
    
    /**
     * Creates a new customer with initial credit score calculation.
     * 
     * @param request the customer creation request containing demographic data
     * @return the created customer entity with generated ID and credit score
     * @throws DuplicateSSNException if a customer with the SSN already exists
     * @throws ValidationException if request data fails validation
     */
    @Transactional
    public Customer createCustomer(CreateCustomerRequest request) {
        // Implementation
    }
}
```

**RPG:**
- Procedure headers with description, parameters, return value
- Inline comments for complex business logic

```rpg
//*============================================================
//* Procedure: CalculateCreditScore
//* Description: Multi-factor credit score calculation
//* Parameters:
//*   pCustomerId - Customer ID (input)
//* Returns: Credit score (300-850) or -1 on error
//* Author: Banking Team
//* Created: 2025-01-01
//*============================================================
```

## Branching Strategy

### Git Workflow

**Main Branches:**
- `main` - Production-ready code
- `develop` - Integration branch for features

**Feature Branches:**
- `feature/customer-management` - New features
- `bugfix/transaction-rollback` - Bug fixes
- `refactor/service-layer` - Code improvements
- `docs/api-documentation` - Documentation updates

**Migration Branches:**
- `migration/java-customer-service` - RPG to Java conversions

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** feat, fix, refactor, test, docs, chore
**Example:**
```
feat(customer): add credit score calculation service

Implement multi-factor credit scoring algorithm:
- Payment history (35% weight)
- Debt ratio (30% weight)
- Credit age (15% weight)
- Income (10% weight)
- Employment (10% weight)

Closes #42
```

## Common Patterns

### Error Response Structure (Java)

```java
@Data
@Builder
public class ErrorResponse {
    private String errorCode;
    private String errorMessage;
    private LocalDateTime timestamp;
    private String path;
    private Map<String, String> fieldErrors;
}
```

### Audit Entity Pattern (Java)

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Data
public abstract class AuditableEntity {
    
    @CreatedDate
    @Column(name = "created_date", nullable = false, updatable = false)
    private LocalDate createdDate;
    
    @CreatedDate
    @Column(name = "created_time", nullable = false, updatable = false)
    private LocalTime createdTime;
    
    @Column(name = "created_user", nullable = false, updatable = false, length = 20)
    private String createdUser;
    
    @LastModifiedDate
    @Column(name = "updated_date")
    private LocalDate updatedDate;
    
    @LastModifiedDate
    @Column(name = "updated_time")
    private LocalTime updatedTime;
    
    @Column(name = "updated_user", length = 20)
    private String updatedUser;
}
```

## Performance Guidelines

### Java Performance
- Use pagination for large result sets (Spring Data Pageable)
- Implement caching for frequently accessed data (Spring Cache)
- Use `@Transactional(readOnly = true)` for read operations
- Avoid N+1 queries (use JOIN FETCH or @EntityGraph)
- Use batch operations for bulk inserts/updates
- Monitor SQL queries in development (spring.jpa.show-sql=true)

### RPG Performance
- Use `SETLL` + `READE` for sequential access (faster than multiple `CHAIN`)
- Create appropriate indexes on frequently queried fields
- Use SQL for complex queries/aggregations
- Minimize record locking scope and duration

## Security Guidelines

### Java Security
- Never log sensitive data (SSN, account numbers) - use masking
- Use parameterized queries (JPA/JPQL automatically handles this)
- Validate all input data (Bean Validation annotations)
- Use HTTPS for all external communication
- Implement rate limiting for public APIs
- Use Spring Security for authentication/authorization
- Store passwords hashed with BCrypt (never plain text)

### RPG Security
- No hardcoded passwords or connection strings
- Validate all input parameters
- Use parameterized SQL (avoid concatenation)
- Log security events (failed authentication, authorization failures)

## Getting Help

### Resources
- **Architecture Questions:** Review `ARCHITECTURE.md`
- **Business Rules:** Review `PRODUCT.md`
- **RPG Syntax:** Review `RPG-CONVENTIONS.md`
- **Spring Boot Docs:** https://docs.spring.io/spring-boot/
- **PostgreSQL Docs:** https://www.postgresql.org/docs/

### When to Ask for Review
- Complex business logic changes
- Database schema modifications
- Transaction boundary changes
- Security-sensitive code
- Performance-critical paths
- Before merging to develop or main
