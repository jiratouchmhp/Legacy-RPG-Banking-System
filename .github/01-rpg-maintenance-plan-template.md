---
title: [Short descriptive title of the RPG change]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
---

# RPG Maintenance Plan: [Change Description]

[Brief 1-2 sentence description of what's changing and why]

## Change Summary

**Affected Program(s):** [List RPG program names, e.g., CUSTPROC.RPGLE]

**Change Type:** [New Feature / Bug Fix / Enhancement / Refactoring]

**Business Justification:** [Why this change is needed from a business perspective]

**Complexity:** [Simple / Medium / Complex]

## Current State Analysis

### Affected Procedures
- **ProcedureName1:** Brief description of what it does
- **ProcedureName2:** Brief description of what it does

### Existing Validation Patterns
- **ValidateSSN:** SSN format validation (9 digits)
- **ValidateEmail:** Email format validation (contains @)
- [List other relevant validations]

### Current Error Codes
- **E0001:** Error description
- **E0002:** Error description
- **E0003:** Error description
- [List error codes currently in use]

### Data Structures
```rpg
D CurrentDS       DS                  QUALIFIED
D  Field1                       10A
D  Field2                        9S 0
D  Field3                       50A
```

### Transaction Boundaries
- **COMMIT points:** [Where transactions commit]
- **ROLLBACK points:** [Where transactions rollback]
- **File specs with COMMIT:** [List files with commitment control]

## Proposed Changes

### New/Modified Procedures

#### Procedure: [ProcedureName]

**Purpose:** [What this procedure does]

**Signature:**
```rpg
P ProcedureName   B                   EXPORT
D ProcedureName   PI             [ReturnType]
D  pParameter1                  [Type]   CONST
D  pParameter2                  [Type]   CONST OPTIONS(*NOPASS)
```

**Parameters:**
- `pParameter1`: Description of parameter 1 (input)
- `pParameter2`: Description of parameter 2 (optional input)

**Returns:** [Description of return value]

**Business Logic:**
1. Step 1: Description
2. Step 2: Description
3. Step 3: Description

**Validation Rules:**
- Rule 1: Specific validation requirement
- Rule 2: Specific validation requirement

**Error Handling:**
- Return *OFF / error code if [condition]
- Rollback transaction if [condition]

**Model After:** [Reference to similar existing procedure, if applicable]

### Data Structure Changes

[If adding/modifying fields in data structures]

**Structure:** [DataStructureName]

```rpg
D UpdatedDS       DS                  QUALIFIED
D  ExistingField1               10A
D  ExistingField2                9S 0
D  NewField                     50A   // NEW FIELD
D  ExistingField3               50A
```

**New Fields:**
- **NewField (50A):** Description of what this field stores

### DDS File Changes

[If database file definitions need updating]

**File:** [FileName].PF

```
     A            NEWFIELD      50A         COLHDG('New' 'Field')
     A                                      TEXT('Description of field')
```

### Integration Points

**Where to integrate new/modified code:**

1. **In CreateCustomer procedure (line ~XXX):**
   - Before: `[existing code]`
   - After: `[new code with call to new validation]`

2. **In ValidateCustomer procedure (line ~XXX):**
   - Before: `wValidation.ValidPhone = (pCustomer.Phone > 1000000000);`
   - After: `wValidation.ValidPhone = ValidatePhone(pCustomer.Phone);`

3. **Error handling in CreateCustomer (line ~XXX):**
   - Add new error check and return error code

### Error Code Management

**New Error Codes:**
- **E0005:** Invalid phone format - use (###) ###-####

**Error Code Conflicts:**
- E0005 was previously used for "Customer not found" in UpdateCustomer
- Solution: Change UpdateCustomer to use E0006 for "Customer not found"

### Audit Trail Updates

[If audit fields need special handling]

**Fields to Update:**
- `CRTDATE`, `CRTTIME`, `CRTUSER` - On INSERT operations
- `UPDDATE`, `UPDTIME`, `UPDUSER` - On UPDATE operations

**Approach:**
```rpg
// Get current date/time
wCurrentDate = %DEC(%CHAR(%DATE():*ISO):8:0);
wCurrentTime = %DEC(%CHAR(%TIME():*ISO):6:0);
wCurrentUser = %USER;

// Set appropriate audit fields
UPDDATE = wCurrentDate;
UPDTIME = wCurrentTime;
UPDUSER = wCurrentUser;
```

## Implementation Details

### Procedure Implementation

```rpg
      *===============================================================
      * [ProcedureName] - [Brief description]
      * [Detailed description of what this procedure does]
      * 
      * Parameters:
      *   pParameter1 - Description (input)
      *   pParameter2 - Description (input)
      * 
      * Returns: [Return type and description]
      * 
      * Error Codes: [List error codes this can return]
      *===============================================================
     P [ProcedureName] B
     D [ProcedureName] PI             [ReturnType]
     D  pParameter1                  [Type]   CONST
     D  pParameter2                  [Type]   CONST

     D wWorkVar1       S              [Type]
     D wWorkVar2       S              [Type]

      /FREE

       // Implementation steps with clear comments
       // Step 1: Validation
       IF [validation condition];
         RETURN [error value];
       ENDIF;

       // Step 2: Processing
       wWorkVar1 = [calculation];

       // Step 3: Return result
       RETURN [success value];

      /END-FREE
     P [ProcedureName] E
```

### Code Location

**File:** `/path/to/PROGRAM.RPGLE`

**Section:** [Where in the file to add/modify code]

**Line Numbers (approximate):** [XXX-YYY]

## Testing Strategy

### Test Scenarios

#### Happy Path Tests

| Test Case | Input | Expected Output | Expected Result |
|-----------|-------|----------------|-----------------|
| Valid input 1 | [Example data] | [Expected return value] | ✅ Success |
| Valid input 2 | [Example data] | [Expected return value] | ✅ Success |

#### Error Path Tests

| Test Case | Input | Expected Error Code | Expected Error Message |
|-----------|-------|--------------------|-----------------------|
| Invalid input 1 | [Example data] | E0005 | "Invalid phone format..." |
| Invalid input 2 | [Example data] | E0003 | "Invalid SSN format..." |

#### Edge Case Tests

| Test Case | Input | Expected Behavior |
|-----------|-------|-------------------|
| Boundary value 1 | [Example] | [Expected result] |
| Null/blank value | [Example] | [Expected result] |
| Maximum length | [Example] | [Expected result] |
| Special characters | [Example] | [Expected result] |

### Compilation Command

```
CRTBNDRPG PGM(BANKLIB/[PROGRAM]) SRCFILE(QRPGLESRC) SRCMBR([PROGRAM])
```

### Test Environment

**Library:** BANKDEV

**Test Files:** CUSTMAST (development copy)

**Test User:** DEVUSER

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation Strategy |
|------|--------|------------|---------------------|
| Breaking existing functionality | High | Low | Test in development environment, verify existing procedures still work |
| Error code conflict | Medium | Low | Review all existing error codes before assigning new ones |
| Performance degradation | Low | Low | Validation is fast, minimal impact on response time |
| Data corruption | High | Very Low | Proper error handling and rollback on failures |
| Incomplete error handling | Medium | Low | Test all error paths, ensure ROLLBACK on any error |

## Open Questions

1. [Question about requirement or business rule that needs clarification]
2. [Question about implementation approach or design decision]
3. [Question about testing requirements or acceptance criteria]

## Dependencies

**Programs that call this program:** [List programs that might be affected]

**Programs this program calls:** [List called programs/procedures]

**Database files:** [List DB files that will be modified]

## Rollback Plan

If implementation causes issues:

1. **Immediate rollback:** Restore previous version of [PROGRAM].RPGLE from source control
2. **Recompile:** `CRTBNDRPG PGM(BANKLIB/[PROGRAM]) SRCFILE(QRPGLESRC) SRCMBR([PROGRAM])`
3. **Verify:** Run test suite to ensure rollback successful
4. **Document:** Log the issue and rollback in change management system

## Success Criteria

Implementation is complete when:

- [ ] All procedure prototypes added correctly
- [ ] All procedures implemented with proper signatures
- [ ] Integration points updated as planned
- [ ] Error handling complete with proper COMMIT/ROLLBACK
- [ ] Audit trail updates implemented (if applicable)
- [ ] Code compiles without errors
- [ ] All test scenarios pass (happy path, error path, edge cases)
- [ ] Code review completed
- [ ] Documentation updated (procedure headers, inline comments)
- [ ] Follows all RPG conventions (free-format, naming, BIFs)
- [ ] No sensitive data in logs
- [ ] Change logged in version control

## Notes

[Any additional notes, considerations, or context that doesn't fit in other sections]
