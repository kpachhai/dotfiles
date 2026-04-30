<!--
SKILL.md TEMPLATE - copy this as the starting point for a new skill.

Replace every <PLACEHOLDER> with real content. Delete every HTML comment
block when done. The structure here encodes patterns from skill-improver's
"Skill Authoring Blueprint" section - read that first.

Quality gates checklist (apply before shipping):
- [ ] Description is single line, leads with "Use when..."
- [ ] Description includes concrete trigger phrases
- [ ] Body has explicit "When NOT to Use" section
- [ ] Body has Output Contract section (if agent-callable)
- [ ] Body length is 100-200 lines for core SKILL.md
- [ ] Reasoning + frameworks present, not just steps
- [ ] Common Pitfalls / Anti-Patterns section present
- [ ] Source / inspiration cited if from external content
- [ ] Version line at bottom
-->

---
name: <skill-name-with-hyphens>
description: Use when <specific trigger conditions and symptoms>. <Brief restatement of artifact type produced and output shape>. <One-sentence differentiator from related skills>. Triggered by <real user phrases or slash command>.
---

<!--
Description rules (80% of skill quality - get these right before writing the body):

1. SINGLE LINE only. No formatter line-breaks. If wrapped, Claude reads only the first line.
2. LEAD WITH "Use when..." - never with a label. Not: "Multi-sub-agent planning skill...". Yes: "Use BEFORE writing code on...".
3. Include real trigger phrases users/agents would type ("ship it", "/deep-plan", "improve this project").
4. Name the artifact type produced (versioned doc, structured eval, plan, checklist).
5. State output shape concretely (markdown file at path, inline response, JSON structure).
6. Be pushy not vague. Skills under-trigger by default; make it confident.
7. Spend 80% of skill-writing effort on this description.
-->

# <Skill Name>

<One-paragraph purpose statement. What does this skill do? Why does it exist as a separate artifact rather than living in another skill? What's the differentiator from adjacent skills?>

**This is a global skill** - it works across any project.
<!-- DELETE the line above if this is project-scoped (your-meta-repo) instead of global -->

## When To Use

<Specific behavioral triggers - what user phrases or session signals invoke this?>

- <trigger condition 1>
- <trigger condition 2>
- The user explicitly invokes `/<skill-name>`
- <session-state signal that warrants automatic invocation, if any>

## When NOT to Use

<Explicit edge cases. Don't assume "common sense" - write the skip-conditions down.>

- <skip condition 1 - typical "this is too small" case>
- <skip condition 2 - "this is the wrong tool for X"
- <skip condition 3 - "user has already done X" or "context already provides Y"
- The user has explicitly said "don't run this"

## Workflow / Process

<Reasoning + frameworks, not just numbered steps. Encode the WHY along with the WHAT.>

### Step 1: <name>

<details - include reasoning, not just instructions. What does the agent need to think about, not just do?>

### Step 2: <name>

<details>

### Step 3: <name>

<details>

## Output Contract

<For agent-callable skills, frame outputs as contracts. Skip this section for purely human-interactive skills with no structured downstream consumer.>

The <artifact> is delivered <where: inline in conversation / saved to file path / both>.

**Required sections (always present):**
- <section 1 name + brief description>
- <section 2 name + description>
- <section 3 name + description>

**Optional sections (depends on...):**
- <section X> (only when <condition>)
- <section Y> (only when <condition>)

**Out of scope (this skill does NOT produce):**
- <explicit non-deliverable 1 - what consumers should NOT expect>
- <explicit non-deliverable 2>
- <explicit non-deliverable 3>

**Format guarantees:**
- <structural promise: markdown headers, table format, file naming, etc.>
- <invariants: every X has Y, no X without Z>
- <ordering or dependency guarantees>

**Consumed by (downstream chain):**
- <what skill, workflow stage, or human role uses this output>
- <if part of a chain: pointer to next skill in sequence>

## Common Pitfalls

<Things that break with this skill. Lessons learned from real usage. This grows over time as you discover failure modes.>

- **<failure mode 1>:** <what happens, how to spot it, fix>
- **<failure mode 2>:** <what happens, how to spot it, fix>
- **<failure mode 3>:** <what happens, how to spot it, fix>

## Source

<If the skill was inspired by an external source - blog post, video, repo, paper - cite it. If it emerged from internal session work, point to the relevant `workspace/your-meta-repo-meta/` audit doc.>

Inspired by <source>. See <reference path or URL>.

## Version

1.0.0
