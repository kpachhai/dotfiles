---
name: evaluate-ai-tool
description: Use when evaluating a new AI tool, MCP server, agent framework, model, or AI-related platform for adoption decisions - personal use, internal tooling, or client/enterprise recommendation. Produces a structured evaluation against a fixed rubric (infrastructure fit, layering, semantic surface, configurability, scale economics, lock-in) so adoption decisions are explicit and comparable across tools.
---

# Evaluate AI Tool

Structured rubric for evaluating new AI tools (MCP servers, agent frameworks, models, platforms, libraries) before adopting them. Prevents shallow "this looks cool, let's use it" decisions and makes adoption tradeoffs explicit.

**This is a global skill** - it works across any project. Use for personal tool choices, work decisions, or client/enterprise recommendations.

## When to Use

- A new AI tool, MCP server, agent framework, or model has been announced and the user is deciding whether to adopt it
- A client or enterprise team is asking for a recommendation on AI tooling
- The user is comparing 2+ tools for the same job
- An existing tool is causing friction and the user is considering replacement
- The user explicitly invokes `/evaluate-ai-tool` or asks "should we use X?"

## When NOT to Use

- Simple "does this work for my task" prototyping - just try it
- The user has already decided and just wants implementation help
- Tooling decisions where cost/effort to switch is trivial (cheaper to try than evaluate)

## The Rubric

For each tool, score these six dimensions. Each one is independently meaningful - low scores in two or more dimensions usually means "don't adopt."

### 1. Infrastructure Fit

Does this tool bridge to the user's (or client's) existing infrastructure, or does it force the existing infrastructure to adopt the tool's protocol/format?

- **Strong (bridge):** Speaks the existing transport, format, or auth surface. Drops in next to existing services with minimal translation. **Strongest positive signal: tool ships as an MCP server (or installable Claude Code skill).** MCP-first distribution composes immediately with the rest of the agent ecosystem; no bridging work needed. Empirical evidence: Remotion went from a niche website to 150K+ Claude Code installs in 8 weeks after shipping as a skill.
- **Weak (force):** Requires the user to replace, rewrite, or wrap existing services to fit the tool's expectations.

This is the highest-value dimension for enterprise contexts because force-adoption costs scale with org size.

### 2. Layering / Pluggability

Is the tool's architecture layered (transport, format, semantics separated) so individual layers can be replaced, or is it monolithic?

- **Strong (layered):** Each concern is independently swappable. Default options preserved for backward compat; alternatives are first-class.
- **Weak (monolithic):** Tightly coupled. Replacing any layer requires forking or replacing the whole thing.

Layered tools age better. Monolithic tools become technical debt when one layer (e.g., transport) needs to change.

### 3. Semantic Surface for LLMs

Does the tool carry semantic context that LLMs need (when-to-use, what-it-does), or does it only expose structure (types, signatures)?

- **Strong:** Tool descriptions include explicit usage guidance. Examples in docs are LLM-consumable. The tool is designed for AI agents, not just humans.
- **Weak:** Tool exposes raw API/types and assumes the consumer knows when to call what. LLMs misuse it.

Critical for any tool that AI agents will consume. Semantic-poor tools force a wrapper layer.

### 4. Configurability vs Mandatory Behavior

Does the tool give the user choices with sensible defaults, or does it force opinions?

- **Strong:** Default + alternative pattern. The default works for most users; alternatives exist for edge cases. User picks based on context.
- **Weak:** One-size-fits-all. The vendor's opinion is mandatory. No escape hatch when their opinion doesn't fit.

Be especially wary of tools that A/B-test prompts or behavior server-side without user control - this is the "lottery" anti-pattern. The user can't reproduce results.

### 5. Scale Economics

Where does this tool's cost-benefit curve actually pay off?

- **Low-scale:** Negligible benefit at small scale (e.g., binary serialization vs JSON when you have <100 req/s and LLM inference dominates).
- **High-scale:** Real benefit only at production scale (e.g., gRPC transport for MCP at thousands of req/s).
- **Cross-scale:** Benefit at all scales (e.g., type safety, semantic descriptions).

Adoption math: if the user is at low-scale and the tool only pays off at high-scale, the cost of adoption (learning curve, migration, ops overhead) outweighs the benefit. Don't adopt prematurely.

### 6. Lock-in / Exit Cost

If the user adopts this tool and later wants to leave, what's the exit cost?

- **Low lock-in:** Tool uses open standards. Data is portable. Migration is mechanical.
- **High lock-in:** Tool uses proprietary formats. Data extraction is hard or expensive. Replacement requires rewrite.

For client/enterprise recommendations, lock-in is usually a deal-breaker unless the vendor relationship is already strategic.

## Sub-Rubric: Runtime Guardrail Risk Profile (apply when the tool runs autonomous actions)

When the tool will execute actions in production without per-action human approval (autonomous agents, scheduled jobs, agentic workflows), score each class of action this tool would take on four axes. The four axes determine where to draw the human-in-the-loop line.

| Axis | Question | Why it matters |
|------|----------|----------------|
| **Blast Radius** | Cost of error if this action goes wrong? | A misspelled email is recoverable; an incorrect drug-interaction recommendation or unauthorized wire transfer is catastrophic. Magnitude shapes everything else. |
| **Reversibility** | Can the mistake be undone after the fact? | Draft email = yes (review before send). Sent wire transfer = no. High-blast + low-reversibility = mandatory pre-action human approval. |
| **Frequency** | How often does this action run? | 10,000/day multiplies any per-run risk. Frequency at scale converts low-blast errors into high-impact incidents. |
| **Verifiability** | Can correctness be checked, and is the check semantic (sounds right) or functional (is right)? | Functional verification means a downstream consequence test exists ("did the recommended credit card actually fit the customer?"). Semantic-only verification is insufficient at runtime - it catches fluency, not competence. |

**Decision rules:**
- High blast radius + low reversibility → mandatory pre-action human approval, no exceptions
- Low blast radius + high reversibility + functional verification available → full automation appropriate
- Frequency multiplies any per-run risk - reassess thresholds when an action runs at high frequency
- Semantic-only verifiability is rarely sufficient at production scale; demand functional checks where blast radius is non-trivial

This sub-rubric does not replace the 6 main dimensions - it complements them when the tool will run autonomously. Skip it for tools that are dev-only, internal-research-only, or always require human approval per action.

## Output Contract

The evaluation is delivered inline in the conversation as a structured response.

**Required sections (always present):**
- **Tool name** as heading
- **6-dimension scoring table** with Strong/Mixed/Weak rating per dimension and one-line notes
- **Recommendation** verdict: Adopt / Adopt with conditions / Defer / Don't adopt
- **Reasoning** (2-3 sentences) citing the specific dimensions that drove the verdict

**Optional sections (depends on verdict):**
- **Conditions / cautions** list (only if verdict is "Adopt with conditions")
- **Runtime Guardrail Risk Profile** sub-rubric (only if the tool will execute autonomous actions in production)

**Out of scope (this skill does NOT produce):**
- Implementation guidance for adopted tools (this is decision support, not setup help)
- Migration plans away from existing tools (separate concern)
- Cost-benefit financial models (rough scale economics only, not detailed ROI)
- Vendor procurement or contract terms

**Format guarantees:**

```markdown
## Tool: <name>

| Dimension | Score (Strong/Mixed/Weak) | Notes |
|-----------|---------------------------|-------|
| Infrastructure Fit | <S/M/W> | <one-line> |
| Layering / Pluggability | <S/M/W> | <one-line> |
| Semantic Surface for LLMs | <S/M/W> | <one-line> |
| Configurability | <S/M/W> | <one-line> |
| Scale Economics | <S/M/W> | <one-line> |
| Lock-in / Exit Cost | <S/M/W> | <one-line> |

## Recommendation

<Adopt / Adopt with conditions / Defer / Don't adopt>

**Reasoning:** <2-3 sentences citing the dimensions that drove the decision>

**Conditions / cautions:** <if "Adopt with conditions">
- ...
```

## Calibration

- **2+ Weak dimensions** → default to "Don't adopt" or "Defer until they fix"
- **All Strong** → "Adopt" - rare but happens (well-designed open-standard tools)
- **Mixed** → "Adopt with conditions" - specify the conditions explicitly so the user can revisit if they fail to hold

## Common Pitfalls

- **Hype bias:** A tool's announcement quality and stargazer count are not adoption signals. Ignore them. Score the dimensions.
- **Single-dimension thinking:** "It's faster!" or "It has a great API!" - score all six. Speed alone doesn't beat lock-in or force-adoption costs.
- **Premature scale assumption:** Tools designed for high-scale problems are wrong choices at low-scale. Check the user's actual scale before recommending.
- **Vendor pressure:** "Everyone is using X" is not a dimension. Score independently.
- **Confirmation bias on existing choice:** When evaluating a replacement for a tool you already use, run the rubric on BOTH the incumbent and the challenger. Apples-to-apples.

## Source Material

This rubric is derived from patterns captured in Open Brain, primarily:
- `[Pattern] Layered Protocol Design` (semantic / message-format / transport separation)
- `[Pattern] Bridge-to-existing-infrastructure vs force-adoption` (Google's gRPC-for-MCP move)
- `[Pattern] Semantic context vs structural context for LLM tool consumption`
- `[Pattern] A/B-Testing-as-Lottery` (server-side prompt randomization as anti-pattern)

Future patterns captured by `learn-and-improve` should feed back into this rubric. When you find a recurring tool-evaluation lens, add it as a new dimension.

## Version

1.0.0
