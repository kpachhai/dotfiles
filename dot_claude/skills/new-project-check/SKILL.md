---
name: new-project-check
description: Use BEFORE committing serious time to a new app, side project, business idea, or open-source repo. Surfaces durable positioning across 6 infrastructure layers + 5 business-defensibility verticals + AI-resilience diagnostic + distribution gap. Returns GO / RECONSIDER / KILL with explicit reasons. Triggers on phrases like "I have an idea for", "let's start a new project", "is this worth building", "evaluate this project idea", "should I build X". Use upstream of `idea-refiner` and `north-star-builder` - this is a viability filter that runs first.
---

# New Project Viability Check

## Purpose

Most projects fail at the positioning stage, not the building stage. This skill runs a new project idea through three filters before you commit time to it:

1. **Durable positioning** - which of the 5 verticals (trust / context / distribution / taste / liability) does it own, or does it sit in the "doomed middle" of wrapping a base model?
2. **Infrastructure layer awareness** - which of the 6 agent stack layers does it sit in, and what's that layer's maturity?
3. **AI-resilience** - what does this still own if AI gets 10x better in 12 months?

Plus the hard one most builders skip: **distribution**. When supply is infinite, curation is the scarcest resource. "Build it and they will come" was always wrong; more wrong now.

The output is a structured viability report ending in **GO / RECONSIDER / KILL** with reasons. Not a binding verdict - the user always decides. But the reasons are explicit enough to argue against rather than vibe past.

**This is a global skill** - use in any project context, on any machine.

## When To Use

- Considering starting a new app, side project, business, or open-source repo
- Within the first hour of an idea, before committing build time
- Pivoting an existing project (re-run after major scope change)
- Evaluating someone else's project pitch (client, friend, hackathon submission)
- Solutions Architect: helping a client decide whether to build vs buy vs partner

## When NOT To Use

- **Quick experiments / hackathon weekends.** Overhead > value. Just build.
- **Internal tooling for personal use only.** No audience to defend against.
- **Continuation of an already-running project with no scope change.** Use audit / `north-star-builder` instead.
- **Document creation work** (PRD, presentation, blog post). Use `idea-refiner` instead - that's about choosing the right document type, not viability.
- **Tool evaluation** (should I adopt X?). Use `evaluate-ai-tool` instead - that's about adoption, not building.
- **You've already invested >40 hours.** Sunk-cost mode; viability check at this stage is closing the barn door.

## Workflow

Read `references/framework.md` first - it contains the 5 verticals, 6 layers, diagnostic question, and distribution discipline in full. The skill body below is the question structure; the framework is the lens.

### Step 0: Capture The Idea In One Sentence

Force a one-sentence statement: "I want to build X for Y because Z." If the user can't compress it, that's a finding worth surfacing - probably the idea isn't sharp enough yet.

### Step 1: 5-Vertical Positioning

Walk through each of the 5 verticals (trust / context / distribution / taste / liability) and ask: "does this project own a meaningful position in this vertical?"

- **Trust:** does the project act as verification or guarantee for users / agents in any way?
- **Context:** does the project accumulate proprietary user data / state that makes it hard to leave?
- **Distribution:** does the project have a built-in audience / channel / curation layer?
- **Taste:** does the project's success depend on a specific point of view or editorial judgment that the user owns?
- **Liability:** does the project sit in a regulated domain where accountability is the actual product?

For each: **Yes / Partial / No** + one-sentence reason.

If the answer is **No across all 5** - the project is in the doomed middle. Surface this as a critical finding. The user can still proceed (sometimes a wrapper IS valuable temporarily) but should know.

### Step 2: 6-Layer Stack Positioning

Walk through the 6 infrastructure layers (compute / identity / memory / tools / billing / orchestration) and ask: "where does this project sit?"

- For each layer the project touches: is it consuming an existing solution, or building a new one?
- For new builds: is it native to that layer, or a shim?
- For consumers: is the consumed layer mature (compute, tools), early (memory, identity), or open gap (orchestration)?

Surface dependency on early or open-gap layers as a risk - these layers will see major churn.

### Step 3: AI-Resilience Diagnostic

Single question: **"What does this project own that still matters if AI gets 10x better in 12 months?"**

If the answer is one of the 5 verticals or one of the 6 mature infrastructure layers, the project is defensible.

If the answer is "we have a better UX" or "we have prompt engineering" or "we wrap the model differently" - that moat erodes in weeks now. Surface this as a critical finding.

### Step 4: Distribution Plan Check

Single question: **"How will the first 100 users / customers / agents discover this?"**

Acceptable answers:
- Specific channel (e.g., "I have a 5K-subscriber newsletter where this fits"). Validate the channel actually fits.
- Specific community (e.g., "I'm active in r/X and the project solves an explicit pain there"). Validate.
- B2B with named pipeline (e.g., "client A has asked for this; B and C are likely follow-ons"). Validate.
- Existing distribution (e.g., "the project extends an open-source repo with 10K stars"). Validate.

Unacceptable answers:
- "I'll post on Twitter / LinkedIn / Hacker News and hope" - field-of-dreams thinking.
- "Word of mouth will spread it" - not a plan.
- "The product will sell itself" - definitely not a plan.

If the distribution plan is in the unacceptable list, surface as **the most likely cause of failure** - bigger than build risk. Per Nate B Jones: distribution gap is what kills most AI projects in 2026.

### Step 5: Output The Verdict

Format the response as a structured report ending in one of three verdicts:

**GO** - Project owns at least 1 vertical OR one mature infrastructure layer with a clear distribution plan AND a defensible answer to the AI-10x diagnostic. Proceed; route to `north-star-builder` (your-meta-repo) or `idea-refiner` for next steps.

**RECONSIDER** - Project has gaps in 1-2 of the above but is fixable. Surface the specific gaps and what would close them. User decides whether to invest the closing work or pivot.

**KILL** - Project sits in the doomed middle (no vertical, no infrastructure ownership, no distribution plan, no AI-resilience answer). Recommend pivoting or skipping. User can override - sometimes a known-doomed wrapper is worth building for short-term value - but the override should be conscious.

## Output Contract

The viability report is delivered **inline in conversation**. Optional: save to `workspace/<project-slug>/viability-check-v1.md` if the user wants a record.

**Required sections (always present):**
- One-sentence idea statement (from Step 0)
- 5-vertical positioning (table format with Yes/Partial/No + reason per vertical)
- 6-layer stack position (which layers, native vs shim, maturity risk)
- AI-resilience diagnostic answer (or admission of "none" if applicable)
- Distribution plan check (acceptable vs unacceptable)
- **Verdict:** GO / RECONSIDER / KILL
- **Top 3 risks** ordered by likelihood of killing the project
- **Top 1 strength** - what to lean into

**Optional sections (depends on context):**
- Worked retrospective (if comparing against a past project of yours)
- Client framing (if this is a Solutions Architect deliverable for a client)
- Pivoting suggestions (if RECONSIDER or KILL)

**Out of scope (this skill does NOT produce):**
- A North Star (use `north-star-builder` after GO verdict)
- A document plan (use `idea-refiner` after GO verdict)
- A technical architecture (use `tech-arch-builder` later)
- A business plan / market sizing (different exercise)

**Format guarantees:**
- Verdict is one of exactly three values: GO / RECONSIDER / KILL
- All five workflow steps appear in order
- Every "No" or "doomed middle" finding has an explicit reason
- Distribution plan is validated, not just listed

**Consumed by (downstream chain):**
- User makes the decision; this skill informs, does not bind
- If GO: route to `idea-refiner` (your-meta-repo) or `north-star-builder` for project planning
- If RECONSIDER: user iterates on the gaps and re-runs this skill
- If KILL: capture as `[Parked]` thought in Open Brain with the kill-reasons; useful future signal

## Common Pitfalls

- **Vague vertical claims.** "We have great UX" is not "we own taste." Force specificity. Taste = the user has explicit editorial judgment that drives decisions; "great UX" without that is just hope.
- **Confusing utility with defensibility.** A useful tool is not the same as a defensible business. Internal personal tooling skips this skill (correctly); product/business positioning needs it.
- **Distribution hand-wave.** "I'll figure out distribution later" is the most common failure mode. Push back. The plan does not have to be perfect; it has to be specific.
- **AI-resilience evasion.** "AI will never replace this because [generic vibe]" is not an answer. Force a specific layer or vertical claim, or accept the doomed-middle finding.
- **Skipping the worked retrospective when relevant.** If the user mentions a past project, run that one through the same lens. Concrete pattern-matching beats abstract framework.

## Worked Example: Himalayan Gambit Retrospective

If the user invokes this skill on Himalayan Gambit (an active solo project), the output would be:

- **Idea:** "I want to build a 10-game freemium PWA platform for a niche audience because no one is serving them well today."
- **5 verticals:** Trust = Yes (Stripe + Coinbase Commerce as trust layer). Context = Partial (user accounts + game state, but limited cross-game context). Distribution = **No** (PWA without distribution channel = invisible). Taste = Yes (thoughtful UX choices: AI fill, freemium gates, 10-game scope). Liability = N/A (gaming, low surface).
- **6 layers:** Standard web stack (Next.js + Supabase + Railway). Layer 4 (tools/integration) consumed via Stripe + AI APIs. No agent layers. Mature consumer choices.
- **AI-10x diagnostic:** Owns context (user game state) and taste (curated experience). Defensible.
- **Distribution plan check:** **Critical gap**. PWA without explicit channel. "Word of mouth" was the implicit plan.
- **Verdict:** RECONSIDER - close the distribution gap before scaling build investment. Possible fixes: B2B partnership pipeline (one identified niche partner with audience access), specific community presence, or explicit content/SEO play.
- **Top 3 risks:** (1) Distribution = invisible-app risk. (2) Freemium conversion math unproven. (3) 10-game scope is large for solo dev (build vs distribute time tradeoff).
- **Top 1 strength:** Taste - the AI-fill + freemium-gate decisions show real product judgment.

The retrospective is illustrative; the actual HG decisions remain Anuja's. The point is the framework would have flagged distribution as the #1 risk **at project start**, not in retrospect.

## Source

Combined framework from two Nate B Jones videos (2026-05):
- "The Agent Infrastructure Stack: 6 Layers" (https://www.youtube.com/watch?v=7HP1jFJ9W1c) - bottom-up infrastructure
- "5 Things AI Cannot Replace" (https://www.youtube.com/watch?v=ib2m9HVX7as) - top-down business defensibility

Audit docs: `your-meta-repo/workspace/your-meta-repo-meta/nate-jones-agent-infra-stack-learn-improve-v1.md` and `nate-jones-five-durable-verticals-learn-improve-v1.md`.

Companion personal reference: `your-meta-repo/workspace/your-meta-repo-meta/agent-stack-literacy.md` (where I sit in the framework today).

## Version

1.0.0 - Initial. Combines the 5 durable verticals + 6 infrastructure layers + AI-resilience diagnostic + distribution discipline into a project-start viability check.
