# Legacy RPG Banking System - Demo Guide

## 🎯 Overview

This guide demonstrates how to use GitHub Copilot with specialized agents and prompts to maintain legacy RPG code and convert it to Java Spring Boot with Spring Batch.

**What You'll Learn:**
- Maintain and extend RPG/RPGLE programs safely
- Plan RPG to Java conversions with detailed architecture
- Implement conversions using Test-Driven Development (TDD)
- Use AI agents for planning and implementation workflows

---

## ⚡ Quick Start (30 seconds)

1. **Open project in VS Code**: `code /Users/jiratouchm./Desktop/Legacy-RPG-Banking-System`
2. **Open Copilot Chat**: `Cmd+Shift+I` (Mac) or `Ctrl+Shift+I` (Windows/Linux)
3. **Verify agents available**: Type `@` in chat to see available agents
4. **Try your first prompt**: `@rpg-maintain explain CUSTPROC.RPGLE`

✅ **Working?** You should see a detailed explanation of the customer management program.

---

## 📚 Quick Reference

### Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `@rpg-maintain-planning` | Analyze RPG code & create implementation plans | Adding/modifying RPG features |
| `@rpg-implement` | Implement RPG features with best practices | After approving RPG plan |
| `@java-convert-plan` | Analyze RPG & create Java conversion plans | Converting RPG programs to Java |
| `@java-implement` | Implement Java code with TDD | After approving Java conversion plan |

### Available Prompts

| Prompt | Agent | Purpose |
|--------|-------|---------|
| `/add-rpg-feature` | rpg-maintain-planning | Add features to RPG programs |
| `/convert-to-java` | java-convert-plan | Convert RPG to Java |
| `/rpg-to-java-mapping` | Any | Quick reference for RPG↔Java mappings |

### Agent Workflow

```
┌─────────────────────────────────────────────────────┐
│              RPG Maintenance Workflow                │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  @rpg-maintain-planning        │
        │  (Create detailed plan)        │
        └────────────────────────────────┘
                         │
                         ▼ (User approves)
        ┌────────────────────────────────┐
        │  @rpg-implement                │
        │  (Implement with RPG best      │
        │   practices & error handling)  │
        └────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│           Java Conversion Workflow                   │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  @java-convert-plan            │
        │  (Analyze RPG, create detailed │
        │   Java architecture plan)      │
        └────────────────────────────────┘
                         │
                         ▼ (User approves)
        ┌────────────────────────────────┐
        │  @java-implement               │
        │  (TDD: Write test → Implement  │
        │   → Refactor)                  │
        └────────────────────────────────┘
```

---

## 🎬 Demo Scenarios

### Scenario 1: Understanding the Legacy System (5 minutes)

**Goal:** Get familiar with the banking system's architecture and business logic.

**Steps:**

1. **Open Copilot Chat** (`Cmd+Shift+I`)
2. **Ask about the system:**
   ```
   @rpg-maintain-planning Please explain this legacy banking system. 
   What are the main components and business processes?
   ```
3. **Open** `rpgle-programs/CUSTPROC.RPGLE` and ask:
   ```
   @rpg-maintain-planning Explain the customer creation process and validations in this file.
   ```
4. **Open** `dds-files/CUSTMAST.PF` and ask:
   ```
   @rpg-maintain-planning Explain this customer master file structure and key fields.
   ```

**What You'll Learn:**
- Banking system architecture and data flow
- RPG programming patterns and conventions
- Database structure and relationships
- Audit trail and compliance requirements

---

### Scenario 2: Add RPG Feature with Planning (15 minutes)

**Goal:** Add phone number validation to customer creation using safe planning workflow.

**Steps:**

1. **Open** `rpgle-programs/CUSTPROC.RPGLE`
2. **Activate planning agent:** `@rpg-maintain-planning`
3. **Use the prompt:**
   ```
   /add-rpg-feature
   
   Add phone number validation to CreateCustomer procedure.
   
   Requirements:
   - Phone format: (###) ###-####
   - Validate before writing customer record
   - Return error code E0005 if invalid
   - Follow existing email validation pattern
   ```
4. **Review the plan** (The agent will analyze the code and create detailed plan)
5. **Approve:** `The plan looks good. Please hand off to implementation.`
6. **Implementation:** Agent switches to `@rpg-implement` and generates code

**What You'll Get:**
- Detailed implementation plan with code locations
- New `ValidatePhone` procedure with proper RPG syntax
- Error handling with commitment control
- Audit trail updates
- Integration into existing `CreateCustomer` procedure

---

### Scenario 3: Convert RPG to Java (30 minutes)

**Goal:** Convert `CUSTPROC.RPGLE` to Java Spring Boot with full architecture using a two-phase approach: planning first, then implementation.

#### Part 1: Planning Phase with @java-convert-plan (15 min)

1. **Start new chat** and select `@java-convert-plan`
2. **Use the conversion prompt:**
   ```
   /convert-to-java
   
   Program: CUSTPROC.RPGLE
   
   This program handles:
   - Create customer with SSN validation
   - Retrieve by ID and SSN
   - Update customer information
   - Credit score integration
   - Full audit trail
   
   Create comprehensive conversion plan.
   ```
3. **Planning agent automatically:**
   - Analyzes RPG code structure and business logic
   - Reads related files (CUSTMAST.PF, CREDSCOR.RPGLE)
   - Documents all procedures and data structures
   - Creates detailed architectural plan with:
     - Complete JPA entity design with relationships
     - Repository interfaces with custom queries
     - Service layer design preserving business logic
     - PostgreSQL schema with Flyway migration
     - Comprehensive test strategy (90%+ coverage)
     - Complete RPG↔Java↔PostgreSQL data mappings
     - Step-by-step implementation tasks

4. **Review the plan carefully:**
   - Verify entity relationships match RPG file structures
   - Check business logic preservation (SSN validation, audit trails)
   - Confirm test coverage includes all edge cases
   - Validate PostgreSQL schema matches DB2 structure

5. **Approve plan:** `The plan looks good. Please hand off to implementation.`

#### Part 2: Implementation Phase with @java-implement (15 min)

6. **Accept handoff** - Planning agent offers to switch to `@java-implement`
7. **Implementation agent begins TDD workflow:**
   
   **First Iteration:**
   - **Red:** Writes failing test for customer creation
   - **Green:** Implements minimal `CustomerService.createCustomer()`
   - **Refactor:** Improves code structure while tests pass
   
8. **Continue iterations:** `Add test for duplicate SSN validation`
9. **Implementation agent repeats** Red-Green-Refactor for each feature:
   - Duplicate SSN exception handling
   - Customer retrieval by ID
   - Customer update with audit trail
   - Integration tests with Testcontainers

10. **Final validation:** `Run all tests and verify 90%+ coverage`

**What You'll Get After Planning:**
- Detailed architectural blueprint
- Entity-relationship documentation
- Database migration scripts
- Complete test strategy
- Implementation task checklist

**What You'll Get After Implementation:**
- Complete Spring Boot application
- JPA entities with proper annotations
- Spring Data JPA repositories
- Service layer with preserved business logic
- 90%+ test coverage (unit + integration)
- Working Flyway database migration
- Full RPG behavior parity validation

---

### Scenario 4: Quick Reference Lookups (30 seconds)

**Goal:** Get instant RPG↔Java conversion references.

**Steps:**

1. **In any chat, type:**
   ```
   /rpg-to-java-mapping
   ```

**What You'll Get:**
```
📖 RPG to Java Quick Reference

File Operations:
  RPG: CHAIN pId CUSTMAST           → Java: customerRepository.findById(id)
  RPG: IF %FOUND(CUSTMAST)          → Java: optional.isPresent()
  RPG: UPDATE CUSTMASTR             → Java: repository.save(entity)
  RPG: WRITE CUSTMASTR              → Java: repository.save(entity)

Data Types:
  RPG: 10A                          → Java: String @Size(max=10)
  RPG: 9S 0                         → Java: Integer
  RPG: 15P 2                        → Java: BigDecimal(15,2)
  RPG: 8S 0 (date: YYYYMMDD)        → Java: LocalDate
  RPG: 6S 0 (time: HHMMSS)          → Java: LocalTime

Transactions:
  RPG: COMMIT                       → Java: @Transactional completes
  RPG: ROLLBACK                     → Java: @Transactional throws exception

Built-in Functions:
  RPG: %TRIM(field)                 → Java: field.trim()
  RPG: %FOUND(file)                 → Java: optional.isPresent()
  RPG: %ERROR()                     → Java: try-catch blocks
  RPG: %USER                        → Java: @CreatedBy auditing
```

---

### Scenario 5: Convert Batch Processing (20 minutes)

**Goal:** Convert `EODPROC.CLLE` to Spring Batch.

**Steps:**

1. **Select** `@java-convert-plan`
2. **Prompt:**
   ```
   /convert-to-java
   
   Program: EODPROC.CLLE (End-of-Day batch)
   
   This orchestrates:
   - Database backups
   - Interest calculation (CALCINT)
   - Statement generation (GENSTMT)
   - Credit score updates (BATCHSCR)
   - Daily reports (RPTDAILY)
   
   Convert to Spring Batch 5.x with job orchestration.
   ```
3. **Review plan** for job steps, error handling, restart capabilities
4. **Approve and implement** using `@java-implement`

**What You'll Get:**
- Spring Batch job configuration
- Individual step implementations
- Job scheduling with Quartz
- Error handling and restart logic
- Monitoring and logging

---

## ✅ Validate Your Setup (2 minutes)

Run these quick tests to ensure everything works:

### Test 1: Agents Available
```
1. Open Copilot Chat
2. Type @ and verify you see:
   - @rpg-maintain-planning
   - @rpg-implement
   - @java-convert-plan
   - @java-implement
```
✅ **Pass:** All 4 agents appear in dropdown

### Test 2: Prompts Available
```
1. In Copilot Chat, type /
2. Verify you see:
   - /add-rpg-feature
   - /convert-to-java
   - /rpg-to-java-mapping
```
✅ **Pass:** All 3 prompts appear

### Test 3: Context Loading
```
1. Ask: @rpg-maintain-planning "What is commitment control in RPG?"
2. Verify response mentions:
   - COMMIT keyword
   - Transaction rollback
   - File specifications with COMMIT flag
```
✅ **Pass:** Agent understands RPG-specific concepts from context

### Test 4: File Analysis
```
1. Open rpgle-programs/CUSTPROC.RPGLE
2. Ask: @rpg-maintain-planning "Summarize this program's main procedures"
3. Verify response lists:
   - CreateCustomer
   - GetCustomerById
   - UpdateCustomer
   - ValidateSSN/ValidateEmail
```
✅ **Pass:** Agent can read and analyze RPG code

**All tests pass?** 🎉 You're ready to start!
**Some tests fail?** See Troubleshooting section below.

---

## 📊 What You'll Achieve

### Development Velocity
- ⚡ **3-5x faster** RPG to Java conversions
- 🎯 **90%+ test coverage** automatically generated
- 📖 **Complete documentation** with every conversion

### Code Quality
- 🔒 **100% business logic preservation** verified by tests
- 🏗️ **Modern architecture** following Spring Boot best practices
- 📋 **Full audit trails** maintained from legacy system
- ✨ **Production-ready code** with error handling and validation

### Team Benefits
- 📚 **Knowledge capture** in detailed conversion plans
- 🚀 **Faster onboarding** for new developers
- ✅ **Consistent quality** across all conversions
- 🔍 **Clear migration path** for stakeholders

---

## 🔧 Project Structure Reference

```
Legacy-RPG-Banking-System/
├── .github/
│   ├── copilot-instructions.md                    # Auto-loaded context for all agents
│   ├── 01-rpg-maintenance-plan-template.md        # Template for RPG plans
│   ├── 02-java-conversion-plan-template.md        # Template for Java conversions
│   ├── agents/                                    # Specialized AI agents (use @ to call)
│   │   ├── 01-rpg-maintain-planning.agent.md     # Step 1: Plan RPG changes
│   │   ├── 02-rpg-implement.agent.md             # Step 2: Implement RPG features
│   │   ├── 03-java-convert-plan.agent.md         # Step 3: Plan Java conversions
│   │   └── 04-java-implement.agent.md            # Step 4: Implement Java with TDD
│   └── prompts/                                   # Reusable templates (use / to call)
│       ├── 01-add-rpg-feature.prompt.md          # Add RPG features safely
│       ├── 02-convert-to-java.prompt.md          # Convert RPG→Java
│       └── 03-rpg-to-java-mapping.prompt.md      # Quick reference
├── rpgle-programs/                                # Legacy RPG source code
│   ├── CUSTPROC.RPGLE                  # Customer management
│   ├── POSTTRAN.RPGLE                  # Transaction processing
│   └── CREDSCOR.RPGLE                  # Credit scoring algorithm
├── dds-files/                           # DB2 database definitions
│   ├── CUSTMAST.PF                     # Customer master file
│   ├── ACCTMAST.PF                     # Account master file
│   └── TRANLOG.PF                      # Transaction log
├── cl-programs/
│   └── EODPROC.CLLE                    # End-of-day batch orchestration
├── sql-scripts/
│   └── create-tables.sql               # PostgreSQL schema
├── PRODUCT.md                          # Business requirements
├── ARCHITECTURE.md                     # System architecture
├── CONTRIBUTING.md                     # Development guidelines
└── RPG-CONVENTIONS.md                  # RPG coding standards
```

---

## 🆘 Troubleshooting

### Problem: Agents don't appear when typing @

**Possible Causes:**
- GitHub Copilot Chat not enabled
- VS Code needs restart
- Agent files not properly formatted

**Solutions:**
1. Verify GitHub Copilot Chat is active (status bar icon)
2. Restart VS Code: `Cmd+Q` and reopen
3. Check `.github/agents/*.agent.md` files exist
4. Ensure agent files have proper markdown structure

### Problem: Prompts don't appear when typing /

**Possible Causes:**
- Prompt files missing or misnamed
- Wrong directory structure

**Solutions:**
1. Verify `.github/prompts/*.prompt.md` files exist
2. Check filenames end with `.prompt.md`
3. Restart VS Code
4. Try typing full prompt path: `/add-rpg-feature`

### Problem: Agent doesn't understand RPG code

**Possible Causes:**
- Context not loading properly
- Documentation files missing

**Solutions:**
1. Verify `.github/copilot-instructions.md` exists
3. Check `RPG-CONVENTIONS.md` is accessible
3. Open the RPG file first, then ask questions
4. Use `@rpg-maintain-planning` for analyzing RPG code

### Problem: Conversion plans are too generic

**Possible Causes:**
- Insufficient detail in prompt
- Agent not reading related files

**Solutions:**
1. Provide more specific requirements in prompt
2. Mention specific RPG procedures to convert
3. Reference business rules from PRODUCT.md
4. Ask agent to explain its analysis first

### Problem: Test coverage lower than expected

**Possible Causes:**
- Implementation agent not following TDD strictly
- Missing edge cases in requirements

**Solutions:**
1. Explicitly request: "Add tests for edge cases: null values, empty strings, boundary conditions"
2. Review plan phase for missing test scenarios
3. Ask: "What additional tests should we add for complete coverage?"

---

## 💡 Pro Tips

1. **Start with planning:** Use `@rpg-maintain-planning` to analyze code and create detailed plans
2. **Always review plans:** Don't skip the planning phase - it catches issues early
3. **Be specific:** The more details you provide, the better the output
4. **Iterate incrementally:** Convert small programs first, then tackle complex ones
5. **Validate business logic:** Always test converted code against original RPG behavior
6. **Use quick reference:** Keep `/rpg-to-java-mapping` handy during conversions

---

## 📚 Learn More

### Core Documentation
- **`PRODUCT.md`** - Business requirements, features, user roles, KPIs
- **`ARCHITECTURE.md`** - System design, data models, technology stack
- **`CONTRIBUTING.md`** - Development workflow, testing standards, code review
- **`RPG-CONVENTIONS.md`** - RPG syntax, patterns, built-in functions, best practices

### External Resources
- [VS Code Copilot Docs](https://code.visualstudio.com/docs/copilot/overview)
- [Context Engineering Guide](https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide)
- [Spring Boot 3.x Docs](https://docs.spring.io/spring-boot/reference/)
- [Spring Batch 5.x Docs](https://docs.spring.io/spring-batch/reference/)
- [PostgreSQL 16 Docs](https://www.postgresql.org/docs/16/)

---

## 🎓 Next Steps

1. **Complete all validation tests** to ensure setup works
2. **Run Scenario 1** to understand the banking system
3. **Try Scenario 2** to practice RPG maintenance workflow
4. **Attempt Scenario 3** for your first conversion
5. **Customize for your needs** - adapt agents and prompts for your legacy system

---

## 🤝 Customization Guide

### Add Your Own Agent

Create `.github/agents/my-agent.agent.md`:
```markdown
# Agent Name: my-agent

## Description
[Your agent's purpose]

## Core Principles
- Principle 1
- Principle 2

## Workflow
1. Step 1
2. Step 2

## Available Tools & Commands
- Tool 1: Purpose
- Tool 2: Purpose
```

### Add Your Own Prompt

Create `.github/prompts/my-prompt.prompt.md`:
```markdown
# Slash Command: /my-prompt

## Description
[What this prompt does]

## Usage Example
```
/my-prompt [parameters]
```

## Instructions for AI
[Detailed instructions for the AI assistant]
```

### Adapt for Your Legacy System

1. **Update business context:** Modify `PRODUCT.md` with your domain knowledge
2. **Document your architecture:** Update `ARCHITECTURE.md` with your system design
3. **Add language conventions:** Create conventions guide for your legacy language
4. **Customize agents:** Modify agent instructions for your technology stack
5. **Create domain prompts:** Add prompts specific to your conversion patterns

---

**🚀 Ready to modernize your legacy system? Start with Scenario 1!**