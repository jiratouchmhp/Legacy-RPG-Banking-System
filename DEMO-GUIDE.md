# Legacy RPG Banking System - Complete Demo Guide

## 🎯 Project Overview

This is a **Legacy Banking System Context Engineering Demo** that showcases how to effectively use GitHub Copilot with custom instructions, specialized agents, and structured prompts to:

1. **Maintain legacy RPG/RPGLE code** safely and consistently
2. **Plan conversions** from RPG to Java Spring Boot with detailed architecture
3. **Implement conversions** using Test-Driven Development (TDD)

## 📋 Prerequisites

### Required Software
- **VS Code** with GitHub Copilot extension enabled
- **GitHub Copilot Chat** access
- **Java 21** (for Java conversion demos)
- **PostgreSQL** (for database demos)
- **Maven** or **Gradle** (for Java build)

### Required Knowledge
- Basic understanding of banking/financial concepts
- Willingness to learn RPG concepts (no prior experience needed)
- Basic Java knowledge (for conversion scenarios)

## 🚀 Getting Started

### Step 1: Environment Setup

1. **Open the project** in VS Code:
   ```bash
   cd /Users/jiratouchm./Desktop/Legacy-RPG-Banking-System
   code .
   ```

2. **Verify GitHub Copilot** is active:
   - Check the Copilot icon in VS Code status bar
   - Open Copilot Chat (`Ctrl+Shift+I` or `Cmd+Shift+I`)

3. **Confirm context loading**:
   - The `.github/copilot-instructions.md` file automatically provides context
   - Custom agents are available in `.github/agents/`
   - Prompts are available in `.github/prompts/`

### Step 2: Understand the Project Structure

```
Legacy-RPG-Banking-System/
├── .github/
│   ├── copilot-instructions.md          # Main Copilot instructions
│   ├── agents/                          # Specialized AI agents
│   │   ├── rpg-maintain.agent.md       # RPG maintenance expert
│   │   ├── java-convert-plan.agent.md  # Conversion planning architect
│   │   └── java-implement.agent.md     # Java TDD implementation expert
│   ├── prompts/                         # Reusable prompt templates
│   │   ├── add-rpg-feature.prompt.md   # Add RPG features safely
│   │   ├── convert-to-java.prompt.md   # Convert RPG to Java
│   │   └── rpg-to-java-mapping.prompt.md # Quick reference guide
│   └── plan-template.md                 # Conversion plan template
├── rpgle-programs/                      # Legacy RPG programs
│   ├── CUSTPROC.RPGLE                  # Customer management (507 lines)
│   ├── POSTTRAN.RPGLE                  # Transaction processing
│   └── CREDSCOR.RPGLE                  # Credit scoring algorithm
├── dds-files/                           # Database definitions
│   ├── CUSTMAST.PF                     # Customer master file
│   ├── ACCTMAST.PF                     # Account master file
│   └── TRANLOG.PF                      # Transaction log
├── cl-programs/
│   └── EODPROC.CLLE                    # End-of-day batch processing
├── sql-scripts/
│   └── create-tables.sql               # PostgreSQL equivalent tables
├── PRODUCT.md                          # Business requirements & features
├── ARCHITECTURE.md                     # System design & architecture
├── CONTRIBUTING.md                     # Development guidelines
└── RPG-CONVENTIONS.md                  # RPG coding standards
```

## 🎬 Demo Scenarios

## Scenario 1: Understanding the Legacy System

### Objective
Get familiar with the banking system's architecture and business logic.

### Steps

1. **Open Copilot Chat** and ask:
   ```
   Please explain this legacy banking system. What are the main components and business processes?
   ```

2. **Explore customer management** by opening `rpgle-programs/CUSTPROC.RPGLE`:
   ```
   Explain the customer creation process in CUSTPROC.RPGLE. What validations are performed?
   ```

3. **Review the database structure** by opening `dds-files/CUSTMAST.PF`:
   ```
   Explain the customer master file structure. What are the key fields and their purposes?
   ```

### Expected Results
- Clear explanation of the banking system architecture
- Understanding of RPG programming patterns
- Knowledge of data validation and audit trails

---

## Scenario 2: RPG Code Maintenance (Safe Legacy Updates)

### Objective
Demonstrate how to safely maintain and extend legacy RPG code using specialized agents.

### Step 1: Switch to RPG Maintenance Mode

1. Open Copilot Chat
2. Type `@rpg-maintain` to activate the RPG maintenance agent
3. The agent will focus on RPG best practices and safety

### Step 2: Add Phone Number Validation

**Prompt:**
```
I need to add phone number validation to the CreateCustomer procedure in CUSTPROC.RPGLE.

Requirements:
- Phone format: (###) ###-####
- Validate before writing customer record
- Return error code E0005 if invalid
- Follow existing email validation pattern
- Maintain commitment control and audit trails
```

### Step 3: Review the Implementation Plan

The RPG maintenance agent will:
1. Analyze the existing `CUSTPROC.RPGLE` file
2. Identify the email validation pattern to follow
3. Create a detailed plan showing:
   - New `ValidatePhone` procedure design
   - Integration point in `CreateCustomer` procedure
   - Error handling approach with proper rollback
   - Test scenarios for validation

### Step 4: Implement the Changes

**Follow-up prompt:**
```
The plan looks good. Please implement the phone validation following RPG conventions.
```

### Expected Results
- Complete RPG procedure with free-format syntax
- Proper error checking with `%ERROR()` 
- Commitment control with COMMIT/ROLLBACK
- Audit trail updates (CRTDATE, CRTTIME, CRTUSER)
- Inline documentation and comments

---

## Scenario 3: Java Conversion Planning (Architecture Design)

### Objective
Plan the conversion of RPG programs to Java Spring Boot with detailed architecture.

### Step 1: Activate Conversion Planning Mode

1. Open a new Copilot Chat session
2. Type `@java-convert-plan` to activate the conversion planning agent

### Step 2: Plan Customer Service Conversion

**Prompt:**
```
/convert-to-java

Program to convert: CUSTPROC.RPGLE

This program handles customer management including:
- Create customer with SSN validation
- Retrieve customer by ID and SSN
- Update customer information
- Delete customer (soft delete)
- Credit score calculation integration
- Comprehensive audit trail

Please create a detailed conversion plan with modern Java architecture.
```

### Step 3: Review the Comprehensive Plan

The conversion planning agent will automatically:
1. **Analyze the RPG program** thoroughly
2. **Read related files** (CUSTMAST.PF, CREDSCOR.RPGLE)
3. **Document business logic** and data validation rules
4. **Create detailed conversion plan** including:

   - **Entity Design**
     ```java
     @Entity
     @Table(name = "customers")
     public class Customer extends AuditableEntity {
         @Id
         @Column(name = "customer_id", length = 10)
         private String customerId;
         
         @Column(name = "ssn", length = 11, unique = true, nullable = false)
         private String ssn;
         // ... other fields
     }
     ```

   - **Repository Layer**
     ```java
     @Repository
     public interface CustomerRepository extends JpaRepository<Customer, String> {
         boolean existsBySsn(String ssn);
         Optional<Customer> findBySsn(String ssn);
     }
     ```

   - **Service Layer** with business logic preservation
   - **Database Schema** (PostgreSQL DDL with Flyway migration)
   - **Testing Strategy** (Unit tests with 90%+ coverage target)
   - **Complete Data Mapping** (RPG ↔ Java ↔ PostgreSQL)

### Step 4: Approve and Proceed

**Follow-up prompt:**
```
The conversion plan looks comprehensive. Please proceed with implementation using TDD approach.
```

### Expected Results
- Complete architectural blueprint for Java conversion
- Database migration scripts (Flyway/Liquibase)
- Entity relationship diagrams
- Service layer design with transaction boundaries
- Testing strategy with specific coverage targets

---

## Scenario 4: Java Implementation (Test-Driven Development)

### Objective
Implement the Java conversion using Test-Driven Development methodology.

### Step 1: Automatic Mode Transition

After approving the conversion plan, the agent will offer:
```
🔄 Ready to start implementation? 
[Switch to Java Implementation Mode]
```

Click the handoff to activate `@java-implement` agent.

### Step 2: TDD Red-Green-Refactor Cycle

The Java implementation agent follows strict TDD:

**Red Phase - Write Failing Test:**
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
                .email("john.doe@email.com")
                .build();
        
        when(customerRepository.existsBySsn(anyString())).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(i -> i.getArgument(0));
        
        // When
        Customer result = customerService.createCustomer(request);
        
        // Then
        assertThat(result).isNotNull();
        assertThat(result.getFirstName()).isEqualTo("John");
        assertThat(result.getStatus()).isEqualTo(CustomerStatus.ACTIVE);
        verify(customerRepository).save(any(Customer.class));
    }
}
```

**Green Phase - Minimal Implementation:**
```java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CustomerService {
    
    private final CustomerRepository customerRepository;
    
    public Customer createCustomer(CreateCustomerRequest request) {
        // Validate SSN uniqueness (preserve RPG business logic)
        if (customerRepository.existsBySsn(request.getSsn())) {
            throw new DuplicateSSNException("Customer with SSN already exists");
        }
        
        // Create customer entity (preserve RPG data structure)
        Customer customer = Customer.builder()
                .customerId(generateCustomerId())
                .ssn(request.getSsn())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .status(CustomerStatus.ACTIVE)
                .build();
        
        return customerRepository.save(customer);
    }
}
```

**Refactor Phase:**
Improve code quality while keeping tests green.

### Step 3: Continue TDD Cycle

**Prompt for next test:**
```
Add test for duplicate SSN validation with proper exception handling.
```

The agent will:
1. Write failing test for duplicate SSN scenario
2. Update implementation to handle the exception
3. Refactor for better error handling

### Expected Results
- Complete Spring Boot service with 90%+ test coverage
- All business logic preserved from RPG original
- Proper exception handling and validation
- Transaction management with `@Transactional`
- Comprehensive unit and integration tests

---

## Scenario 5: Complex Algorithm Conversion (Credit Scoring)

### Objective
Convert the credit scoring algorithm ensuring exact business logic preservation.

### Step 1: Analyze the Algorithm

**Prompt:**
```
Please analyze the credit scoring algorithm in CREDSCOR.RPGLE and explain the business logic.
```

### Step 2: Convert with Exact Logic Preservation

**Prompt:**
```
Convert the credit scoring algorithm from CREDSCOR.RPGLE to Java.

Critical requirements:
- Algorithm must produce EXACTLY the same results
- Base score: 600
- Payment history: 35% weight (0-150 points)
- Debt ratio: 30% weight (0-100 points)  
- Credit age: 15% weight (20-100 points)
- Income: 10% weight (20-100 points)
- Employment: 10% weight (20-100 points)
- Risk levels: 720+ (Low), 640-719 (Medium), <640 (High)

Create comprehensive unit tests comparing RPG and Java outputs with same inputs.
```

### Expected Results
- Java implementation with identical algorithm logic
- Parameterized tests comparing RPG vs Java results
- Business rule validation tests
- Performance benchmarks

---

## Scenario 6: Batch Processing Conversion (Spring Batch)

### Objective
Convert end-of-day batch processing from CL to Spring Batch.

### Step 1: Analyze Batch Program

**Prompt:**
```
Analyze EODPROC.CLLE and create a conversion plan for Spring Batch 5.x.

This CL program orchestrates:
- Database backups
- Interest calculation
- Statement generation  
- Credit score batch updates
- Daily reconciliation reports

Design a Spring Batch workflow with proper job orchestration and error handling.
```

### Expected Results
- Spring Batch job configuration
- Step-by-step processing workflow
- Error handling and restart capabilities
- Job scheduling configuration

---

## Scenario 7: Quick Reference Lookup

### Objective
Get instant mapping references for common RPG to Java conversions.

### Step 1: Use Quick Reference Prompt

**Prompt:**
```
/rpg-to-java-mapping

Show me how to convert RPG file operations to Java Repository methods.
```

### Expected Results
Instant reference showing:
```
RPG → Java Mapping Reference

File Operations:
RPG: CHAIN pCustomerId CUSTMAST
Java: customerRepository.findById(customerId)

RPG: IF %FOUND(CUSTMAST)  
Java: customerRepository.findById(id).isPresent()

RPG: UPDATE CUSTMASTR
Java: customerRepository.save(customer)

Data Types:
RPG: 10A → Java: String (max 10 chars)
RPG: 9S 0 → Java: Integer  
RPG: 15P 2 → Java: BigDecimal(15,2)
RPG: 8S 0 (date) → Java: LocalDate
```

---

## 🧪 Testing Your Setup

### Test 1: RPG Maintenance Agent

1. Open `rpgle-programs/CUSTPROC.RPGLE`
2. Activate `@rpg-maintain` agent
3. Ask: "Explain the CreateCustomer procedure and suggest improvements"
4. **Verify**: Agent understands RPG syntax, commitment control, and audit patterns

### Test 2: Java Conversion Planning

1. Use `/convert-to-java` prompt with `CUSTPROC.RPGLE`
2. **Verify** plan includes:
   - Complete JPA entity design
   - Repository layer with custom queries
   - Service layer with business logic
   - PostgreSQL schema with constraints
   - Testing strategy with coverage targets
   - Step-by-step implementation tasks

### Test 3: Java Implementation Mode

1. After conversion plan approval, accept handoff to `@java-implement`
2. Request: "Implement the database migration first"
3. **Verify** generates:
   - Flyway migration with proper versioning
   - Complete PostgreSQL DDL  
   - Constraints, indexes, and foreign keys
   - Rollback instructions

---

## 🎯 Success Metrics

After completing these demos, you should achieve:

### **Development Speed**
- ⚡ **3-5x faster** conversions compared to manual approach
- 🎯 **90%+ test coverage** achieved automatically
- 📖 **Comprehensive documentation** generated with code

### **Code Quality**
- 🔒 **Business logic parity** verified through testing
- 🏗️ **Modern architecture** with Spring Boot best practices
- 📋 **Complete audit trails** preserved from legacy system

### **Team Benefits**
- 📚 **Knowledge preservation** through detailed plans
- 🚀 **Faster onboarding** for new team members
- ✅ **Consistent standards** across all conversions

---

## 🛠️ Customization Guide

### Adding New Agents

Create new agent files in `.github/agents/`:

```markdown
# Agent Name: my-custom-agent

## Description
Specialized agent for [specific purpose]

## Core Principles
- [Principle 1]
- [Principle 2]

## Workflow
1. [Step 1]
2. [Step 2]

## Tools & Capabilities
- [Tool 1]: [Purpose]
- [Tool 2]: [Purpose]
```

### Adding New Prompts

Create prompt files in `.github/prompts/`:

```markdown
# Slash Command: /my-custom-prompt

## Description
[What this prompt does]

## Usage
```
/my-custom-prompt [parameters]
```

## Instructions
[Detailed instructions for the AI]
```

### Customizing for Other Legacy Systems

1. **Update context files**: Modify `PRODUCT.md`, `ARCHITECTURE.md` for your domain
2. **Adapt agents**: Update agent files for your specific technologies
3. **Create new prompts**: Add prompts for your conversion scenarios
4. **Update conventions**: Modify coding standards for your languages

---

## 🆘 Troubleshooting

### Agents Not Available
- ✅ Ensure `.github/agents/` directory exists with `.agent.md` files
- ✅ Restart VS Code to reload chat modes
- ✅ Check GitHub Copilot Chat is enabled (not just inline suggestions)

### Prompts Not Working
- ✅ Prompts must start with `/` (e.g., `/convert-to-java`)
- ✅ Verify `.github/prompts/` has `.prompt.md` files
- ✅ Try typing `/` in chat to see available prompts

### Context Not Loading
- ✅ Verify `.github/copilot-instructions.md` exists and is properly formatted
- ✅ Check that documentation files (PRODUCT.md, etc.) are accessible
- ✅ Ensure file references in instructions use correct paths

### Conversion Plans Too Generic
- ✅ Provide more specific business requirements in your prompts
- ✅ Reference specific RPG procedures or business rules
- ✅ Ask for business logic preservation verification

---

## 📚 Additional Resources

### Documentation Deep Dive
- **`PRODUCT.md`**: Complete business requirements and rules
- **`ARCHITECTURE.md`**: System design patterns and data models  
- **`CONTRIBUTING.md`**: Development workflow and standards
- **`RPG-CONVENTIONS.md`**: RPG syntax patterns and idioms

### External Resources
- [VS Code Copilot Documentation](https://code.visualstudio.com/docs/copilot/overview)
- [Context Engineering Guide](https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide) 
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 🎉 Conclusion

This demo showcases a complete **Context Engineering** approach to legacy system modernization. By using:

- **Specialized AI agents** for different phases
- **Structured prompts** for common tasks  
- **Comprehensive documentation** for context
- **Test-Driven Development** for quality

You can achieve faster, safer, and more consistent legacy system conversions while preserving critical business logic and maintaining high code quality.

The setup is designed to be **adaptable** - use it as a foundation for your own legacy modernization projects by customizing the agents, prompts, and documentation for your specific technologies and business domain.

---

**Happy coding! 🚀**