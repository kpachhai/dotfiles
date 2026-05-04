---
name: comprehension-gate
description: Use BEFORE merging or shipping any non-trivial AI-generated code change. Asks senior-engineer-style questions about structure, semantics, and why-this-way to surface dark code (AI-generated code nobody understands). Returns COMPREHENSIBLE / PARTIALLY-COMPREHENSIBLE / DARK + reasons. Triggers on phrases like "review this code", "is this ready to merge", "comprehension check on this PR", "did I understand what I just shipped". Companion to `new-project-check` (start-of-project) - this fires at end-of-work / pre-merge.
---

# Comprehension Gate (v1, shim)

## Purpose

"Tests pass" answers **correctness**. It does not answer **comprehension**. Dark code = code shipped to production that no human fully understands - AI-generated, passed automated checks, never read line-by-line.

This skill is a pre-merge filter that asks senior-engineer-style questions on a code change: why this dependency, why this structure, where does state live, what's the failure mode. The accountable human reviews the answers; if any answer is "I don't know," that's a finding that flows back to spec refinement before ship.

The skill does NOT replace test suites, code review, or static analysis. It runs alongside them, asking a different question: **do I understand what I'm shipping?**

**This is a global skill** - works across any project / repo / language.

## Status: v1 SHIM

This is a thin v1 designed to be **swap-replaced** when Nate B Jones (or others) ships a more comprehensive comprehension-gate skill upstream. Per the shim-vs-native discipline:

- **Tracked at:** `your-meta-repo/workspace/your-meta-repo-meta/agent-stack-literacy.md` "Active Shims I Track" table.
- **Swap-out trigger:** A comprehension-gate skill ships in `github.com/NateBJones-Projects/OB1/skills/` OR a comparable, well-designed alternative ships in another community repo. Adopt that instead of maintaining ours.
- **Watch-trigger date:** Re-check upstream every ~30 days starting 2026-06-03.
- **Not a placeholder:** v1 is functional and useful today. The shim framing is honest about long-term ownership, not about quality.

## When To Use

- **Pre-merge on any non-trivial AI-generated code change.** Anything beyond a one-line typo fix or pure config change.
- **Reviewing a PR you didn't write yourself** (yours or someone else's).
- **Auditing a codebase chunk you inherited** - especially in client work where you don't yet have full ownership context.
- **After a multi-step AI build session** where you may have lost track of why things are structured the way they are.

## When NOT To Use

- **Trivial typo / one-line fix.** Overhead > value.
- **Pure config / data file edits.** No comprehension surface to gate.
- **Code I just wrote myself with full understanding.** I AM the comprehension layer.
- **Tests for code I already comprehend.** The test code is straightforward; the gated code is the SUT.
- **Pure refactor where behavior is unchanged AND understood.** Refactors of black-box code do need this skill.

## Workflow

### Step 1: Capture The Change + Spec

Before reading any code, ask: **what was the spec?** One sentence:
> "This change does X for Y reason because Z constraint applies."

If you can't write that sentence, that's the first finding - the change has no spec, which means there's no eval, which means it's dark by definition. Recommend going back to spec-write before review.

### Step 2: Three-Layer Question Walk

For each layer, ask the questions. Either answer them confidently from the code, or flag the unanswered ones as findings.

#### Layer 1: Structural (Where)

- Where does state live? (memory, file, db, cache, external service)
- What does this code depend on? (libraries, internal modules, external APIs)
- What depends on this code? (callers, subscribers, downstream consumers)
- What's the entry point and what's the exit point?

If any answer is "I'm not sure" → structural-dark.

#### Layer 2: Semantic (What)

- What's the failure mode? What happens when X fails (network, parse, validation)?
- What's the retry semantic? Idempotent? Exactly-once? At-least-once? None?
- What's the performance expectation? P50, P99 latency? Throughput? Memory ceiling?
- What's the behavioral contract? What can callers rely on? What's NOT promised?

If any answer is "I'm not sure" → semantic-dark.

#### Layer 3: Why-This-Way (Comprehension)

- **Why this dependency?** What was rejected? What's the migration plan if it dies?
- **Why this structure?** What's the alternative? Why this one specifically?
- **Why this caching choice?** What's the staleness tolerance? When does the cache invalidate?
- **Why this separation of concerns?** Or why this monolith?
- **Why these abstraction boundaries?** Could the same thing be done with fewer / more layers?
- **Why now?** Was this the smallest viable change, or scope creep?

If any answer is "the AI did it that way" or "I'm not sure why" → comprehension-dark.

### Step 3: Verdict

Aggregate the findings into one of three verdicts:

- **COMPREHENSIBLE** - All three layers answered confidently. Ready to merge. Note any minor questions for follow-up but don't block.
- **PARTIALLY-COMPREHENSIBLE** - 1-2 unanswered questions across the three layers. Not dark, but worth a re-read or a quick question to whoever (or whatever) wrote it. Acceptable to merge if the user accepts the residual unknowns explicitly.
- **DARK** - Multiple unanswered questions, especially structural or semantic. **Do not merge.** Loop back to spec refinement: rewrite the spec to be clearer, re-run the agent, re-run the gate. The flywheel is: dark findings → sharper specs → cleaner code → cleaner gates.

### Step 4: Output The Report

Format the response as a structured report ending in one of three verdicts:

```markdown
## Comprehension Gate: <change name>

**Spec (one sentence):** <statement, or "MISSING" if not derivable>

**Structural (where):**
- State: <answer or UNKNOWN>
- Dependencies: <answer or UNKNOWN>
- Dependents: <answer or UNKNOWN>
- Entry / exit: <answer or UNKNOWN>

**Semantic (what):**
- Failure mode: <answer or UNKNOWN>
- Retry semantic: <answer or UNKNOWN>
- Performance: <answer or UNKNOWN>
- Behavioral contract: <answer or UNKNOWN>

**Why-this-way (comprehension):**
- Why these dependencies: <answer or UNKNOWN>
- Why this structure: <answer or UNKNOWN>
- Why this caching / separation: <answer or UNKNOWN>
- Why now: <answer or UNKNOWN>

**Verdict:** COMPREHENSIBLE | PARTIALLY-COMPREHENSIBLE | DARK

**Findings (top 3):**
1. ...
2. ...
3. ...

**Recommended action:**
- If DARK: <specific spec refinement to apply>
- If PARTIAL: <specific question to resolve before merge>
- If COMPREHENSIBLE: ship it, optionally note follow-ups
```

### Step 5 (Optional): Artifact Output Mode

Steps 1-4 produce a private verdict. Sometimes the verdict alone is not enough - you need an explanation artifact that ships ALONGSIDE the work itself, like a commit message that travels with the deliverable. This is the public-facing counterpart to the private gate: proof of comprehension that a future reader (PR reviewer, future-you, employer, client, portfolio visitor) can verify on its own merits.

**Trigger artifact mode** when the user explicitly asks for it: "comprehension gate + write the explanation artifact", "ship the explanation alongside this", "make this portfolio-ready", or similar. Do NOT fire artifact mode by default - it's opt-in to keep the cost of the regular gate low.

When artifact mode fires, after the Step 4 verdict, ALSO produce a 4-question explanation artifact:

```markdown
## Explanation Artifact: <change / artifact name>

### 1. What is this?
<Plain-English statement of what this does AND what it explicitly does NOT do. Not marketing copy. A future reader should understand the scope in 30 seconds.>

### 2. Why did I choose this?
<Alternatives evaluated and why they were rejected. Trade-offs made. Hard choices. Where the path-of-least-resistance was rejected and why.>

### 3. What's going to break?
<Fragile points. Assumptions baked in. Blast radius if requirements change or upstream dependencies move. The honest version, not the marketing version.>

### 4. What did I learn?
<Concrete discoveries during the build. Places where AI output was confidently wrong and the human corrected. What would change next time. Pattern-level learnings that survive the project.>
```

**Default output path:** `<repo-root>/.claude/explanations/<artifact-slug>.md` where `<artifact-slug>` is the commit short-SHA, branch name, or feature slug. Configurable via user request (e.g., "save it next to the deliverable" → place it next to the file the artifact describes).

**The 4 questions are deliberately simple.** Resist the urge to add more. The format's value is that a human reader can spot AI-generated slop in seconds because:
- Q1 slop reads like marketing copy.
- Q2 slop names alternatives no one would seriously consider.
- Q3 slop describes risks that any project would share.
- Q4 slop has no "AI was confidently wrong about X" moment - because slop never corrects AI.

**No-Slop Rule (CRITICAL):** The human writes the answers. AI may sketch a strawman; the human edits, fact-checks against the actual decisions made during the build, and signs off. **Outsourcing the explanation artifact to AI defeats the entire signal value** - a human reader will detect the slop, and the artifact's credibility (and by extension, the user's) collapses to zero. This rule is enforced socially (readers will catch you), not technically (no tool prevents it).

**Relationship to private gate (Steps 1-4):** The artifact is the EXPORT of the comprehension that already happened during Steps 1-4. The 4-question answers should be derivable from the structural / semantic / why-this-way questions already answered. If artifact mode fires and the Step 4 verdict was DARK, do NOT produce a slop artifact - tell the user "comprehension is incomplete, no shippable artifact yet, refine spec and re-run."

**Relationship to `[Artifact]` Open Brain capture:** The same 4 answers feed both. When Open Brain MCP is available, capture the 4 answers as an `[Artifact]` thought (private canonical store). When shipping, write the 4 answers as the markdown artifact (public). One authoring effort, two destinations.

## Output Contract

The comprehension report is delivered **inline in conversation**. Optional: save to `workspace/<project>/comprehension-<change-id>.md` if the user wants a record (rare for v1).

**Required sections (always present):**
- Spec sentence (or MISSING marker)
- All 3 layers (structural / semantic / why-this-way), each with the question set answered
- Verdict (one of exactly three values)
- Top 3 findings
- Recommended action

**Out of scope (this skill does NOT produce):**
- A test suite (use existing test frameworks)
- A correctness review (use `code-reviewer` agent or `coderabbit:code-review`)
- Architecture-level decisions (use `n-agentic-harnesses` evaluation mode)
- Pre-project viability (use `new-project-check`)

**Optional artifact output mode (Step 5):** when explicitly invoked, additionally produces a 4-question explanation artifact at `<repo-root>/.claude/explanations/<slug>.md` for shipping alongside the work. Subject to the No-Slop Rule (human-authored answers).

**Format guarantees:**
- Verdict is one of: COMPREHENSIBLE / PARTIALLY-COMPREHENSIBLE / DARK
- Every UNKNOWN is named explicitly (no "TBD" hand-waving)
- Findings are concrete and traceable to specific code lines or interfaces
- If artifact mode fires: 4 questions answered in the order specified, no extra sections added

## Common Pitfalls

- **Vague spec.** "It improves X" is not a spec. "It does X for Y reason because Z" is. Force the discipline.
- **Trusting the AI's self-explanation.** Asking the AI to explain its own code re-runs the same training distribution. The accountable human must independently understand it.
- **Skipping the gate on "small" changes.** "It's just a function" misses that small dark functions accumulate into large dark codebases.
- **DARK as a moral judgment.** It's not. DARK is a state-of-knowledge marker. The fix is comprehension, not blame.
- **Flagging style preferences as comprehension issues.** "I would have written it differently" is not the same as "I don't understand why it works." Stay focused on comprehension, not preference.

## Pairs With Other Skills

- `new-project-check` - fires at project start (should I build this?). This skill fires at code merge (do I understand what I'm shipping?). Together they bookend the work cycle.
- `verify-before-done` - end-of-task verification of CLAIMS (stderr, bounds-checks). This skill is end-of-task verification of CODE COMPREHENSION. Different focus.
- `code-reviewer` agent - does correctness / maintainability / anti-pattern review. This skill asks "do I understand it?" - distinct from "is it correct?"
- `coderabbit:code-review` - third-party AI review covering correctness + style. Use both: coderabbit for correctness coverage, this for comprehension coverage.

## Source

Nate B Jones, "Dark Code: AI-Generated Code Nobody Understands" (2026-05-03).
URL: https://www.youtube.com/watch?v=E1idsrv79tI
Audit doc: `your-meta-repo/workspace/your-meta-repo-meta/nate-jones-dark-code-learn-improve-v1.md`

This skill operationalizes the 3-layer context engineering pattern Nate describes (structural, semantic, comprehension) as a pre-merge filter. The skill itself is a thin v1 shim; if Nate ships a comprehensive comprehension-gate skill in OB1 (or comparable), swap to it.

The artifact output mode (Step 5) was added in v1.1.0 from Nate B Jones, "Five Principles for Proving Your Worth in 2026" (2026-05). URL: https://www.youtube.com/watch?v=-dJ9WrTG6zQ. Audit doc: `your-meta-repo/workspace/your-meta-repo-meta/nate-jones-proving-worth-learn-improve-v1.md`. The 4-question format ports Nate's "commit message for AI" framing as the public-facing counterpart to the private gate.

## Version

1.1.0 - Added Step 5: Artifact Output Mode (opt-in). Produces a 4-question explanation artifact (what is this / why this / what breaks / what I learned) for shipping alongside the work, distinct from the private verdict. Includes the No-Slop Rule: human writes the answers; AI may sketch but the human edits and signs. Source: Nate B Jones "Five Principles for Proving Your Worth in 2026."

1.0.0 - Initial v1 shim. Three-layer question walk + verdict. Designed to be swap-replaced when upstream ships.
