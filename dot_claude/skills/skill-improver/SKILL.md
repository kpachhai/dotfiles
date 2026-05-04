---
name: skill-improver
description: Detects when something reusable was learned during a work session and extracts it into a skill update or new skill. Triggers on investigation > 10 min, workaround found, misleading error fixed, configuration diverged from docs. Inspired by OB1's claudeception pattern.
---

# Skill Improver

## Purpose

Extract reusable knowledge from work sessions into skill improvements or new skills. This is the "learning from doing" complement to learn-and-improve (which learns from external articles).

**This is a global skill** - it works across any project.

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

## When NOT to Capture

Skip this skill when:

- The learning was a one-off solution unlikely to recur (specific bug in throwaway code)
- The pattern is already well-documented in vendor docs, project README, or existing skill
- The "learning" is just rediscovering something the user already knows (won't add value)
- The user has explicitly said "don't save this" or signaled the topic is sensitive
- The learning is project-specific in a way that won't generalize (e.g., specific file path coincidence)
- A duplicate Open Brain capture already exists at >0.8 similarity (covered by Step 2 dedup, but worth naming as a stop-condition)

If unsure, default to capturing. Cost of an extra Open Brain entry is low; cost of a re-investigation later is high.

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

### Step 2.5: Enterprise / Work-Context Lens (Mandatory)

Before classifying the improvement, run a second-pass check: **does this learning apply to the user's client/enterprise work, not just the immediate project?**

The user is a Solutions Architect working across multiple clients and enterprise customers. Many session learnings (debugging patterns, integration approaches, AI-tooling workarounds, MCP design quirks) apply to client work even if the immediate session was personal. Don't bias capture toward "this only matters for the current project."

Check:
- **Client/enterprise transfer:** Could this pattern help in a different client/enterprise context with similar tech?
- **Architecture-decision input:** Does this learning inform architecture choices the user makes at work even if no code ships?
- **Developer-advocacy material:** Is this worth a blog post, talk, or demo for community or enterprise audiences?

If yes, scope the captured artifact (skill, rule, lesson) to be generic - phrase it in terms of roles and patterns, not the specific project context. A skill captured from a personal-project session with a generic rule serves both personal and enterprise contexts.

The discipline: skill-improver captures should default to generic-and-portable, not project-specific-and-narrow. If the rule only applies to one project, that's fine - just be sure that's the actual scope, not lazy bounding.

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

For **new skills**, follow the Skill Authoring Blueprint below. A starter template lives at `~/.claude/skills/skill-improver/template-SKILL.md` - copy it as the starting point.

## Skill Authoring Blueprint

This blueprint consolidates patterns learned from authoring 15+ skills across multiple repos. Apply every rule when creating a new skill or substantially editing an existing one.

### Frontmatter Discipline

```yaml
---
name: <skill-name-with-hyphens>
description: <single line - leads with "Use when..." trigger phrase + artifact produced + output shape>
---
```

**Description rules (80% of skill quality):**

1. **Single line ONLY.** No formatter line-breaks. If a code formatter wraps it, Claude reads only the first line.
2. **Lead with "Use when..."** trigger phrasing, not label-style openings ("Multi-sub-agent planning skill..." → wrong; "Use BEFORE writing code on..." → right).
3. **Include real trigger phrases** users/agents would type ("ship it", "/deep-plan", "improve this project", etc.).
4. **Name the artifact type** the skill produces (versioned audit doc, structured eval, plan, etc.).
5. **State the output shape** concretely (markdown file at path X, inline structured response, etc.).
6. **Be pushy not vague.** Skills tend to UNDER-trigger by default. Make it confident enough to fire when the situation matches.
7. **80/20 attention rule.** Spend 80% of skill-writing effort on the description (which determines whether the skill ever fires). 20% on the body. Resist the temptation to write a long body before the description is dialed in.

### Body Discipline

**Length target:** 100-200 lines for the core SKILL.md. Heavy reference material goes in supporting files in the same skill folder.

**Required body sections (in order):**

1. **One-paragraph purpose** - what does the skill do, why does it exist as a separate artifact?
2. **`## When To Use`** - specific behavioral triggers, slash command, user phrases
3. **`## When NOT to Use` / `## Skip When` / `## When NOT to Capture`** - explicit edge cases. Don't assume "common sense"; write it down.
4. **Workflow / Process** - reasoning + frameworks, not just numbered steps. Encode the WHY along with the WHAT.
5. **`## Output Contract`** - for agent-callable skills, frame outputs as contracts (see below).
6. **`## Common Pitfalls`** or **`## Anti-Patterns`** - things that break, lessons from real usage.
7. **`## Source`** (if inspired by external content) - cite the source.
8. **`**Version:**` line at the bottom** - SemVer-style (1.0.0, 1.1.0, 2.0.0).

### Output Contract Pattern (for Agent-Callable Skills)

Replace generic "Output Format" sections with structured contracts:

```markdown
## Output Contract

The <artifact> is delivered <where: inline / file path / both>.

**Required sections (always present):**
- <section 1 name + brief description>
- <section 2>

**Optional sections (depends on...):**
- <section X> (only when <condition>)

**Out of scope (this skill does NOT produce):**
- <explicit non-deliverable 1>
- <explicit non-deliverable 2>

**Format guarantees:**
- <structural promise: markdown headers, table format, etc.>
- <invariants: every X has Y, no X without Z, etc.>

**Consumed by (downstream chain):**
- <what skill or workflow stage uses this output>
```

The contract semantics matter more than the exact wording - it tells downstream agents what they can rely on, what's optional, and what's NOT in scope. Without this, agents fail in handoffs (sycophantic confirmation on missing data, silent failure on assumed-but-absent fields).

### Authoring Process Discipline

- **Latent-space-trigger awareness:** the same instruction phrased differently produces different output qualities. Expect 3-4 wording iterations to dial in the right output for important skills. This is engineering work, not polish.
- **Eval gold standard:** would two independent reviewers reach the same pass/fail when comparing actual output to the skill's expectations? If unsure, sharpen the criteria.
- **Hardwired behavior uses scripts, not skills.** Skills are guidance. If something MUST happen exactly the same way every time (data validation, security check, side-effecting operation), use deterministic code, not natural-language skill text.
- **Examples are powerful but expensive.** One excellent example pattern-matches better than three mediocre ones. Put examples in supporting files (`example.md`, `template.md`) referenced from the main SKILL.md, not inline in the body.

### File Structure

```
~/.claude/skills/<skill-name>/
├── SKILL.md           # Required - main file with frontmatter + body
├── template.md        # Optional - if the skill produces a structured artifact
├── example.md         # Optional - one excellent example pattern-match target
└── reference.md       # Optional - heavy reference material the body cites
```

For project-local skills (e.g. inside a meta-stack repo): `<your-repo>/skills/<category>/<skill-name>/SKILL.md` with the same internal structure.

### Quality Gates Before Shipping a New Skill

Run through this checklist when authoring or substantially editing:

- [ ] Description is single line and leads with "Use when..."
- [ ] Description includes concrete trigger phrases
- [ ] Body has explicit `When NOT to Use` section
- [ ] Body has Output Contract section (if agent-callable)
- [ ] Body length is 100-200 lines for core SKILL.md
- [ ] Reasoning + frameworks present, not just steps
- [ ] Common Pitfalls / Anti-Patterns section present
- [ ] Source / inspiration cited if from external content
- [ ] Version line at bottom

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
