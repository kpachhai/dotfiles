---
name: debug
description: Systematic debugging workflow - reproduce, isolate, trace, root-cause, and suggest a fix. Usage - /debug <error-description-or-file>
user-invocable: true
---

# Debug Skill

## Purpose

Systematically debug an issue by following evidence to the root cause. No guessing - follow the data.

## Process

### Step 1: Understand the Problem

Ask if not provided:
- What's the error message or unexpected behavior?
- When did it start? What changed recently?
- Is it reproducible? Under what conditions?

### Step 2: Gather Evidence

1. **Read the error** - Parse the full stack trace or error output
2. **Find the code** - Locate the exact file and function where the error originates
3. **Check recent changes** - `git log --oneline -20` on affected files
4. **Read surrounding context** - Understand what the code is supposed to do

### Step 3: Form Hypotheses

Based on the evidence, list 2-3 most likely causes. Rank by probability.

Common patterns to check:
- Null/undefined access
- Off-by-one errors
- Race conditions
- Type mismatches
- Missing error handling
- Configuration/environment differences
- Dependency version changes

### Step 4: Verify

For each hypothesis (starting with most likely):
1. Find evidence that confirms or eliminates it
2. If confirmed, trace the full chain from cause to symptom
3. If eliminated, move to next hypothesis

### Step 5: Report

```markdown
## Bug Report

**Symptom**: What the user sees
**Root Cause**: The actual bug and why it happens
**Location**: file:line
**Evidence**: How I traced it
**Suggested Fix**: Specific code change needed
**Risk**: What else might be affected
**Prevention**: How to prevent similar bugs
```
