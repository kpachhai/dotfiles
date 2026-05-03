# Framework: 5 Verticals + 6 Layers + AI-Resilience

This is the canonical framework for the `new-project-check` skill. Read this first when invoking the skill.

Source: Two Nate B Jones videos (2026-05) - "The Agent Infrastructure Stack: 6 Layers" + "5 Things AI Cannot Replace."

---

## The Core Pattern

> **AI commoditizes production. Survivors own layers production cannot replace.**

Two kinds of "layers production cannot replace":

1. **Underneath production** - the 6 infrastructure layers (compute, identity, memory, tools, billing, orchestration). These are picks-and-shovels for the AI economy.
2. **Above production** - the 5 durable verticals (trust, context, distribution, taste, liability). These are positions AI structurally cannot occupy.

The "doomed middle" is anything that just **wraps a base model nicely**. UI moats erode in weeks now that Claude Code + Codex exist. A better model from Anthropic / OpenAI / Google can replace any wrapper overnight.

---

## The 5 Durable Verticals (Top-Down Business Defensibility)

### 1. Trust

**What it owns:** Verification - this app won't steal your credit card; this content was produced by a real person; this service does what it claims.

**Why AI cannot occupy it:** Trust requires accountability to humans / regulators / commercial relationships. A model has no skin in the game.

**Named players:** Stripe (powered-by-Stripe is itself a trust signal at $1T+ in transactions), Shopify, Apple App Store review process, Vercel deployment infrastructure, certificate authorities.

**Position diagnostic:** Does the project act as verification or guarantee for users / agents in any way? Does it route trust signals into the system? In the agentic economy, agents need trust signals to know which APIs / payments / services are safe.

### 2. Context

**What it owns:** Your specific data + the permissioning layer over it. Customer relationships, medical records, meeting notes, organizational knowledge graphs.

**Why AI cannot occupy it:** AI is a general application tool. To be useful, it needs context unique to your situation. Whoever owns the authoritative context owns a choke point that every agent has to flow through.

**Named players:** Notion (100M users' structured knowledge graphs), Salesforce, Epic (healthcare), Palantir (security), Snowflake, Databricks.

**Position diagnostic:** Does the project accumulate proprietary user data / state that makes it hard to leave? An agent without context is a chatbot; an agent with context is a dependable junior employee. That gap is where context-owning businesses live.

### 3. Distribution

**What it owns:** Curation when supply is infinite. Telling people / agents where to go.

**Why AI cannot occupy it:** Distribution gatekeepers strengthen, not weaken, when the flood of supply gets bigger. AI making it 100x easier to produce apps makes curation 100x more valuable.

**Named players:** Google (search), Apple App Store, TikTok, YouTube, Substack, Amazon (commerce). Emerging: agent-discovery layer for the agentic economy (which businesses are agent-friendly to transact with).

**Position diagnostic:** Does the project have a built-in audience / channel / curation layer? Lovable runs 100K projects/day - most never get discovered. **This is the most-skipped check.** Distribution gap kills more projects than build risk.

### 4. Taste

**What it owns:** Editorial judgment + design sensibility + value-proposition fit. The conviction about what should exist in the world that is not derivable from training data.

**Why AI cannot occupy it:** AI assists; it does not replace. Taste requires a human point of view on how humans (and now agents) connect with humans. In agentic systems, taste translates to "orchestration quality" - the curated experience that does powerful work even when the underlying models commoditize.

**Named players:** Humans. In the AI era, the producer / curator with strong taste is the human-in-the-loop role that survives.

**Position diagnostic:** Does the project's success depend on a specific point of view or editorial judgment that the user owns? "Great UX" without that is just hope. Taste = explicit editorial decisions driving the product, not just polish.

### 5. Liability

**What it owns:** Accountability before regulators, courts, customers. Sells the legal / professional / ethical risk-bearing.

**Why AI cannot occupy it:** "The AI did it" does not survive in court. Regulated industries (healthcare, finance, legal, insurance) sell accountability as the actual product, not the work itself.

**Named players:** Deloitte, McKinsey (repositioning as AI assurance providers), 11 Labs (voice agent insurance), Veeva, Elation, regulated SaaS, AI safety / vetting boutiques.

**Position diagnostic:** Does the project sit in a regulated domain where accountability is the actual product? In the agentic economy, liability becomes a governance layer when agents autonomously execute workflows that touch money, documents, or commitments.

---

## The 6 Infrastructure Layers (Bottom-Up)

### 1. Compute / Sandbox

**Maturity:** Production. Multiple shipped options (E2B, Daytona, Modal, browser base, Alibaba Open Sandbox).

**What it owns:** Where agent code runs safely - isolated, sandboxed, auditable.

**Architectural bet:** Ephemeral (E2B-style, dispose after run) vs persistent (Daytona-style, agent comes back, has dependencies installed).

### 2. Identity / Communication

**Maturity:** Transitional. Most current solutions are shims (email-as-identity).

**What it owns:** How agents authenticate, send / receive messages, hold verifiable identity.

**Architectural bet:** Email-as-shim vs agent-native protocols (TBD - on-chain agent identity, dedicated A2A standards, MCP-based service discovery).

### 3. Memory / State

**Maturity:** Early. Standalone vendors (Mem0) compete with platform built-ins (Anthropic, OpenAI baking memory into models).

**What it owns:** Persistence across sessions, days, tasks.

**Architectural bet:** Standalone (portability) vs platform built-ins (convenience).

### 4. Tools / Integration

**Maturity:** Explosive growth.

**What it owns:** Access to external systems (Slack, GitHub, CRMs, Unix / Python).

**Architectural bet:** Managed integration layer (Composio) vs MCP standardization. If MCP becomes universal, the managed layer's value diminishes.

### 5. Provisioning / Billing

**Maturity:** Brand new (Stripe Projects launched April-May 2026).

**What it owns:** Acquire services + pay for them programmatically.

**Architectural bet:** Agent-credentials-as-account vs human-issues-creds-to-agent.

### 6. Orchestration / Coordination

**Maturity:** Open gap. Frameworks exist (LangChain), infrastructure-grade does not.

**What it owns:** Multi-agent reliability, scheduling, audit, cost controls.

**Architectural bet:** Framework-level vs infrastructure-level. Per Nate B Jones: this will likely be the next infrastructure-defining company in the space.

---

## The AI-Resilience Diagnostic

Single question for any project / tool / position:

> **What does this own that still matters if AI gets 10x better in 12 months?**

| Answer | Verdict |
|--------|---------|
| One of the 5 verticals | Defensible. Bet there. |
| One of the 6 mature layers (compute, tools) | Defensible. Picks-and-shovels position. |
| One of the 6 early / open-gap layers (identity, memory, billing, orchestration) | Defensible IF you can survive the layer's churn. |
| "Better UX" / "better prompt engineering" / "we wrap the model differently" | **Doomed middle.** Erosion in weeks. |
| "Nothing - the model just makes us obsolete" | Honest answer. Change positioning now. |

The doomed middle is not necessarily "don't build." Sometimes a known-doomed wrapper is worth building for short-term cash or learning. But the bet must be conscious, time-bounded, with an explicit migration plan when the model catches up.

---

## Distribution Discipline

> When supply is infinite, curation is the scarcest resource.

Distribution gatekeepers strengthen when the flood is bigger. AI generating 100x more apps makes Google / Apple / Amazon / TikTok curation 100x more valuable. Lovable runs 100K projects per day; most never get discovered.

**Acceptable distribution plan answers:**
- Specific channel with validated fit (a newsletter, community, audience)
- Named B2B pipeline (clients who have asked for it)
- Existing distribution surface (extending an open-source repo with audience)

**Unacceptable:**
- "I'll post on Twitter / LinkedIn / HN and hope"
- "Word of mouth will spread it"
- "Field of Dreams - if I build it, they will come"

The unacceptable answers are field-of-dreams thinking. They were always wrong; more wrong now.

---

## Combined 2-Axis Positioning Grid

When evaluating any project, ask both:

1. **Which infrastructure layer (1-6) does it consume or build in?**
2. **Which durable vertical (1-5) does it own?**

A strong position is **both axes covered** (e.g., Stripe sits in Layer 5 billing AND owns Trust). A weaker position is **one axis covered** - still defensible but with more risk. The doomed middle is **neither axis** - just wraps a model.

For the user (Solutions Architect): use this grid in client architecture conversations. "Where in the infra stack are you, and which vertical of value are you defending?" is a sharper question than "what's your AI strategy?"

---

## How To Apply This Framework

The `new-project-check` skill (parent of this reference file) operationalizes the framework as a 5-step workflow ending in GO / RECONSIDER / KILL. The framework is the lens; the skill is the procedure.

For YOUR_NAME's personal application of the framework to the meta-stack today (where I sit per layer + per vertical), see `your-meta-repo/workspace/your-meta-repo-meta/agent-stack-literacy.md`. That's a state document; this is a framework document.
