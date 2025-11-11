---
description: Quick reference for mapping RPG constructs to Java Spring Boot equivalents
---

# RPG to Java Mapping Reference

This is a quick reference guide for converting common RPG/RPGLE patterns to Java Spring Boot with PostgreSQL.

## Data Types

| RPG Type | Example | PostgreSQL Type | Java Type | Notes |
|----------|---------|-----------------|-----------|-------|
| nA (Character) | 10A | VARCHAR(n) | String | Fixed-length character |
| VARCHAR(n) | VARCHAR(100) | VARCHAR(n) | String | Variable-length character |
| nS 0 (Integer) | 9S 0 | INTEGER | Integer | Whole numbers |
| nS 0 (SSN) | 9S 0 | VARCHAR(11) | String | Store formatted: ###-##-#### |
| nP d (Packed) | 15P 2 | DECIMAL(n,d) | BigDecimal | Currency, precise decimals |
| 8S 0 (Date) | 8S 0 | DATE | LocalDate | YYYYMMDD → ISO-8601 |
| 6S 0 (Time) | 6S 0 | TIME | LocalTime | HHMMSS → ISO-8601 |
| 1A (Flag) | 1A | CHAR(1) or BOOLEAN | Boolean or Enum | Y/N → Boolean, A/I → Enum |

## Data Structures → JPA Entities

**RPG Data Structure:**
```rpg
D CustomerDS      DS                  QUALIFIED
D  CustomerId                   10A
D  SSN                           9S 0
D  FirstName                    50A
D  LastName                     50A
D  CreditScore                   9S 0
D  Status                        1A
```

**Java Entity:**
```java
@Entity
@Table(name = "customers")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Customer extends AuditableEntity {
    
    @Id
    @Column(name = "customer_id", length = 10)
    private String customerId;
    
    @Column(name = "ssn", length = 11, unique = true, nullable = false)
    private String ssn;
    
    @Column(name = "first_name", length = 50, nullable = false)
    private String firstName;
    
    @Column(name = "last_name", length = 50, nullable = false)
    private String lastName;
    
    @Column(name = "credit_score")
    private Integer creditScore;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 1)
    private CustomerStatus status;
}
```

## File Operations → Repository Methods

| RPG Operation | Java Repository Equivalent |
|---------------|----------------------------|
| `CHAIN key FILE` | `repository.findById(key)` |
| `SETLL key FILE; READE key FILE` | `repository.findAllByKey(key)` |
| `WRITE record` | `repository.save(entity)` |
| `UPDATE record` | `repository.save(entity)` (with existing ID) |
| `DELETE record` | `repository.delete(entity)` or `repository.deleteById(id)` |
| `CHAIN + %FOUND` | `repository.findById(id).isPresent()` |
| `CHAIN + UPDATE` | Pessimistic lock: `@Lock(PESSIMISTIC_WRITE)` |

## Procedures → Service Methods

**RPG Procedure:**
```rpg
P CreateCustomer  B                   EXPORT
D CreateCustomer  PI            10A
D  pSSN                          9S 0 CONST
D  pFirstName                   50A   CONST
D  pLastName                    50A   CONST

 /FREE
  CHAIN pSSN CUSTMAST;
  IF %FOUND(CUSTMAST);
    RETURN *BLANKS;
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

**Java Service Method:**
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerService {
    
    private final CustomerRepository customerRepository;
    
    @Transactional
    public Customer createCustomer(CreateCustomerRequest request) {
        // CHAIN + %FOUND check
        if (customerRepository.existsBySsn(request.getSsn())) {
            throw new DuplicateSSNException("Customer with SSN already exists");
        }
        
        // Record population
        Customer customer = Customer.builder()
                .customerId(generateCustomerId())
                .ssn(request.getSsn())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .status(CustomerStatus.ACTIVE)
                // Audit fields handled by JPA auditing
                .build();
        
        // WRITE operation (COMMIT/ROLLBACK handled by @Transactional)
        return customerRepository.save(customer);
    }
}
```

## Commitment Control → @Transactional

**RPG Commitment Control:**
```rpg
FCUSTMAST  UF   E           K DISK    COMMIT

CHAIN pCustomerId CUSTMAST;
IF %FOUND(CUSTMAST);
  BALANCE = BALANCE + pAmount;
  UPDATE CUSTMASTR;
  IF %ERROR();
    ROLLBACK;
  ELSE;
    COMMIT;
  ENDIF;
ENDIF;
```

**Java Transaction:**
```java
@Transactional  // Automatic COMMIT/ROLLBACK
public void updateBalance(String customerId, BigDecimal amount) {
    Customer customer = customerRepository.findById(customerId)
            .orElseThrow(() -> new CustomerNotFoundException(customerId));
    
    customer.setBalance(customer.getBalance().add(amount));
    // Transaction commits if no exception, rolls back on any exception
}
```

## Error Handling → Exceptions

**RPG Error Response:**
```rpg
D ResponseDS      DS                  QUALIFIED
D  Success                       1A
D  ErrorCode                     5A
D  ErrorMsg                     80A

IF NOT ValidateSSN(pSSN);
  wResponse.Success = 'N';
  wResponse.ErrorCode = 'E0003';
  wResponse.ErrorMsg = 'Invalid SSN format';
  RETURN wResponse;
ENDIF;
```

**Java Custom Exception:**
```java
// Define exception
public class InvalidSSNException extends RuntimeException {
    public InvalidSSNException(String ssn) {
        super("Invalid SSN format: " + ssn);
    }
}

// Throw exception
if (!validateSSN(request.getSsn())) {
    throw new InvalidSSNException(request.getSsn());
}

// Handle globally
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(InvalidSSNException.class)
    public ResponseEntity<ErrorResponse> handleInvalidSSN(InvalidSSNException ex) {
        ErrorResponse error = ErrorResponse.builder()
                .errorCode("E0003")
                .errorMessage(ex.getMessage())
                .timestamp(LocalDateTime.now())
                .build();
        return ResponseEntity.badRequest().body(error);
    }
}
```

## Audit Trail → JPA Auditing

**RPG Audit Trail:**
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

**Java JPA Auditing:**
```java
// Base entity class
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
    
    @CreatedBy
    @Column(name = "created_user", nullable = false, updatable = false)
    private String createdUser;
    
    @LastModifiedDate
    @Column(name = "updated_date")
    private LocalDate updatedDate;
    
    @LastModifiedDate
    @Column(name = "updated_time")
    private LocalTime updatedTime;
    
    @LastModifiedBy
    @Column(name = "updated_user")
    private String updatedUser;
}

// Enable JPA auditing
@Configuration
@EnableJpaAuditing
public class JpaAuditingConfiguration {
    
    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> Optional.ofNullable(SecurityContextHolder.getContext())
                .map(SecurityContext::getAuthentication)
                .filter(Authentication::isAuthenticated)
                .map(Authentication::getName);
    }
}
```

## Embedded SQL → JPQL/Native Queries

**RPG Embedded SQL:**
```rpg
EXEC SQL
  SELECT COUNT(*), COALESCE(AVG(BALANCE), 0)
  INTO :wTotalAccounts, :wAvgBalance
  FROM ACCTMAST
  WHERE CUSTID = :pCustomerId
    AND STATUS = 'A';
```

**Java JPQL Query:**
```java
public interface AccountRepository extends JpaRepository<Account, String> {
    
    @Query("SELECT COUNT(a), COALESCE(AVG(a.balance), 0) " +
           "FROM Account a " +
           "WHERE a.customer.customerId = :customerId " +
           "AND a.status = 'ACTIVE'")
    Object[] getAccountStats(@Param("customerId") String customerId);
}
```

## Validation → Bean Validation

**RPG Validation:**
```rpg
P ValidateSSN     B                   EXPORT
D ValidateSSN     PI             1N
D  pSSN                          9S 0 CONST

 /FREE
  IF pSSN = 0;
    RETURN *OFF;
  ENDIF;
  
  IF pSSN < 1000000 OR pSSN > 999999999;
    RETURN *OFF;
  ENDIF;
  
  RETURN *ON;
 /END-FREE
P ValidateSSN     E
```

**Java Bean Validation:**
```java
@Data
@Builder
public class CreateCustomerRequest {
    
    @NotBlank(message = "SSN is required")
    @Pattern(regexp = "\\d{3}-\\d{2}-\\d{4}", message = "SSN must be in format ###-##-####")
    private String ssn;
    
    @NotBlank(message = "First name is required")
    @Size(min = 1, max = 50)
    private String firstName;
    
    @Email(message = "Email must be valid")
    private String email;
}

// Custom validator
@Component
public class SSNValidator {
    
    public boolean isValid(String ssn) {
        if (ssn == null || ssn.isBlank()) {
            return false;
        }
        
        String digits = ssn.replaceAll("-", "");
        if (digits.length() != 9) {
            return false;
        }
        
        long ssnNumber = Long.parseLong(digits);
        return ssnNumber >= 1000000 && ssnNumber <= 999999999;
    }
}
```

## Constants

**RPG Constants:**
```rpg
D BASE_SCORE      C                   600
D APPROVE_THRESHOLD...
D                 C                   680
D MAX_OVERDRAFT   C                   1000.00
```

**Java Constants:**
```java
public class CreditScoreConstants {
    public static final int BASE_SCORE = 600;
    public static final int APPROVE_THRESHOLD = 680;
    public static final int REVIEW_THRESHOLD = 620;
    public static final BigDecimal MAX_OVERDRAFT = new BigDecimal("1000.00");
    
    private CreditScoreConstants() {
        // Utility class, prevent instantiation
    }
}
```

## Date/Time Handling

**RPG Date/Time:**
```rpg
D wCurrentDate    S              8S 0
D wCurrentTime    S              6S 0

wCurrentDate = %DEC(%CHAR(%DATE():*ISO):8:0);  // YYYYMMDD
wCurrentTime = %DEC(%CHAR(%TIME():*ISO):6:0);  // HHMMSS
```

**Java Date/Time:**
```java
LocalDate currentDate = LocalDate.now();  // 2025-11-06
LocalTime currentTime = LocalTime.now();  // 14:30:58.123

// Convert RPG format to Java
int rpgDate = 20251106;  // YYYYMMDD
LocalDate javaDate = LocalDate.of(
    rpgDate / 10000,           // Year
    (rpgDate / 100) % 100,     // Month
    rpgDate % 100              // Day
);

int rpgTime = 143058;  // HHMMSS
LocalTime javaTime = LocalTime.of(
    rpgTime / 10000,           // Hour
    (rpgTime / 100) % 100,     // Minute
    rpgTime % 100              // Second
);
```

## PostgreSQL Schema Conventions

**Table Naming:**
- Lowercase plural: `customers`, `accounts`, `transactions`
- Snake_case for multi-word: `transaction_logs`, `account_balances`

**Column Naming:**
- Snake_case: `customer_id`, `first_name`, `credit_score`
- Consistent suffixes: `_id` for IDs, `_date` for dates, `_amount` for currency

**Constraints:**
- Primary keys: Always define
- Foreign keys: Always define relationships
- Unique constraints: For natural keys (SSN)
- Check constraints: For enums and valid value ranges
- NOT NULL: For required fields

**Indexes:**
- `idx_{table}_{column}`: `idx_customers_ssn`
- Compound: `idx_{table}_{col1}_{col2}`: `idx_transactions_account_date`
- Partial: `WHERE status = 'A'` for active-only queries

---

Use this as a quick reference when converting RPG code to Java. For detailed conversion plans, use the `/convert-to-java` prompt which creates a comprehensive implementation plan.
