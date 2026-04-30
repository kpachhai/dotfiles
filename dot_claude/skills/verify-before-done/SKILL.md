---
name: verify-before-done
description: Produce an explicit verification checklist before claiming a non-trivial task is complete. Triggers when a task involves tests, UI changes, bug fixes, multi-file edits, or any work where missed verification carries real cost. Counters the premature-completion failure mode.
---

# Verify Before Done

## Purpose

Counter the most common failure mode: declaring work complete without checking it actually works. This skill produces an explicit, structured verification report that a task author must fill in before claiming "done."

The goal is not paperwork. It is to force a moment of honest reflection before shipping. Most premature completions happen because the model checks the easy thing (the test ran) and skips the hard thing (the test actually exercises the bug, the UI actually renders, the percentages actually make sense).

**This is a global skill** - it works across any project.

## When To Use

### Behavioral Cues

Activate when:
- Wrapping up a non-trivial implementation task (multi-file change, new feature, bug fix)
- About to write a commit message claiming completion
- The user invokes `/verify-before-done`
- User says "is this ready?", "are we done?", "can I ship?"

### Skip When

- Single-line edits to documentation
- Conversational responses with no code change
- Pure exploration or research tasks (nothing to verify)
- Tasks where the user has explicitly said "just do a quick pass, don't verify"

## The Verification Checklist

Output a checklist with these items. Each item must be either `VERIFIED: <how>`, `SKIPPED: <why>`, or `BLOCKED: <reason>`. Empty checkmarks are not allowed - every item gets a real disposition.

### Section 1: Execution Evidence

```
1. Test/build command run
   Command: <exact command>
   Stdout result: <pass/fail + relevant excerpt>
   Stderr result: <empty/warnings/errors - DO NOT skip stderr>

2. Edge cases tested
   - <case 1>: <input> -> <expected> -> <actual>
   - <case 2>: <input> -> <expected> -> <actual>

3. Bounds-checks for any numerical output
   - <metric>: range [<min>, <max>], observed <value> -> within bounds: yes/no
   - (skip this section if no numerical outputs)

4. UI rendered (if UI change)
   Verification method: <Chrome MCP / Playwright / screenshot / N/A>
   Result: <screenshot path or description>
```

### Section 2: Scope Honesty

```
5. Files actually changed (from git diff --stat)
   <paste output>

6. Commit message draft
   <draft message>

7. Scope match check
   Does the commit message match the diff exactly? <yes/no>
   If no, revise the message before committing.
```

### Section 3: What Was NOT Verified

```
8. Explicit gaps
   - <area not tested and why>
   - <browser/OS/edge case skipped and why>
   - <integration point not exercised and why>
```

### Section 4: Risk Assessment

```
9. If something I missed breaks in production, what would it be?
   <one honest sentence>

10. What would I check if I had 5 more minutes?
    <one specific action - if non-trivial, do it>
```

### Section 5: Six-Failure-Type Diagnostic (Agent / Multi-Step Work Only)

When verifying agent runs, multi-step automated workflows, or any work where output came from an AI system rather than direct human-driven implementation, classify any anomaly into one of six named failure modes. If output looks fine, briefly check that none of these are silently happening.

```
11. Agent / multi-step work failure check (skip if N/A)
    a. Context Degradation - quality dropped as session lengthened?
       (Symptom: later output worse than earlier; context window saturated)
       Status: <not observed / observed: ...>
    b. Specification Drift - did the agent forget the original spec mid-task?
       (Symptom: final output drifts from initial intent; missing pieces declared earlier)
       Status: <not observed / observed: ...>
    c. Sycophantic Confirmation - did the agent confirm incorrect input and build on it?
       (Symptom: agent agreed with a premise that was wrong, then built downstream work on the wrong premise)
       Status: <not observed / observed: ...>
    d. Tool Selection Errors - did the agent pick the wrong tool?
       (Symptom: outcome is partially correct but the path was wrong; suggests tool framing issue)
       Status: <not observed / observed: ...>
    e. Cascading Failure - did one sub-task failure propagate without correction?
       (Symptom: a small early error became a much larger downstream error)
       Status: <not observed / observed: ...>
    f. Silent Failure - does the output look correct but functionally isn't?
       (Most dangerous. Symptom: passes semantic checks; downstream consequence test reveals incorrectness)
       Status: <not observed / observed: ...>
```

If any failure is observed, do not declare done. Fix the named mode (each has distinct fixes - shorter sessions for context degradation, forced spec reminders for spec drift, input validation for sycophantic confirmation, tool description sharpening for tool selection, correction loops for cascading, functional checks for silent failure).

## Output Contract

The checklist is delivered inline in the conversation as a structured response. The artifact is the discipline of filling it in honestly, not a permanent document.

**Required sections (always present):**
- **Section 1: Execution Evidence** (items 1-4: test/build run, edge cases tested, bounds-checks, UI rendered)
- **Section 2: Scope Honesty** (items 5-7: change-vs-request match, list of changes, list of touched-but-shouldnt)
- **Section 3: What Was NOT Verified** (item 8: explicit gaps with reasons)
- **Section 4: Risk Assessment** (items 9-10: production-break risk + 5-more-minutes question)

**Optional sections (depends on work type):**
- **Section 5: Six-Failure-Type Diagnostic** (only if work involved agents or multi-step automated workflows)

**Out of scope (this skill does NOT produce):**
- Actual fixes to issues found (this is verification, not remediation - if a fix is needed, the agent does it as a separate step)
- Commit messages (use `ship` skill for that)
- Permanent file artifacts (compressing the checklist to one paragraph is fine; persisting to disk is opt-in only when user requests)
- Recommendations for future work (focused on current task verification only)

**Format guarantees:**
- Every numbered item gets one of three dispositions: `VERIFIED: <how>`, `SKIPPED: <why>`, or `BLOCKED: <reason>`
- Empty checkmarks not allowed - every item gets a real answer
- Sections appear in numerical order even if compressed
- Section 5 appears only when applicable (agent/multi-step work)

If the user asked for a quick check, you can compress sections into a single paragraph - but every numbered item must still be addressed honestly.

## Failure Patterns This Catches

These are real failures from past sessions that this skill exists to prevent:

| Failure | What got missed | What this checklist catches |
|---------|----------------|----------------------------|
| Tests passed but stderr leaked | Stdout-only check | Section 1 item 1 (stderr explicit) |
| Disconnect rate exceeded 100% | No bounds check on percentages | Section 1 item 3 |
| Chess AI bugs hidden by surface tests | Edge cases never tested | Section 1 item 2 |
| Commit overstated scope | Diff not compared to message | Section 2 items 5-7 |
| UI shipped with overlapping pieces | No visual verification | Section 1 item 4 |
| Mobile breakpoints broken | "Done" claimed without testing them | Section 3 item 8 |

## Rules

1. **Every item gets a real disposition.** No empty checkmarks, no "looks good" without evidence. If skipped, say WHY.
2. **Stderr is not optional.** Always include stderr output, even if just "empty" - the act of looking forces awareness.
3. **Scope honesty before commit.** Do not write the commit message before running `git diff --stat` and reconciling the two.
4. **The "5 more minutes" question is load-bearing.** It is the most useful prompt for catching obvious gaps. Answer it specifically, and if the answer is non-trivial, actually do it before claiming done.
5. **Don't pad to look thorough.** A compressed but honest checklist beats a long checklist filled with "VERIFIED" lies.

## Anti-Patterns

- **Filling in items without actually checking them.** The point is to verify, not to produce a checklist artifact.
- **Treating SKIPPED as a free pass.** Skipping is fine when justified; skipping everything defeats the skill.
- **Running this for trivial tasks.** A docs typo fix doesn't need a 10-item checklist. Use judgment.
- **Treating this as a performance review.** This is a discipline, not paperwork. The user does not need to see every checklist - reference it inline when summarizing completion.

## Configurable Behavior

- **Light mode:** Sections 1, 2, and 4 only (skip explicit gaps section if everything was checked)
- **Full mode:** All four sections
- **Default:** Full mode for code changes, light mode for config/docs changes

---

**Version:** 1.0.0
