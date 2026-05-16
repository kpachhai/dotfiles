---
name: review-pr
description: Use WHEN reviewing a pull request and the user wants a structured second opinion focused on correctness, security, maintainability - not an automated linter pass and not a full architectural review. Triggers on "review this PR", "/review-pr <num>", "check my changes", "look over this PR before I merge". Produces a structured findings doc (correctness / security / maintainability / questions). Skip when CodeRabbit has already run and the user wants a different perspective - invoke `coderabbit:code-review` instead for first-pass automated review.
user-invocable: true
---

# Pull Request Review Skill

## Purpose

Perform a thorough code review of a pull request. Analyze all changes, check for correctness, security, maintainability, and provide structured feedback.

## Process

### Step 1: Gather PR Context

```bash
# If argument is a URL, extract the PR number
# If argument is a number, use it directly
gh pr view $ARGUMENTS --json title,body,additions,deletions,files,baseRefName,headRefName,author
gh pr diff $ARGUMENTS
```

### Step 2: Analyze Changes

For each changed file:
1. Read the full file for context (not just the diff)
2. Understand the purpose of the change
3. Check for issues against the review checklist

### Step 3: Review Checklist

**Correctness**
- Does the code do what the PR description says?
- Are edge cases handled?
- Are error paths covered?

**Security**
- Input validation at boundaries?
- Auth/authz checks?
- No secrets or credentials?
- SQL injection, XSS, command injection?

**Maintainability**
- Is the code clear and readable?
- Are names descriptive?
- Is there unnecessary complexity?
- Are there tests for new behavior?

**Performance**
- N+1 queries?
- Unnecessary allocations?
- Missing pagination on lists?

### Step 4: Output Review

Format:

```markdown
## PR Review: <title>

**Summary**: <1-2 sentence summary of what this PR does>
**Risk Level**: Low / Medium / High

### Blockers (Must Fix)
- [file:line] Description and why

### Suggestions (Should Fix)
- [file:line] Description and why

### Nits (Nice to Have)
- [file:line] Description

### What's Good
- Positive observations about the code

### Questions
- Things that aren't clear from the diff alone
```
