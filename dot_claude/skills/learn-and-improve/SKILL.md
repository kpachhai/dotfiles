---
name: learn-and-improve
description: Use when the user shares an external article, blog post, video, GitHub repo, or other resource with improvement intent ("let's improve this project", "what can we learn from", "how does this apply to us"). Produces a versioned audit document in `<project>/.claude/audits/` mapping external patterns to specific changes in the current project's CLAUDE.md, skills, configs, or workflows.
---

# Learn and Improve (Global / Project-Scope)

Systematically learn from external sources and translate insights into concrete improvements for the **current project**. Produces a versioned audit artifact, not an ad-hoc summary.

**This is a global skill** - it works across any project. The audit target is whatever project the session is running in.

## Scope: Project-Improvement Mode

This skill improves the project the user is currently working in (`$CWD` or its git root). Audit targets:

- The project's `CLAUDE.md` (and any nested CLAUDE.md files)
- Skills under `.claude/skills/` if any
- Agents under `.claude/agents/` if any
- Hooks and settings under `.claude/`
- README, docs, project conventions
- Any reusable code patterns, scripts, or tools the project ships

**When NOT to use this skill - scope mismatch:**
- If the article is about YOUR_NAME's personal Claude workflow / dotfiles / Open Brain / cross-repo patterns AND the user is in `your-meta-repo`, defer to `your-meta-repo/skills/intake/learn-and-improve/SKILL.md` (the meta-stack version). That skill audits your-meta-repo + dotfiles + your-data-repo together.
- If the article is purely a reference share with no improvement intent, do not invoke this skill. Just discuss inline.

## When To Use

Strong triggers:
- User shares a URL with improvement language ("let's improve ourselves", "what should we adopt", "how does this apply to us")
- User shares a usage report or external analysis of their own behavior
- User wants a gap analysis between current state and a described approach
- User says "audit recent friction" or "what have we been getting wrong?" → Phase 0 friction mode

When NOT to use:
- Pure reference share without improvement intent
- Quick factual lookup that doesn't need formal extract-and-audit
- Change is < 10 lines and obviously local - just do it inline

## Workflow

```
Phase 0 (optional friction): Open Brain pull → Phase 1: Ingest → Phase 2: Extract → Phase 3: Audit → Phase 4: Recommend → Phase 5: Execute (optional)
```

The user can stop after any phase. Each phase appends to a single versioned doc.

### Phase 0: Friction Pull (Optional)

Run when the user invokes friction mode ("audit recent friction") or when articles are scarce and you want to drive improvement from real session data.

If the `capture_thought` / `search_thoughts` MCP is available:
1. Search Open Brain with query `[Friction]` (limit 15-25)
2. Optionally filter by recency (last 30-60 days) or topic
3. Cluster by theme: verification failures, factual/scope errors, UI/visual issues, workflow misuse, other
4. Treat each cluster as an Anti-Pattern for downstream phases. Cluster size = priority signal (5+ thoughts → high-priority).
5. If only friction is being audited (no external article), skip Phase 1-2 and go to Phase 3.

If MCP unavailable, skip silently.

### Phase 1: Ingest Sources

Accept URLs, file paths, pasted text, or topic references. For each source:

1. Fetch via the URL retrieval fallback chain (WebFetch → firecrawl → research agent → Chrome MCP). For YouTube specifically, try the `youtube-transcript` MCP first; if it returns "Video unavailable" that means transcript-unavailable not video-deleted - verify via Chrome MCP, then ask the user how to proceed if no captions exist.
2. Extract metadata: title, author, date, URL, type (engineering blog / docs / research / tutorial / opinion / case study).
3. Verify recency - flag sources older than 12 months.

For long sources (2000+ words) or PDFs: read summary first, only do full extraction if summary indicates value.

### Phase 2: Extract Patterns

For each source extract structured insights in 4 categories:

**Concepts:** High-level ideas. Format: name + 2-3 sentence summary + why it matters.

**Techniques:** Implementable approaches. Format: name + what + how + prerequisites + trade-offs.

**Anti-Patterns:** Things to stop / avoid. Format: name + problem + detection + fix.

**Architecture Decisions:** Structural choices. Format: name + pattern + when to use + when to avoid.

Rules:
- Be specific. "Use better prompts" is useless; "calibrate evaluator prompts with few-shot examples showing score breakdowns" is actionable.
- Preserve the source's reasoning - capture the WHY not just the WHAT.
- Flag contradictions between sources.
- Note model-specific caveats.

### Phase 2.5: Persist Patterns to Open Brain (Optional)

If `capture_thought` / `search_thoughts` MCP is available:

1. **Batch dedup (5+ patterns):** Collect all pattern names, run `search_thoughts` once per pattern using its most distinctive term (not full description). Skip any pattern with similarity > 0.8.
2. **Individual dedup (< 5 patterns):** `search_thoughts` per pattern with concise summary as query.
3. **Capture non-duplicates:** `[Pattern] <name>: <2-3 sentence description with when-to-use and trade-offs>. Source: <title and URL>`

Log captured thoughts in the output document under "Open Brain Captures".

If MCP unavailable, skip silently.

### Phase 3: Audit Current Project

For each extracted pattern, audit against the actual current state of the project:

1. **Read** the relevant project files - do not rely on memory or assumptions
2. Classify each gap:
   - **Missing** - pattern is completely absent
   - **Partial** - pattern exists but is incomplete or shallow
   - **Outdated** - pattern was relevant before but may now be overhead
   - **Conflicting** - pattern contradicts what the project explicitly does
   - **Already Done** - genuinely implemented, no action needed
3. Per non-"Already Done" gap: assess Impact (High/Medium/Low), Effort (High/Medium/Low), Risk (High/Medium/Low), and list affected files.

Discipline:
- Read before judging. Skills/configs evolve; your knowledge may be stale.
- Be honest about "Already Done." If partial, mark Partial.
- Consider cascading effects - changes that affect multiple downstream files.

### Phase 3.5: Enterprise / Work-Context Lens (Mandatory)

**Do not dismiss content purely because it doesn't fit the current project.** The user is a Solutions Architect working across multiple clients and enterprise customers. Many articles cover patterns that apply to internal tooling, day-job architecture decisions, or developer-advocacy content even when they don't fit the project being audited.

For every pattern extracted in Phase 2, run a second-pass enterprise audit:

- **Internal tooling fit:** Could this pattern improve internal tools the user builds for clients or enterprises? (e.g., MCP server design, agent-tool integration, AI-tooling rubrics)
- **Work-context architecture:** Does this pattern inform decisions the user makes at work even if no code ships in this project?
- **Developer-advocacy content opportunity:** Worth a blog post, talk, or demo for community or enterprise audiences?
- **New artifact opportunity:** Could a new skill, MCP, repo, or tool justify itself based on client/enterprise need?

When the enterprise lens surfaces opportunities, add them as first-class **"Enterprise / Work-Context"** recommendations in Phase 4 - equal priority to project-scope recs. Don't fold them into "Backlog" or "diminishing returns."

The discipline: project-scope and enterprise-scope are independent audit targets. Always run both before declaring no recommendations. Keep this section generic - do not name specific companies or product ecosystems; focus on roles (Solutions Architect, developer advocate) and responsibilities.

### Phase 3.6: Project / Demo Opportunity Lens (Mandatory)

External content is not just a source of skill improvements - it's also a source of **sample project ideas**. The user wants to constantly learn by building hands-on demos with new techniques, growing the your-meta-repo project portfolio, even if execution is parked for later. Identify these opportunities explicitly.

For every pattern extracted in Phase 2, ask:

1. **Could this seed a sample project?** Even small/throwaway. Hands-on building beats reading.
2. **Hands-on value:** Would building it give meaningful experience with the new technique that captures alone don't provide?
3. **Audience fit (both/and):** Evaluate the project against BOTH axes - never collapse to one:
   - **Client / enterprise architecture value:** Would the project demonstrate the technique usefully for the user's client/enterprise architecture work, internal tooling decisions, or knowledge-sharing with the teams the user supports (DevRel collaborators included, not the primary frame)?
   - **Personal project value:** Would the project be a fun / interesting / educational personal build the user would actually want to maintain - something that solves their own problem, scratches an itch, or extends their personal stack (your-meta-repo, dotfiles, Open Brain, blog, side ideas)?
   A project can be a strong fit on either axis OR both. The North Star and tutorial framing should reflect whichever fits - many project audiences are both/and rather than either/or. Do NOT exclude the personal-project angle when scoping unless the technique is genuinely client-only (e.g., a regulated-industry compliance pattern).
4. **your-meta-repo expansion:** Could the project become a reusable demo template or starter for future projects of this type?
5. **Skill gap check (critical):** Does your-meta-repo already have a builder/intake skill that would handle this project type?
   - **Yes, existing skill fits** → use existing skill when project executes
   - **No, but small extension to existing skill suffices** → flag the existing skill for extension when project executes (per balance-modify-vs-create rule)
   - **No, and a genuinely new skill is needed** → flag as skill gap. Decide whether to create skill now (if confidence is high project will execute soon) or park skill creation alongside the project (linked via Open Brain `[Parked]` thoughts)
   - When creating new skills, always apply the Skill Authoring Blueprint in `~/.claude/skills/skill-improver/SKILL.md`

When project opportunities surface, hand them off to `idea-refiner` to draft a project plan **in the same session if possible**. Even if execution is parked, the plan is the artifact - it sits in `workspace/<new-project-name>/` as a real project, not just a recommendation. Surface the project in Phase 4 under the new "Sample Project Opportunities" category.

The discipline: not every audit produces a project opportunity. News content (market analysis, strategic forecasts, supply-chain reports) typically won't. Technique-rich content (frameworks, tools, code patterns) often will. Honestly evaluate per-pattern and don't force project opportunities into news audits.

### Phase 4: Recommend Changes

For each gap:

```markdown
### Recommendation N: <Title>

**Priority:** P1 (do now) | P2 (do soon) | P3 (nice to have)
**Based on:** <pattern from Phase 2>
**Gap type:** <from Phase 3>
**Impact / Effort / Risk:** High|Medium|Low / Low|Medium|High / Low|Medium|High

**Current state:** <what the project does today, with file paths>
**Proposed change:** <exactly what to change, specific enough to implement without re-reading the source>
**Affected files:** <bulleted list>
**Implementation sketch:** <3-10 lines showing the shape of the change>
**Risks and mitigations:** <list>
```

Sort by Impact desc → Effort asc → Risk asc.

Group recommendations:
- **Quick Wins** (P1, Low effort) - do this conversation
- **Projects** (P1-P2, Medium-High effort) - separate conversation/branch (skill development efforts, not your-meta-repo sample projects)
- **Sample Project Opportunities** - your-meta-repo sample/demo projects to plan via `idea-refiner` from Phase 3.6 lens. Each entry names: project description, hands-on value, **skill situation** (existing skill X works / extends existing skill Y / new skill Z needed), trigger to execute (or "execute now" if quick). Plan goes in `workspace/<new-project-name>/` as a real project plan even if execution is parked. If a new skill is needed, decide create-now vs park-with-project per balance-modify-vs-create rule.
- **Backlog** (P3) - revisit later. **For every parked recommendation, also capture a `[Parked]` thought to Open Brain** with the recommendation summary, an explicit trigger condition for when to unpark, and a reference to this audit doc. Future Open Brain semantic search will surface the parked item when work matching the trigger arises. Audit docs in `<project>/.claude/audits/` are not always indexed by other tools, so Open Brain is the durable surfacing path. Format: `[Parked] <summary>. Trigger to unpark: <specific condition>. Source: <audit doc path> Rec <id>.`

After individual recommendations, identify Cross-Cutting Themes that span multiple recommendations.

Recommendation rules:
- Every recommendation must reference a specific file path.
- Prefer modifying existing artifacts when the change fits within an existing artifact's purpose. Create new artifacts when the new responsibility genuinely doesn't fit. Apply timing discipline: don't create speculatively, but don't avoid creation when it's justified.
- Be honest about diminishing returns - not every article applies.

### Phase 5: Execute (Optional)

If user approves recommendations:

1. Ask which to implement (don't assume all are approved)
2. Implement in priority order, P1 quick wins first
3. Per change: Read → Edit → verify internal consistency → note what changed
4. After all changes: consistency check (cross-references still resolve, version numbers updated)
5. **Mark superseded Friction** (if Phase 0 ran AND skills changed): for each Friction cluster that drove a change, capture `[Resolution] <skill> updated <date> to address <theme>: <one-sentence summary>`. If `add_edge` MCP is exposed, insert `supersedes` edges from Friction thoughts to the Resolution. Otherwise note pending in the output doc.

## Output Contract

The audit is delivered as a versioned Markdown file at `<project-root>/.claude/audits/<slug>-learn-improve-v<N>.md`. Create `.claude/audits/` if it doesn't exist. Slug is derived from source title (kebab-case, ~30 chars max).

**Required sections (always present):**
- **Header:** Date, Author, Status (Draft/Reviewed/Applied), Project
- **Sources Ingested:** table with title, author, date, type, URL
- **Extracted Patterns:** Concepts + Techniques + Anti-Patterns + Architecture Decisions (any may be empty list, but section header always present)
- **Current State Audit:** Gap Summary (table) + Detailed Gaps
- **Recommendations:** Quick Wins / Projects / Backlog / Cross-Cutting Themes (any may be empty)

**Optional sections (depends on phases run):**
- **Friction Sources** (only if Phase 0 ran)
- **Open Brain Captures** (only if Phase 2.5 ran)
- **Applied Changes** table (only if Phase 5 executed)

**Out of scope (this skill does NOT produce):**
- The actual skill/file modifications themselves (Phase 5 produces those; the audit doc only tracks them)
- Open Brain captures (Phase 2.5 produces those; the audit doc only references them)
- Multi-project audits (one project per audit file; meta-stack lives in your-meta-repo-local skill)
- Recommendations for skills marked DO NOT MODIFY (per Audit Rules)

**Format guarantees:**
- Markdown file with versioned filename suffix `-v<N>.md`
- Status field is one of three exact values: `Draft`, `Reviewed`, `Applied`
- Recommendations sorted Impact desc → Effort asc → Risk asc within each priority tier
- Every Recommendation references at least one specific file path

```markdown
# Learn and Improve: <Topic or Article Title>

**Date:** <YYYY-MM-DD>
**Author:** YOUR_NAME
**Status:** Draft | Reviewed | Applied
**Project:** <project name from CWD>

## Sources Ingested

| # | Title | Author | Date | Type | URL |

## Friction Sources (if Phase 0 ran)

## Extracted Patterns
### Concepts
### Techniques
### Anti-Patterns
### Architecture Decisions

## Open Brain Captures (if Phase 2.5 ran)

## Current State Audit
### Gap Summary (table)
### Detailed Gaps

## Recommendations
### Quick Wins
### Projects
### Backlog
### Cross-Cutting Themes

## Applied Changes (if Phase 5 ran)
| File | Change | Recommendation # |
```

## Modes

**Single source:** Run Phase 1-4 for one input.

**Batch (multiple sources):** Run Phase 1-2 for ALL sources in parallel. Deduplicate patterns across sources (consensus reinforces priority). Run Phase 3-4 once with merged pattern set.

**Incremental (adding to existing audit):** Read existing `<slug>-learn-improve-v<N>.md`. Run Phase 1-2 for new source only. Skip duplicates. Append to existing file (increment version).

**Friction-only:** Run Phase 0, skip Phase 1-2, go directly to Phase 3-4 using friction patterns as input.

## Quick Reference

| Trigger phrase | Mode |
|---|---|
| "let's improve this project" + URL | Phase 1-4 single source |
| "let's improve ourselves" + N URLs | Phase 1-4 batch |
| "add this article to the existing audit" | Incremental |
| "audit recent friction" | Phase 0 friction-only |

## Common Mistakes

- **Paraphrasing the workflow inline instead of producing a versioned artifact.** The artifact is the deliverable. Use `Write` to produce it.
- **Bounding scope too narrowly.** If an article doesn't map to a code change, ask: does it suggest a CLAUDE.md addition, a new skill, a new hook, an MCP, a workflow tweak? Surface those as Workflow Recommendations rather than declaring "no recommendations."
- **Reading from memory instead of disk.** Always Read the actual current state of project files before judging gaps. Skills and configs evolve.
- **Inflating recommendations.** Not every article applies. "Diminishing returns" is a valid honest finding when supported by the audit.

## Differences from Idea-Forge Local Version

This global skill is for **project-improvement** scope. The your-meta-repo-local version (`your-meta-repo/skills/intake/learn-and-improve/`) is for **workflow/meta-stack** scope (your-meta-repo + dotfiles + your-data-repo + Claude workflow).

Use your-meta-repo's local version when:
- The article is about Claude Code workflow, skill design, prompt engineering, agent orchestration, or anything that improves the user's cross-project Claude experience
- The audit target is the meta-stack, not a specific project

Use this global version when:
- The user is in any project (including your-meta-repo) and wants to improve THAT project specifically
- The audit target is the project's own files

## Version

1.0.2 - Phase 3.6 lens question 3 broadened to both/and (client/enterprise + personal project). Reason: 1.0.1's "Solutions Architect / client-applicability" framing was too narrow on the other side - excluded the personal-project angle. Many projects fit both axes; lens should reflect that.

1.0.1 - Phase 3.6 lens question 3 reframed from "DevRel value" to "Solutions Architect / client-applicability value." Reason: user is a Solutions Architect (not DevRel); recurring mis-framing in past audits.
