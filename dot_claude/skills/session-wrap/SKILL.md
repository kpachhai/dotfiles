---
name: session-wrap
description: Structured end-of-session protocol that captures what was accomplished, what was learned, what should change, and next actions. Triggers on wrap-up cues or explicit invocation. Produces a concise session summary for memory persistence.
---

# Session Wrap-Up

## Purpose

Capture structured knowledge at the end of productive work sessions so insights don't evaporate between conversations. This replaces ad-hoc "remember this" with a consistent protocol.

**This is a global skill** - it works across any project.

## When To Use

### Explicit Triggers (User-Initiated)

Activate when the user signals session end:
- "let's wrap up", "that's it for now", "park this", "goodnight"
- "what did we accomplish?", "summarize this session"
- User invokes `/session-wrap` directly

### Proactive Triggers (Claude-Initiated)

Claude proactively suggests `/session-wrap` at four logical boundaries:

1. **Substantive commit-and-push checkpoint.** A feat / refactor / new-tests / new-docs commit lands on a remote branch. EXCLUDES chore/style/typo micro-fixes — those don't warrant a wrap. The wrap captures what shipped, what surprised us, what changed about the approach mid-implementation.

2. **`[Resolution]` event.** A skill change, config update, or doc fix that closes the loop on a previously-logged `[Friction]`. The resolution itself is a learning worth preserving; the wrap formalizes it before context drift erases the why.

3. **End of session.** User signals stop ("wrap up", "park this", "goodnight"), OR the conversation has reached a coherent stopping point with no clear next step queued up.

4. **~70% context-fill fallback.** If none of (1)-(3) has triggered and the context window is approaching ~70% full, suggest a wrap so durable knowledge lands in memory before auto-compact starts dropping things. Better to wrap proactively than to lose context to summarization heuristics.

The user runs `/session-wrap` (Claude can invoke the skill via the `Skill` tool) and `/clear` (CLI-side command; only the user can run it). After Claude suggests a wrap and the user confirms, Claude runs the wrap, then proposes `/clear` and names the natural next step so the user can resume cleanly.

**Cadence target:** 3-5 wraps per long working session. Dense enough to catch learnings; not so dense that wrap overhead dominates.

### Do NOT Auto-Invoke The Skill

Even when a proactive trigger fires, Claude SUGGESTS the wrap and asks for confirmation; it does not silently invoke the skill. The user remains in control of when wraps happen — proactive suggestion is a recommendation, not an action.

## Process

### Step 1: What Was Accomplished

List the concrete work products from this session:
- Files created or modified (with paths)
- Decisions made
- Problems solved

Keep it factual. 3-5 bullet points max.

### Step 2: What Was Learned

Capture non-obvious insights that would help future sessions:
- Patterns discovered (how something works)
- Failures and their fixes (what broke, what fixed it)
- Surprises (things that didn't work as expected)

**Quality test:** Would this help someone (including future-you) who starts a new session tomorrow on the same project? If yes, capture it. If it's obvious from the code/docs, skip it.

### Step 3: What Should Change

Specific skill, config, or documentation updates needed:
- "builder-foundation needs a new lessons log entry about X"
- "CLAUDE.md should mention that Y"
- "The research skill should add a rule about Z"

If changes are small (1-2 edits), offer to make them now. If larger, capture as ACT NOW items.

### Step 4: ACT NOW Items (3-5 Max)

The most important next actions. Each must have:
- **What:** specific action (not vague)
- **Why:** why it matters
- **Next step:** the single next concrete action

Example:
- **What:** Update whitepaper-builder quality prompts for Depth dimension
- **Why:** v1 whitepaper deep-dives scored 2/5 on depth - described features without explaining mechanics
- **Next step:** Add "Do deep-dive sections explain HOW features work, not just WHAT they do?" to the Depth prompt

### Step 5: PARKED Items

Interesting ideas that aren't urgent. Brief note on each:
- What the idea is
- Why it might matter later
- What would trigger revisiting it

### Output Format

Save to memory (not to a file) unless the user requests a file. The memory entry should be concise enough to fit in one screen:

```markdown
## Session Wrap: <date> - <project or topic>

**Accomplished:**
- <bullet 1>
- <bullet 2>

**Learned:**
- <insight 1>
- <insight 2>

**Should Change:**
- <skill/config update needed>

**ACT NOW:**
1. <action> - <next step>

**PARKED:**
- <idea> - revisit when <trigger>
```

### Step 5.4: Friction Enumeration

Before persisting (Step 5.5), explicitly enumerate frictions noticed during this session:

1. List each correction the user made: factual error caught, scope overstated, surface-level test missed a real bug, UI shipped with visible issues, premature completion claim, missed verification step, fabricated citation, wrong approach taken.
2. For each one, ask: "Is this already in `~/.claude/friction-log.md` and Open Brain?" If not, capture both NOW per CLAUDE.md "How to Capture" Step 4 (the dual-write to friction-log + `capture_thought`).
3. Friction capture should have happened at the moment of correction. This step is the safety net: anything that slipped through gets caught here.
4. **Resolution check:** if any of this session's work closed the loop on prior friction (skill change, config update, doc fix that addresses a logged friction), append a `[Resolution]` row to friction-log AND capture a `[Resolution]` thought to Open Brain. Per CLAUDE.md "World Model - Three Architectures": friction without resolution is a knowledge base, not a world model.

If no frictions were noticed this session, state that explicitly. The absence is signal too - either the session was routine, or friction is being missed.

### Step 5.5: Persist to Open Brain (Optional)

If the `capture_thought` MCP tool is available (Open Brain is connected):

1. **Capture the session summary** as a single thought. Format the content as:
   ```
   [Session Summary] <date> - <project or topic>
   Accomplished: <bullet points from Step 1>
   Learned: <insights from Step 2>
   Should Change: <items from Step 3>
   ```

2. **Capture each ACT NOW item** as a separate thought. Format each as:
   ```
   [Action Item] <what> - <why> - Next step: <next step>
   ```

3. **Do not capture PARKED items** as `[Action Item]` - capture them as `[Parked]` with explicit unpark triggers. See "How to Capture" in `~/.claude/CLAUDE.md` for the format.

4. **`[Artifact]` capture (optional - for shipped artifacts only).** If the session shipped a non-trivial artifact - a finished doc, demo, skill, blog post, presentation, or code feature that a future employer might want to know you can build - ask the user once: "Capture an `[Artifact]` thought for this? Project path + 2-3 key tradeoffs + what this would tell a future employer." Only ask when something genuinely shipped (not for routine session work). If the user agrees, capture in this format:
   ```
   [Artifact] <project name>: **Path:** <canonical location>. **What:** <one-line summary>. **Tradeoffs:** <2-3 key tradeoffs>. **Demonstrated capability:** <what this tells a future employer about how I think>. Portability: <portable|sensitive>
   ```
   Default Portability is `portable` for the rationale (the *thinking* transfers across employers); the artifact CONTENT is often sensitive but here we are capturing rationale, not content. Per the BYOC Layer 4 framework in CLAUDE.md "Working Identity (BYOC)" section.

If the `capture_thought` tool is NOT available, skip Step 5.5 silently. Do not warn the user or suggest they set up Open Brain.

### Step 6: Skill Improvement Check (Optional)

If anything in "What Was Learned" or "What Should Change" qualifies for the skill-improver (investigation > 10 min, workaround found, etc.), ask the user: "Should I run the skill-improver to capture these patterns?"

## Rules

1. **Concise over comprehensive.** A 10-line summary that captures the essence beats a 50-line transcript of everything discussed.
2. **Specific over vague.** "Update whitepaper depth prompt" beats "improve skill quality."
3. **3-5 ACT NOW max.** If everything is urgent, nothing is. Prioritize ruthlessly.
4. **Don't capture what's in the code.** The commit history and diff show what changed. Capture the WHY and the WHAT-NEXT, not the WHAT.
5. **Don't force it.** If the session was a quick Q&A or minor edit, a wrap-up adds no value. Say "Nothing substantial to capture from this session" and move on.

## Wrap-Then-Clear Pattern

When the wrap is mid-session (proactive trigger 1, 2, or 4 above), the natural follow-up is `/clear` so the next chunk of work starts with a fresh context window. The wrap has just captured the session's durable knowledge to Open Brain + friction-log + CHANGELOG; raw conversation history was paying token-tax for context that is now persisted.

The flow:

1. Claude detects a trigger (commit-and-push, `[Resolution]`, end-of-session signal, or ~70% context fill).
2. Claude suggests: "good wrap point — run `/session-wrap` then we `/clear` and continue with [the named next step]?"
3. User confirms; Claude invokes the skill via the `Skill` tool. Mid-session wraps use `--checkpoint` mode (lighter; deltas only).
4. After wrap completes, Claude tells the user the natural next step ("OK to `/clear`; next iteration: [Step N] of [plan-file]").
5. User runs `/clear` (CLI-side; Claude cannot trigger it).
6. The user's next message rebuilds minimal context from the breadcrumbs the wrap left — CHANGELOG `[Unreleased]`, the relevant audit log, recent Open Brain captures, the implementation plan's "next step" pointer. DO NOT re-load the full prior conversation; that defeats the point.

This pattern is what makes BYOC operationally cheap. Every wrap is a deposit into persistent memory; every `/clear` is the dividend - a fresh context window without losing the work product.

## Configurable Behavior

- **Mode** (the `--checkpoint` vs default distinction):
  - **Default (full retrospective):** all 6 steps. Used at end of session or before a project ships. Thorough; longer.
  - **`--checkpoint`:** Steps 1 (Accomplished), 2 (Learned), 5.4 (Friction Enumeration), 5.5 (Persist) only. Skips ACT NOW / PARKED / Skill Improvement Check, since those make more sense aggregated at end of session. Mid-session wraps focus on capturing deltas. Faster; lighter.
- **Output:** Memory entry (default) or file in `workspace/<project>/session-wrap-<date>.md`. The Open Brain capture in Step 5.5 is the canonical persistent home; the file is for project-specific traceability.
- **Skill-improver integration:** Optional (Step 6). Skipped by default unless the user enables it.

---

**Version:** 1.2.0
