# Legacy Banking System - Architecture Overview

## System Architecture

### Current Architecture (Legacy RPG/IBM i)

```
┌─────────────────────────────────────────────────────────┐
│                    IBM i (AS/400)                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  CUSTPROC    │  │  POSTTRAN    │  │  CREDSCOR    │ │
│  │  (RPGLE)     │  │  (RPGLE)     │  │  (RPGLE)     │ │
│  │              │  │              │  │              │ │
│  │ Customer Mgmt│  │ Transaction  │  │ Credit Score │ │
│  │ CRUD + Audit │  │ Processing   │  │ Calculation  │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                  │                  │         │
│         └──────────────────┼──────────────────┘         │
│                            │                            │
│  ┌─────────────────────────┴──────────────────────┐    │
│  │         DB2 for i (Commitment Control)         │    │
│  ├────────────────────────────────────────────────┤    │
│  │  CUSTMAST.PF  │  ACCTMAST.PF  │  TRANLOG.PF   │    │
│  │  (Customers)  │  (Accounts)   │  (Transactions)│    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  EODPROC.CLLE (Batch Orchestration)              │  │
│  │  ├─ Database Backups                             │  │
│  │  ├─ Interest Calculation (CALCINT)               │  │
│  │  ├─ Statement Generation (GENSTMT)               │  │
│  │  ├─ Credit Score Batch Update (BATCHSCR)         │  │
│  │  └─ Report Generation (RPTDAILY, RPTBALS)        │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Target Architecture (Java Spring Boot / PostgreSQL)

```
┌──────────────────────────────────────────────────────────────────┐
│                     Spring Boot Application                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              REST API Layer (Controllers)                │    │
│  │  ┌───────────┐  ┌────────────┐  ┌──────────────┐       │    │
│  │  │ Customer  │  │Transaction │  │ CreditScore  │       │    │
│  │  │Controller │  │Controller  │  │Controller    │       │    │
│  │  └─────┬─────┘  └──────┬─────┘  └──────┬───────┘       │    │
│  └────────┼────────────────┼────────────────┼───────────────┘    │
│           │                │                │                    │
│  ┌────────┴────────────────┴────────────────┴───────────────┐   │
│  │               Service Layer (Business Logic)             │   │
│  │  ┌───────────────┐  ┌─────────────────┐  ┌────────────┐ │   │
│  │  │CustomerService│  │TransactionService│  │CreditScore │ │   │
│  │  │               │  │                  │  │Service     │ │   │
│  │  │- Validation   │  │- ACID Processing │  │- Algorithm │ │   │
│  │  │- Audit Trail  │  │- Balance Updates │  │- Risk Calc │ │   │
│  │  │- Credit Score │  │- Logging         │  │- Recommend │ │   │
│  │  └───────┬───────┘  └────────┬─────────┘  └─────┬──────┘ │   │
│  └──────────┼──────────────────┼─────────────────┼──────────┘   │
│             │                   │                  │              │
│  ┌──────────┴───────────────────┴──────────────────┴──────────┐ │
│  │           Repository Layer (Spring Data JPA)               │ │
│  │  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐     │ │
│  │  │CustomerRepo  │  │AccountRepo  │  │TransactionRepo│    │ │
│  │  └──────┬───────┘  └──────┬──────┘  └──────┬───────┘     │ │
│  └─────────┼──────────────────┼─────────────────┼─────────────┘ │
│            │                  │                 │                │
│  ┌─────────┴──────────────────┴─────────────────┴─────────────┐ │
│  │              JPA Entity Layer                               │ │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────┐               │ │
│  │  │ Customer │  │ Account  │  │Transaction │               │ │
│  │  │ @Entity  │  │ @Entity  │  │ @Entity    │               │ │
│  │  └────┬─────┘  └────┬─────┘  └─────┬──────┘               │ │
│  └───────┼──────────────┼──────────────┼────────────────────────┘ │
│          │              │              │                        │
├──────────┴──────────────┴──────────────┴────────────────────────┤
│                    PostgreSQL Database                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  customers   │  │  accounts    │  │ transactions │         │
│  │              │  │              │  │              │         │
│  │ - Constraints│  │ - Foreign Key│  │ - Audit Log  │         │
│  │ - Indexes    │  │ - Triggers   │  │ - Partitions │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Spring Batch (End-of-Day Processing)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐      │
│  │ Interest │→ │Statement │→ │ Credit   │→ │Transaction│      │
│  │ Calc Job │  │ Gen Job  │  │Score Job │  │Archive Job│      │
│  └──────────┘  └──────────┘  └──────────┘  └───────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Design Principles

### 1. Layered Architecture
- **Presentation Layer:** REST Controllers with DTOs
- **Business Layer:** Services with business logic and validation
- **Data Access Layer:** JPA Repositories
- **Database Layer:** PostgreSQL with proper schema design

### 2. Separation of Concerns
- Controllers handle HTTP requests/responses only
- Services contain business logic and orchestration
- Repositories handle data persistence
- Entities represent database tables

### 3. Transaction Management
- **Legacy:** Commitment control with manual COMMIT/ROLLBACK
- **Modern:** Spring `@Transactional` with declarative transaction boundaries
- **Strategy:** Pessimistic locking for high-contention operations

### 4. Data Integrity
- **ACID Compliance:** All financial operations are transactional
- **Constraints:** Database-level foreign keys and unique constraints
- **Validation:** Multi-layer validation (controller, service, database)
- **Audit Trail:** JPA auditing with `@CreatedDate`, `@LastModifiedDate`

### 5. Error Handling
- **Global Exception Handler:** Centralized error handling with `@ControllerAdvice`
- **Custom Exceptions:** Domain-specific exceptions for business rules
- **Error Responses:** Consistent error response structure with error codes

## Key Components

### Entity Relationships

```
Customer (1) ──────┬──────> (*) Account
                   │
                   │ OneToMany
                   │
                   └──────> (1) CreditScore

Account (1) ──────────────> (*) Transaction
              OneToMany
```

### Data Model Mapping

| Legacy (DB2/DDS) | Modern (PostgreSQL/JPA) |
|------------------|-------------------------|
| CUSTMAST.PF | customers table (Customer entity) |
| ACCTMAST.PF | accounts table (Account entity) |
| TRANLOG.PF | transactions table (Transaction entity) |
| Numeric SSN (9S0) | VARCHAR(11) with format validation |
| CHAR dates (8S0) | LocalDate (ISO-8601) |
| CHAR times (6S0) | LocalTime (ISO-8601) |
| PACKED decimals (15P2) | DECIMAL(15,2) |
| Record locking | JPA `@Lock(PESSIMISTIC_WRITE)` |
| COMMIT/ROLLBACK | `@Transactional` with rollbackFor |

### Transaction Processing Flow

```
1. Request Validation
   ├─ Controller validates request DTO
   └─ Bean Validation annotations (@NotNull, @Positive, etc.)

2. Service Layer Processing
   ├─ @Transactional begins transaction
   ├─ Acquire pessimistic lock on account(s)
   ├─ Validate business rules
   │  ├─ Account status (must be Active)
   │  ├─ Sufficient funds check
   │  └─ Overdraft protection logic
   ├─ Update account balance(s)
   ├─ Create transaction log entry
   └─ Transaction commits or rolls back on exception

3. Response Generation
   ├─ Map entity to response DTO
   └─ Return success/error response
```

### Credit Scoring Algorithm

```java
// Implemented as a Spring Service
@Service
public class CreditScoreService {
    
    private static final int BASE_SCORE = 600;
    private static final Map<Integer, Double> INTEREST_RATE_TIERS = Map.of(
        760, 3.5, 720, 4.0, 680, 5.0, 640, 6.5, 0, 8.5
    );
    
    public CreditScoreResult calculateScore(Customer customer) {
        int paymentScore = calculatePaymentHistory(customer); // 35% weight
        int debtScore = calculateDebtRatio(customer);          // 30% weight
        int ageScore = calculateCreditAge(customer);           // 15% weight
        int incomeScore = calculateIncomeLevel(customer);      // 10% weight
        int employScore = calculateEmployment(customer);       // 10% weight
        
        int totalScore = BASE_SCORE + paymentScore + debtScore + 
                         ageScore + incomeScore + employScore;
        
        return new CreditScoreResult(
            totalScore,
            determineRiskLevel(totalScore),
            determineLoanRecommendation(totalScore),
            determineInterestRate(totalScore)
        );
    }
}
```

## Technology Stack

### Core Framework
- **Java 21** (LTS) with Virtual Threads support
- **Spring Boot 3.x** (latest stable)
- **Spring Framework 6.x**

### Data & Persistence
- **PostgreSQL 16+** with JSONB for flexible audit data
- **Spring Data JPA** with Hibernate 6.x
- **Flyway** or **Liquibase** for database migrations
- **HikariCP** for connection pooling

### API & Web
- **Spring Web MVC** for REST APIs
- **Spring HATEOAS** for hypermedia APIs (optional)
- **OpenAPI 3.0** (springdoc-openapi) for API documentation
- **Bean Validation** (JSR-380) for request validation

### Batch Processing
- **Spring Batch 5.x** for end-of-day jobs
- **Quartz Scheduler** for job scheduling

### Testing
- **JUnit 5** (Jupiter) for unit tests
- **Mockito** for mocking
- **Testcontainers** for integration tests with real PostgreSQL
- **AssertJ** for fluent assertions
- **REST Assured** for API testing

### Security
- **Spring Security 6.x** for authentication/authorization
- **BCrypt** for password hashing
- **JWT** for stateless authentication (if REST-only)

### Observability
- **Spring Boot Actuator** for health checks and metrics
- **Micrometer** with Prometheus for metrics
- **SLF4J + Logback** for logging
- **Spring Boot Admin** (optional) for monitoring

### Development Tools
- **Lombok** to reduce boilerplate
- **MapStruct** for entity-DTO mapping
- **Maven** or **Gradle** for build management

## Configuration Management

### Application Properties Structure
```
application.yml                    # Base configuration
application-dev.yml               # Development overrides
application-test.yml              # Test overrides
application-prod.yml              # Production overrides
```

### Key Configuration Areas
- Database connection pooling (HikariCP settings)
- JPA/Hibernate configuration (DDL auto, SQL logging)
- Transaction timeout settings
- Batch job parameters
- Logging levels per package
- Security settings (CORS, CSRF)

## Deployment Architecture

### Development
- **Docker Compose:** PostgreSQL + Spring Boot app
- **Local IDE:** IntelliJ IDEA or Eclipse with Spring Tools

### Testing
- **Testcontainers:** Spin up PostgreSQL for integration tests
- **In-memory H2:** For fast unit tests (when appropriate)

### Production
- **Container Platform:** Docker / Kubernetes
- **Database:** Managed PostgreSQL (AWS RDS, Azure Database, etc.)
- **Load Balancer:** Application-level load balancing
- **Monitoring:** Prometheus + Grafana

## Migration Considerations

### Data Migration Strategy
1. **Schema Mapping:** Create PostgreSQL schema matching DB2 structure
2. **Data Types:** Map RPG numeric/character types to PostgreSQL types
3. **ETL Process:** Extract from DB2, transform data formats, load to PostgreSQL
4. **Validation:** Checksum validation, row count verification
5. **Cutover:** Phased migration with rollback plan

### Hybrid Operation Period
- Dual-write to both systems during transition
- Read-only queries from legacy for validation
- Gradual traffic migration with feature flags
- Real-time data reconciliation

### Code Migration Pattern
```
RPG Program → Java Service + Repository + Entity
- CUSTPROC.RPGLE → CustomerService + CustomerRepository + Customer entity
- POSTTRAN.RPGLE → TransactionService + TransactionRepository + Transaction entity
- CREDSCOR.RPGLE → CreditScoreService (pure business logic)
- EODPROC.CLLE → Spring Batch jobs (InterestJob, StatementJob, etc.)
```

## Performance Considerations

### Database Optimization
- **Indexes:** Create indexes on foreign keys, frequently queried columns
- **Connection Pooling:** HikariCP with optimal pool size
- **Query Optimization:** Use JPA query hints, fetch strategies
- **Partitioning:** Partition transactions table by date for large datasets

### Application Optimization
- **Caching:** Spring Cache with Redis for credit scores, customer data
- **Lazy Loading:** Use lazy fetch for large collections
- **Batch Operations:** Use batch inserts/updates for bulk operations
- **Virtual Threads:** Java 21 virtual threads for high concurrency

### Monitoring & Tuning
- **Slow Query Log:** Enable PostgreSQL slow query logging
- **JVM Metrics:** Monitor heap, GC, thread pools
- **Transaction Metrics:** Monitor transaction duration, rollback rate
- **API Response Times:** Track p50, p95, p99 latencies

## Security Architecture

### Authentication & Authorization
- **Spring Security:** Role-based access control (RBAC)
- **Roles:** TELLER, CSR, CREDIT_OFFICER, ADMIN, OPERATIONS
- **Method Security:** `@PreAuthorize` annotations on service methods

### Data Protection
- **Encryption at Rest:** PostgreSQL transparent data encryption
- **Encryption in Transit:** TLS/SSL for all connections
- **Sensitive Data:** Mask SSN, account numbers in logs
- **Audit Logging:** All data modifications logged with user context

### Compliance
- **Audit Trail:** Immutable audit logs with who, what, when
- **Data Retention:** Automated archiving per regulatory requirements
- **Access Logging:** Track all data access for compliance reporting
