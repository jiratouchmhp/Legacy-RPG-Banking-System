---
agent: java-convert-plan
description: Create a detailed plan for converting an RPG program to Java Spring Boot
---

# Convert RPG Program to Java

I need to convert an RPG program to Java 21 with Spring Boot 3.x and PostgreSQL.

**Program to convert:** [Specify the RPG program name, e.g., CUSTPROC.RPGLE]

**Use the planning workflow:**
1. Analyze the RPG program thoroughly using #runSubagent
   - Read complete source code
   - Document all procedures and business logic
   - Identify data structures and database operations
   - Note transaction boundaries and error handling
   
2. Create a comprehensive conversion plan using the [plan-template](../plan-template.md) that includes:
   - **Entity design:** Map RPG data structures to JPA entities with relationships
   - **Service layer:** Convert RPG procedures to service methods preserving business logic
   - **Repository layer:** Spring Data JPA repository interfaces
   - **Database schema:** PostgreSQL DDL with constraints, indexes, Flyway migration
   - **Business logic preservation:** Document how each RPG procedure maps to Java
   - **Testing strategy:** Unit tests (90%+ coverage) and integration tests with Testcontainers
   - **Tasks breakdown:** Step-by-step implementation checklist
   - **Open questions:** Any clarifications needed

3. Use these technology choices:
   - **Java 21** with modern features (records, pattern matching, virtual threads)
   - **Spring Boot 3.x** (latest stable)
   - **PostgreSQL 16+** with proper schema design
   - **Testing:** JUnit 5, Mockito, AssertJ, Testcontainers
   - **Migrations:** Flyway for versioned database migrations

4. Ensure business logic parity:
   - Credit scoring algorithm must produce identical results
   - Transaction processing must maintain ACID compliance
   - Audit trail must capture all required information
   - Error codes must match RPG error codes for compatibility

5. After creating the plan, wait for my approval before offering handoff to the implementation mode.

**Additional context (if any):**
[Provide any specific requirements, constraints, or questions]
