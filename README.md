# Legacy RPG Banking System - Context Engineering Demo

A comprehensive context engineering setup for maintaining and modernizing a legacy RPG banking application to Java 21 Spring Boot 3.x with PostgreSQL.

## 🎯 Overview

This project demonstrates best practices for using GitHub Copilot with custom instructions, chat modes, and prompt files to:
1. **Maintain legacy RPG code** with safety and consistency
2. **Plan conversions** from RPG to Java Spring Boot with detailed architecture
3. **Implement conversions** using Test-Driven Development (TDD)

## 📁 Project Structure

```
legacy-rpg/
├── .github/
│   ├── copilot-instructions.md          # Base Copilot instructions
│   ├── chatmodes/                        # Specialized AI agents
│   │   ├── rpg-maintain.chatmode.md     # RPG maintenance expert
│   │   ├── java-convert-plan.chatmode.md # Conversion planning architect
│   │   └── java-implement.chatmode.md    # Java TDD implementation expert
│   ├── prompts/                          # Reusable prompt templates
│   │   ├── add-rpg-feature.prompt.md    # Add RPG features safely
│   │   ├── convert-to-java.prompt.md    # Convert RPG to Java
│   │   └── rpg-to-java-mapping.prompt.md # Quick reference guide
│   └── plan-template.md                  # Conversion plan template
├── rpgle-programs/                       # Legacy RPG programs
│   ├── CUSTPROC.RPGLE                   # Customer management
│   ├── POSTTRAN.RPGLE                   # Transaction processing
│   └── CREDSCOR.RPGLE                   # Credit scoring
├── dds-files/                            # Database definitions
│   ├── CUSTMAST.PF                      # Customer master file
│   ├── ACCTMAST.PF                      # Account master file
│   └── TRANLOG.PF                       # Transaction log
├── PRODUCT.md                            # Business requirements
├── ARCHITECTURE.md                       # System architecture
├── CONTRIBUTING.md                       # Development guidelines
└── RPG-CONVENTIONS.md                    # RPG coding standards
```

## 🚀 Quick Start

### Prerequisites
- **VS Code** with GitHub Copilot extension
- Access to **GitHub Copilot Chat**
- Basic understanding of RPG/RPGLE or willingness to learn

### Setup
1. Clone or open this repository in VS Code
2. The `.github/copilot-instructions.md` is automatically loaded
3. Chat modes and prompts are ready to use

## 📖 Demo Scenarios

### Scenario 1: Maintain Legacy RPG Code

**Use Case:** Add phone number validation to customer creation

#### Step 1: Switch to RPG Maintenance Mode
In Copilot Chat, select the **rpg-maintain** chat mode from the dropdown.

#### Step 2: Use the Prompt
Type in chat:
```
/add-rpg-feature

I need to add phone number validation to the CreateCustomer procedure in CUSTPROC.RPGLE.

Requirements:
- Phone format: (###) ###-####
- Validate before writing customer record
- Return error code E0005 if invalid
- Follow existing email validation pattern
```

#### Step 3: Review the Plan
Copilot will:
1. Read `CUSTPROC.RPGLE` and existing validation patterns
2. Create a detailed plan showing:
   - New `ValidatePhone` procedure
   - Integration point in `CreateCustomer`
   - Error handling approach
   - Test scenarios

#### Step 4: Approve and Implement
After reviewing, respond:
```
Approved. Please implement the changes following RPG conventions.
```

Copilot will generate complete RPG code with:
- Free-format syntax
- Proper error checking
- Audit trail updates
- Inline documentation

---

### Scenario 2: Convert RPG Program to Java Spring Boot

**Use Case:** Convert `CUSTPROC.RPGLE` to Java with Spring Boot

#### Step 1: Use the Conversion Prompt
In a new Copilot Chat, type:
```
/convert-to-java

Program to convert: CUSTPROC.RPGLE

This program handles customer management including:
- Create customer with SSN validation
- Retrieve customer by ID
- Update customer information
- Credit score calculation integration

Please create a comprehensive conversion plan.
```

#### Step 2: Automatic Analysis
The **java-convert-plan** mode will automatically:
1. Launch a subagent to analyze `CUSTPROC.RPGLE` thoroughly
2. Read related files (`CUSTMAST.PF`, credit scoring procedures)
3. Document business logic and data structures
4. Create a detailed conversion plan

#### Step 3: Review the Conversion Plan
The plan will include:
- **Entity Design:** `Customer` JPA entity with relationships
- **Repository Layer:** `CustomerRepository` with custom queries
- **Service Layer:** `CustomerService` with business logic preservation
- **Database Schema:** PostgreSQL DDL with Flyway migration
- **Testing Strategy:** Unit tests (90%+) and integration tests
- **Tasks Breakdown:** Step-by-step implementation checklist
- **Data Mapping:** Complete RPG to Java/PostgreSQL mapping

Example sections:
```markdown
## Entity: Customer

| Java Field | Type | PostgreSQL Column | RPG Field |
|-----------|------|-------------------|-----------|
| customerId | String | customer_id VARCHAR(10) | CUSTID (10A) |
| ssn | String | ssn VARCHAR(11) UNIQUE | SSN (9S 0) |
| creditScore | Integer | credit_score INTEGER | CREDITSCORE (9S 0) |

## Service Method: createCustomer()

RPG Procedure: CreateCustomer
- Preserves SSN uniqueness check
- Maintains ACID transaction boundaries
- Audit trail via JPA auditing
```

#### Step 4: Approve Plan
Review the plan and respond:
```
The plan looks good. Please proceed with implementation using TDD approach.
```

#### Step 5: Handoff to Implementation
Copilot will offer a handoff button labeled **"Start Java Implementation"** which switches to **java-implement** mode and begins TDD implementation.

---

### Scenario 3: Implement with Test-Driven Development

**Use Case:** Implement the customer service following TDD

#### Step 1: Automatic Mode Switch
After approving the conversion plan, click **"Start Java Implementation"** handoff button.

#### Step 2: TDD Workflow Begins
The **java-implement** mode follows Red-Green-Refactor:

**Red Phase - Write Failing Test:**
```java
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
    
    // When
    Customer result = customerService.createCustomer(request);
    
    // Then
    assertThat(result).isNotNull();
    assertThat(result.getStatus()).isEqualTo(CustomerStatus.ACTIVE);
}
```

**Green Phase - Implement:**
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerService {
    
    private final CustomerRepository customerRepository;
    
    @Transactional
    public Customer createCustomer(CreateCustomerRequest request) {
        if (customerRepository.existsBySsn(request.getSsn())) {
            throw new DuplicateSSNException("Customer with SSN already exists");
        }
        
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

#### Step 3: Continue TDD Cycle
For each additional test case, prompt:
```
Add test for duplicate SSN validation
```

Copilot generates test → implementation → refactor cycle continues.

---

### Scenario 4: Quick Reference Lookup

**Use Case:** Need to know how to convert RPG CHAIN to Java

#### Use the Mapping Prompt
```
/rpg-to-java-mapping
```

Instantly get comprehensive mapping reference:
- Data type conversions
- File operations → Repository methods
- Procedures → Service methods
- Error handling patterns
- Date/time handling
- Transaction management

Example from reference:
```
RPG: CHAIN pCustomerId CUSTMAST
Java: customerRepository.findById(customerId)

RPG: IF %FOUND(CUSTMAST)
Java: customerRepository.findById(id).isPresent()
```

---

## 🎓 Advanced Usage

### Custom Planning for Complex Conversions

For batch programs like `EODPROC.CLLE`:
```
/convert-to-java

Program to convert: EODPROC.CLLE (End-of-Day batch processing)

This CL program orchestrates:
- Database backups
- Interest calculation (CALCINT)
- Statement generation (GENSTMT)
- Credit score batch updates (BATCHSCR)
- Daily reports (RPTDAILY, RPTBALS)

Convert to Spring Batch 5.x with proper job orchestration.
```

### Working with Credit Scoring Algorithm

To ensure exact business logic preservation:
```
I need to convert the credit scoring algorithm from CREDSCOR.RPGLE to Java.

The algorithm must produce EXACTLY the same results:
- Base score: 600
- Payment history: 35% weight (0-150 points)
- Debt ratio: 30% weight (0-100 points)
- Credit age: 15% weight (20-100 points)
- Income: 10% weight (20-100 points)
- Employment: 10% weight (20-100 points)
- Risk thresholds: 720+ (Low), 640-719 (Medium), <640 (High)

Create comprehensive unit tests comparing RPG and Java outputs.
```

---

## 📊 Testing the Setup

### Test RPG Maintenance Mode

1. Open `rpgle-programs/CUSTPROC.RPGLE`
2. Switch to **rpg-maintain** mode
3. Ask: "Explain the CreateCustomer procedure and its error handling"
4. Verify it understands commitment control, audit trails, and RPG patterns

### Test Java Conversion Planning

1. Use `/convert-to-java` with `CUSTPROC.RPGLE`
2. Verify plan includes:
   - Complete entity design with JPA annotations
   - Service layer with business logic preservation
   - PostgreSQL schema with constraints
   - Testing strategy with 90%+ coverage target
   - Task breakdown with specific steps

### Test Java Implementation Mode

1. After getting a conversion plan, accept handoff to **java-implement**
2. Request: "Implement the first task: Create database migration"
3. Verify it generates:
   - Flyway migration with proper versioning
   - Complete PostgreSQL DDL
   - Constraints, indexes, and comments

---

## 🎯 Key Benefits

### For RPG Maintenance
✅ **Safety First:** Commitment control and error checking enforced
✅ **Consistency:** Follows established RPG conventions
✅ **Audit Compliance:** Automatic audit trail updates
✅ **Pattern Reuse:** Leverages existing code patterns

### For Java Conversion
✅ **Business Logic Parity:** Exact preservation of algorithms
✅ **Modern Architecture:** Layered design with best practices
✅ **High Test Coverage:** 90%+ with TDD approach
✅ **Data Integrity:** ACID compliance with Spring transactions
✅ **Production Ready:** Complete, tested, documented code

### For Teams
✅ **Knowledge Preservation:** RPG expertise captured in documentation
✅ **Onboarding:** New developers learn patterns quickly
✅ **Quality Assurance:** Consistent code standards enforced
✅ **Migration Strategy:** Phased approach with clear milestones

---

## 🔍 Troubleshooting

### Agents Not Available?
- Ensure you're using GitHub Copilot Chat (not inline suggestions)
- Check that `.github/agents/` directory exists
- Restart VS Code to reload chat modes

### Prompts Not Working?
- Prompts start with `/` (e.g., `/convert-to-java`)
- Ensure `.github/prompts/` directory has `.prompt.md` files
- Try typing `/` in chat to see available prompts

### Context Not Loading?
- Verify `.github/copilot-instructions.md` exists
- File is automatically loaded for all chat interactions
- Reference documentation files are linked correctly

---

## 📚 Documentation Reference

| Document | Purpose | When to Use |
|----------|---------|-------------|
| `PRODUCT.md` | Business requirements and rules | Understanding feature requirements |
| `ARCHITECTURE.md` | System design and patterns | Making architectural decisions |
| `CONTRIBUTING.md` | Development workflow | Before coding or code review |
| `RPG-CONVENTIONS.md` | RPG syntax and patterns | Writing or reviewing RPG code |

---

## 🤝 Contributing

When adding new features to the context engineering setup:

1. **New Custom Agents:** Add to `.github/Agents/`
   - Include clear description and tools needed
   - Define workflow and core principles
   - Provide examples and patterns

2. **New Prompts:** Add to `.github/prompts/`
   - Use descriptive names
   - Include clear instructions
   - Reference appropriate chat mode

3. **Update Documentation:** Keep docs in sync
   - Update this README with new scenarios
   - Add examples to relevant docs
   - Update copilot-instructions.md if needed

---

## 📝 Example Conversation Flow

### Complete Conversion Example

```
User: /convert-to-java CUSTPROC.RPGLE

Copilot (java-convert-plan mode):
"I'll analyze CUSTPROC.RPGLE and create a comprehensive conversion plan...
[Launches subagent to read files autonomously]
[Creates detailed plan with entities, services, tests, migrations]

Here's the conversion plan:
# Implementation Plan: Customer Management Service
[... complete plan ...]

Review the plan and let me know if you'd like to proceed with implementation."

User: "Looks great! Please implement with TDD approach."

Copilot: "[Offers handoff to java-implement mode]"
[User clicks "Start Java Implementation"]

Copilot (java-implement mode):
"I'll implement using TDD. Starting with database migration...

[Generates V1__create_customers_table.sql]

Now let's write the first test...

[Generates CustomerServiceTest with failing test]

Running test... ❌ (Expected - Red phase)

Now implementing CustomerService...

[Generates CustomerService code]

Running test... ✅ (Green phase)

Refactoring for better readability...

[Improves code while keeping tests green]

Ready for next test case!"
```

---

## 🎉 Success Metrics

After using this setup, you should see:

- ⚡ **Faster Development:** 3-5x speed increase for conversions
- 🎯 **Higher Quality:** 90%+ test coverage achieved automatically
- 🔒 **Fewer Bugs:** Business logic parity verification built-in
- 📖 **Better Documentation:** Comprehensive plans and code comments
- 🚀 **Smoother Onboarding:** New developers productive in days, not weeks

---

## 🆘 Need Help?

### Common Questions

**Q: Can I use this for other legacy systems?**
A: Yes! Adapt the chat modes and documentation for your specific language and domain.

**Q: Do I need to know RPG to use the Java conversion?**
A: No, the planning mode analyzes RPG code and explains the business logic in the plan.

**Q: Can I customize the test coverage requirements?**
A: Yes, edit `.github/chatmodes/java-implement.chatmode.md` to adjust coverage targets.

**Q: How do I add support for other frameworks?**
A: Create new chat modes in `.github/chatmodes/` for your target framework.

### Getting More Help

- Review the [VS Code Copilot Documentation](https://code.visualstudio.com/docs/copilot/overview)
- Check [Context Engineering Guide](https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide)
- Read inline comments in chat mode files for customization tips

---

## 📄 License

This context engineering setup is provided as-is for demonstration and educational purposes.

---

**Built with ❤️ to demonstrate effective AI-assisted legacy system modernization**
