---
name: skill-improver
description: Detects when something reusable was learned during a work session and extracts it into a skill update or new skill. Triggers on investigation > 10 min, workaround found, misleading error fixed, configuration diverged from docs. Inspired by OB1's claudeception pattern.
---

# Skill Improver

## Purpose

Extract reusable knowledge from work sessions into skill improvements or new skills. This is the "learning from doing" complement to learn-and-improve (which learns from external articles).

**This is a global skill** - it works across any project, not just your-meta-repo.

## When To Use

### Automatic Trigger Detection

Watch for these signals during any work session:

1. **Investigation exceeded 10 minutes** beyond what documentation covers
2. **Error message was misleading** - the actual fix was different from what the error suggested
3. **Workaround required experimentation** - multiple approaches tried before success
4. **Configuration diverged from standard patterns** - what works differs from what docs say
5. **A pattern was used 3+ times** in the same session - it should be a reusable rule

### Manual Triggers

- User says "save this as a skill", "remember this pattern", "we should update our skills"
- User invokes `/skill-improver`
- End of a session where significant debugging or problem-solving occurred

## Process

### Step 1: Identify What Was Learned

Ask: "What specific knowledge would have saved us time if we'd had it at the start?"

Extract:
- **The problem** - what went wrong or what was needed
- **The solution** - what actually worked (not what should have worked)
- **Why it's non-obvious** - what makes this worth capturing (if it's obvious from docs, skip it)

### Step 2: Check for Duplicates

Before creating anything new:

0. **Check Open Brain (if available)** - Two conditions:
   - **If `search_thoughts` MCP tool is NOT available:** skip this check entirely and silently. Move to step 1.
   - **If `search_thoughts` IS available:** search for the pattern using a concise description as the query. If a result returns with similarity > 0.8, show it to the user and ask: "This pattern was previously captured in Open Brain. Should I update the existing thought, or create a new skill entry?"
1. **Check existing project skills** - does a skill in this repo already cover this?
2. **Check global skills** - does `~/.claude/skills/` already have this?
3. **Check CLAUDE.md** - is this already documented as a rule?

If an existing skill partially covers it, **update that skill** instead of creating a new one.

### Step 3: Classify the Improvement

| Type | Where It Goes | Example |
|------|--------------|---------|
| **Project-specific pattern** | Project CLAUDE.md or project skill | "Mermaid \\n doesn't render in Notion" |
| **Tool/framework pattern** | `~/.claude/skills/<tool>/SKILL.md` | "Chezmoi requires re-add after local edits" |
| **Workflow pattern** | Global CLAUDE.md or existing global skill | "Always use -S -s for git commits" |
| **New reusable skill** | `~/.claude/skills/<name>/SKILL.md` | A complete new capability |

### Step 4: Structure the Output

For **skill updates** (most common):
```markdown
## Lessons Log Entry

| Date | What Happened | What Changed |
|------|--------------|-------------|
| <today> | <specific failure> | <rule/process updated> |
```

For **new skills**, follow the standard SKILL.md format:
```yaml
---
name: <name>
description: <trigger conditions and purpose>
---
```

### Step 5: Quality Gates

Before saving, verify:

- [ ] **Reusable** - applies to future work (not a one-off fix)
- [ ] **Non-trivial** - not a 1-line fix or something obvious from docs
- [ ] **Specific** - includes exact steps, not vague advice
- [ ] **Verified** - the solution actually worked (not theoretical)
- [ ] **Not a duplicate** - checked existing skills and CLAUDE.md

If any gate fails, do not save. Mention the learning to the user but explain why it doesn't warrant a skill update.

### Step 6: Save and Sync

1. Make the edit or create the file
2. If in the dotfiles repo: changes auto-sync via chezmoi pre-push hook
3. If in a project repo: note in memory that a global skill was updated
4. Inform the user what was saved and where

## Anti-Patterns

- **Over-extracting mundane solutions** - "npm install fixes missing deps" is not a skill
- **Creating vague descriptions** - "helps with debugging" tells the AI nothing about when to trigger
- **Documenting unverified approaches** - if you haven't confirmed it works, it's a hypothesis, not a skill
- **Duplicating official documentation** - link to docs instead
- **Accumulating skills you never use** - during periodic review, delete skills that haven't been triggered in 3+ months

## Configurable Behavior

This skill is opt-in. It does not run automatically. It can be invoked:
- Explicitly by the user (`/skill-improver` or "what did we learn?")
- As part of a session wrap-up (see `session-wrap` skill)
- When the user asks to update skills based on what happened

---

**Version:** 1.1.0
