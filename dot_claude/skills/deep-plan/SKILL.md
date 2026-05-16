---
name: deep-plan
description: Use BEFORE writing code on non-trivial tasks - multi-file changes, architectural decisions, security-relevant work, bug fixes with unclear root cause, refactors touching shared abstractions, or any work where shipping a wrong plan is expensive. Triggered by phrases like "plan this", "design before coding", "what's the approach", "/deep-plan". Dispatches code-analysis, risk, and edge-case sub-agents in parallel during plan construction, then runs a critique pass. Produces an inline plan with risks and edge cases already incorporated, not appended after.
---

# Deep Plan

Multi-sub-agent planning for non-trivial work. Decompose plan construction into specialized sub-agent roles dispatched in parallel, then synthesize a plan that already incorporates risks and edge cases.

**This is a global skill** - it works across any project.

The premise: traditional plan-then-critique pipelines run a single agent to produce a plan, then run a critic over it, then regenerate. Deep Plan inverts this - critique inputs (risk, edge cases, current state) are dispatched as parallel sub-agents DURING plan construction, so the synthesized plan emerges already-incorporating their findings rather than needing post-hoc revision.

## When To Use

Activate when any of these apply:

- Multi-file changes with hidden coupling
- Architectural decisions with multiple plausible approaches
- Bug fixes where the failure mode is unclear or non-local
- Refactors that touch shared abstractions
- Security-relevant changes
- Migrations or schema changes
- The user explicitly invokes `/deep-plan` or asks for a "deep plan"
- Prior friction in the project shows premature implementation has cost real time

## When NOT To Use

- Trivial tasks (typo fixes, single-file renames, formatting changes) - dispatch overhead exceeds quality gain
- The user has already provided a clear plan and just wants execution
- Pure research / lookup tasks where there's nothing to "plan"
- Adding tests to existing well-understood code

If unsure, default to using the skill - the cost of an over-engineered plan is small; the cost of a wrong implementation on multi-file work is large.

## When To Dispatch Sub-Agents vs Read Files Directly

Default: dispatch sub-agents (parallel, isolated context, summary-back). Sub-agent dispatch is the right move for breadth/retrieval - "what files exist, what conventions apply, what risks lurk."

Exception (read files directly in main agent): apply when ALL of the following are true:

- The task's load-bearing reasoning depends on relationships BETWEEN files - invariants preserved across modules, contracts honored across layers, a state machine split across handlers, a type guarantee threaded through several call sites.
- A summary would collapse the pair-wise relationships into noun-phrases. ("File A defines X; file B uses X" is the kind of summary that loses HOW the use preserves the invariant.)
- Main agent has the context budget to hold the relevant files.

In that case, the main agent reads the files directly so cross-file co-attention is possible. Sub-agent dispatch is for breadth/retrieval; direct read is for depth/cross-file reasoning. They are complementary, not competing - a deep plan may dispatch sub-agents for breadth in Step 2 AND read a small set of files directly when Step 3 synthesis needs to reason about how they fit together.

## Workflow

### Step 1: Verifiable Goal

Restate the task as a single-sentence verifiable goal. Format: "When complete, <observable check> will be true."

If the goal is unclear or has multiple plausible interpretations, ASK before dispatching sub-agents. Dispatching against an ambiguous goal wastes 4x the cost of a single-agent clarification.

### Step 2: Dispatch 3 Sub-Agents in Parallel

Use a SINGLE message with 3 Agent tool calls so they run concurrently. The 4th sub-agent (critique) runs after synthesis in Step 4.

**Sub-Agent 1: Code Analysis** (`general-purpose`)

Prompt:
```
Read the relevant files for this task. Summarize:
(a) What currently exists (key types, functions, abstractions)
(b) Constraints and conventions visible in the code
(c) How the existing code is invoked / who depends on it

Do NOT propose changes. Return a 200-400 word summary plus a list of files you read.

Task: <task description>
Suggested starting paths: <relevant paths if known, else "discover via grep/glob">
```

**Sub-Agent 2: Risk Identification** (`general-purpose`)

Prompt:
```
For this task, enumerate adversarially:
(a) Failure modes - what could go wrong at runtime
(b) Hidden coupling - what an implementer is likely to miss
(c) Deprecation traps or version mismatches
(d) Security concerns
(e) Data integrity risks (race conditions, partial writes, lost updates)

Be specific. Generic risks like "error handling" or "edge cases" are not useful - name the actual scenario.

Return a prioritized list with severity (High/Medium/Low) and a 1-2 sentence explanation per item.

Task: <task description>
```

**Sub-Agent 3: Edge Cases** (`general-purpose`)

Prompt:
```
For this task, list the boundary conditions and edge cases the implementation must handle:
(a) Empty / null / zero inputs
(b) Maximum sizes and overflow
(c) Concurrent access scenarios
(d) Error states and rollback / partial-completion behavior
(e) Unicode, encoding, or locale issues if applicable
(f) Network failures or timeouts if applicable

Be specific to this task - don't list every theoretical edge case. Return a categorized list.

Task: <task description>
```

### Step 3: Synthesize the Draft Plan

Compose a draft plan with these sections:

```markdown
## Goal
<one sentence, verifiable>

## Current State
<key facts from Code Analysis sub-agent - not the full summary>

## Risks
<from Risk sub-agent, prioritized; each MUST have a corresponding mitigation in the Plan section, or be explicitly deferred with reason>

## Edge Cases
<from Edge Cases sub-agent; each MUST be addressed in a plan step OR explicitly deferred with reason>

## Plan
<numbered steps, each with inline verifier in this format:
N. <action> -> verify: <how you know it worked>>

## Open Questions
<unresolved items the sub-agents flagged - these need user input before execution>
```

**Synthesis discipline:** every risk and every edge case from the sub-agents MUST appear in either the Plan steps (as something that gets handled) or as an explicitly-deferred item with reason. Don't quietly drop sub-agent findings.

### Step 4: Self-Critique (4th Sub-Agent)

Dispatch the critique sub-agent: use `code-reviewer` if the work is code-heavy, else `general-purpose`.

Prompt:
```
Review this draft plan for:
(a) Missing pieces - things the plan should address but doesn't
(b) Contradictions between sections
(c) Unverified assumptions
(d) Scope inflation beyond the stated goal
(e) Risks or edge cases that were listed but not actually addressed in the plan steps

Return findings with severity (Blocking / Should-Fix / Nice-to-Have).

Plan:
<full draft plan>
```

### Step 5: Revise Once + Present

If critique surfaces Blocking or Should-Fix findings, revise the plan ONCE before presenting. Do not loop indefinitely - one revision pass, then ship.

Present to the user:
1. The final plan inline (this is the work product)
2. A brief summary line: "Code analysis read N files. Risk sub-agent flagged X high-priority risks: <names>. Edge case sub-agent flagged Y boundary conditions. Critique surfaced Z findings, revised."
3. Optional: full sub-agent outputs in a collapsible Appendix if the user wants to verify which finding came from which agent

## Output Contract

The plan is delivered inline in the conversation. It is the work product, not a side artifact.

**Required sections (always present):**
- **Goal:** one-sentence verifiable goal
- **Current State:** key facts from code-analysis sub-agent
- **Risks:** prioritized list with mitigations addressed in Plan section
- **Edge Cases:** boundary conditions, each addressed in Plan steps OR explicitly deferred
- **Plan:** numbered steps with inline verifier per step (Karpathy Goal-Driven Execution format)
- **Open Questions:** unresolved items requiring user input before execution

**Optional sections (depends on task):**
- **Sub-agent findings appendix:** raw outputs from analyze/risk/edge-case sub-agents (when high-stakes work warrants the verification trail)
- **Plan file:** saved to `<project>/.claude/plans/<slug>-deep-plan-<YYYY-MM-DD>.md` if `.claude/plans/` exists, otherwise inline only

**Out of scope (this skill does NOT produce):**
- Implementation code (the plan describes what to do; doesn't write it)
- Tests (named in plan steps but not authored)
- PR drafts or commit messages (use `ship` skill for that)
- Final verification of completed work (use `verify-before-done` for that)

**Format guarantees:**
- Markdown headers in the order shown above
- Every Risk and Edge Case appears in either the Plan section (as a step that handles it) or Open Questions (deferred with reason); never silently dropped
- Every Plan step has an inline verifier (`-> verify: <how>`)

## Optional Mode: Throw-Away First Draft

When the mental model for a task is genuinely uncertain - greenfield design, complex business logic with multiple defensible approaches, refactors where the optimal target shape isn't yet clear - the main Workflow's plan + execute loop can land an implementation that encodes the wrong design instinct. Throw-Away First Draft is the bias-discovery counter-move: implement a deliberately disposable first draft, compare against your mental model to surface where the agent's defaults diverge from your judgment, then iterate with sharpened prompts.

### When to use throw-away mode

- Greenfield design where the user's mental model isn't yet sharp
- Complex business logic with multiple defensible approaches
- Refactors where the target shape is uncertain (e.g. extracting an abstraction whose shape depends on use cases not yet enumerated)
- Architectural decisions where a reconnaissance implementation reveals constraints faster than analysis alone

### When NOT to use throw-away mode

- Small well-specified tasks (overhead exceeds value)
- Bug fixes with clear root cause - you don't need reconnaissance, you need the fix
- Mechanical refactors (rename, format, lift function) where the target is unambiguous
- Tight time budget - throw-away mode at minimum doubles implementation effort

### Throw-away workflow

1. **Clarify** (main Workflow Step 1): Restate the task as a verifiable goal; resolve ambiguity before dispatching anything.
2. **Plan** (main Workflow Steps 2-5): Run the full multi-sub-agent plan including critique pass.
3. **Throw-away implementation:** Create an experimental branch named `throwaway/<feature-or-task>`. Direct the agent to implement the plan end-to-end on that branch. Deliberately disposable - no test polish, no documentation, no commit-message care.
4. **Mental-model diff:** Compare the implementation against the user's mental model. Surface concrete divergences: "I expected X to be a class; the agent made it a module-level function. I expected errors to propagate; the agent swallows them and returns None." Each divergence is a bias-discovery datum.
5. **Plan refinement:** Incorporate the divergence findings into sharpened prompts. Re-run the plan with the new constraints baked in ("X must be a class because <reason>; errors must propagate because <reason>").
6. **Final implementation:** Discard the throw-away branch (or keep as reference only). Execute the refined plan on a clean branch via the standard `superpowers:executing-plans` flow.

### Discipline

- **Name the branch.** `throwaway/<feature>` is non-negotiable. A throw-away branch without the prefix risks accidental merge. Delete the branch after extracting findings.
- **Don't sanitize the throw-away.** The goal is to see the agent's UNSUPERVISED defaults. Cleaning up midstream defeats the bias-discovery purpose.
- **Extract divergences explicitly.** Don't just feel "something is off" - write out the specific decision points where the implementation diverged from your expectation. These become the constraints in the refined plan.
- **One throw-away pass, not multiple.** If you find yourself running throw-away mode twice for the same task, the issue is your initial mental model is still unclear - return to clarification, not another throw-away.

## Cost & Trade-offs

- **Cost:** 4 agent dispatches per plan (3 parallel + 1 sequential critique). Roughly 30-90 seconds total wall-clock depending on file-read scope.
- **Justified for:** non-trivial work where shipping a wrong plan is expensive (multi-file refactors, architectural decisions, security-relevant changes, migrations).
- **NOT justified for:** trivial tasks. Skip the skill entirely.
- **Throw-away mode cost:** doubles total implementation effort (one disposable pass + one keeper). Justified only when the bias-discovery benefit outweighs the second-implementation cost - i.e. the "When to use throw-away mode" list above.

## Integration

- **Often invoked by:** `dev-orchestrator` when recommending non-trivial tasks; user explicit invocation
- **Often feeds into:** direct implementation OR `superpowers:executing-plans` for multi-session work
- **Bracketed by:** `verify-before-done` at end-of-task. Together they make plan-execute-verify the default loop for non-trivial work.
- **Differs from `cross-agent-review`:** cross-agent-review evaluates a finished deliverable using multiple models; deep-plan constructs a plan using multiple sub-agents during planning. Different stage of the work.
- **Differs from `superpowers:writing-plans`:** writing-plans encodes single-agent plan-writing discipline; deep-plan adds multi-sub-agent decomposition. They are complementary - deep-plan can produce input that writing-plans then formalizes.

## Anti-Patterns This Skill Avoids

- **Plan-then-critique pipelines:** running a critic over a finished plan and then regenerating. Wastes work; the plan that already incorporates critique input is cheaper than two passes.
- **Single-agent plan inflation:** one agent trying to think about code, risks, edge cases, and synthesis simultaneously tends to produce shallow coverage. Decomposition increases breadth.
- **Cloud A/B-lottery:** Anthropic's `/ultra plan` cloud feature randomizes between Simple/Visual/Deep variants and the user has no control which they get. Running deep-plan locally guarantees the high-quality variant every time.

## Source

Inspired by Ray Amjad's reverse-engineering of Anthropic's `/ultra plan` Deep Plan variant in Claude Code (2026-04, https://youtu.be/UNhA17l6CWw). Ray extracted the Deep Plan prompt from Claude Code binary strings to bypass the cloud A/B-lottery and run the multi-sub-agent pattern locally. This skill operationalizes that pattern.

---

**Version:** 1.0.0
