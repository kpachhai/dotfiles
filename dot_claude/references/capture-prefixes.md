# Open Brain capture prefixes — full reference

Detailed examples + BYOC layer mapping for each capture prefix. The main rule
("when to capture which prefix") lives in `~/.claude/CLAUDE.md` "Open Brain"
section; this file is the lookup table for per-prefix nuance.

## Operational prefixes (capture-triggering moments)

| Prefix | Trigger | Example |
|---|---|---|
| `[Lesson]` | Debugging breakthroughs, surprising behaviors, workarounds | Root cause found after investigation; non-obvious fix for a tool/library/API; behavior that didn't match expectations |
| `[Decision]` | Architectural decisions, key project context | Why we chose approach A over B; important constraints future sessions need to know |
| `[Pattern]` | Reusable techniques | Worth remembering across future projects, not specific to one |
| `[Friction]` | User corrections | Factual error caught, scope overstated, surface-level test missed a real bug, UI shipped with visible issues, premature completion claim, missed verification step, fabricated citation, wrong approach taken |
| `[Resolution]` | Skill/config change closing a prior friction loop | Documents that a `[Friction]` was addressed; pairs with the friction's date |
| `[Notice]` | Half-formed observations not yet fitting a prefix | The unnamed pattern that, once seen, may reframe how a system is understood. Reviewed quarterly via Skill Health Audit → promoted to a real prefix, formalized as a new prefix, or removed |
| `[Action Item]` | Future-action commitments | "Do X by Y"; revisit when condition Z fires |
| `[Parked]` | Ideas to revisit later | With explicit unpark trigger |
| `[Meta]` | Notes about the memory system itself | Not about project content; about how memory is being used |

## BYOC layers (working identity capture)

These capture WORKING IDENTITY rather than project content. The four BYOC
layers are professional-capital portable across AI vendors, employers, tools.

| Prefix | BYOC Layer | What it captures | Portability default |
|---|:---:|---|---|
| `[Domain]` | Layer 1 | Industry vocabulary, products, market dynamics, regulatory environment, internal acronyms — what an AI needs to be useful in your work | `sensitive` (requires redaction before cross-employer use) |
| `[Workflow]` | Layer 2 | Stated structural preferences — how you like research/code/docs structured, formats you want, sequencing you follow | `portable` |
| `[Style]` | Layer 3 | Patterns the AI inferred correctly without being told (e.g. "skip trailing summaries because user prefers terse"), or unstated communication preferences (technical depth defaults, when to challenge vs execute, tolerance for preamble) | `portable` |
| `[Artifact]` | Layer 4 | On project completion (`session-wrap` or `ship`), project path + the 4 ship-with-explanation questions (Q1 what is this; Q2 why this / alternatives + trade-offs; Q3 what's going to break / fragile points + assumptions; Q4 what I learned / where AI was confidently wrong + what I'd do differently) | `portable` |

`[Artifact]` Q1-Q4 answers feed both the private capture AND the public
explanation artifact (`comprehension-gate` Step 5) — one authoring effort,
two destinations. Subject to the No-Slop Rule in Dark Code Discipline: human
writes the answers; AI may sketch a strawman.

## Portability tags (mandatory on [Domain] and [Artifact]; default portable elsewhere)

- `Portability: portable` — safe to surface at next employer/client (working style, generic patterns)
- `Portability: sensitive` — requires redaction before cross-employer use (default for `[Domain]`)
- `Portability: block` — confidential; do not capture verbatim, recapture with the confidential string removed

The portability tag is the IT-acceptance + legal-safety story: portable
transfers cleanly, sensitive needs redaction, block never lands in the
canonical store.

## Reflexive friction discipline

`[Friction]` capture is **reflexive, not retrospective**. AT THE MOMENT OF
CORRECTION, before generating the next response, capture the friction. If
you wait until wrap-up, you will forget.

Format:

```
[Friction] <what went wrong> - <what the correct approach was> - <which skill or workflow should be updated>
```

Friction thoughts also append to `~/.claude/friction-log.md` per the dual-write
discipline (covered in the main CLAUDE.md). The log survives on machines
without an Open Brain MCP and is the work-machine fallback that keeps the
friction-feedback loop alive everywhere.

## See also

- `~/.claude/CLAUDE.md` "Open Brain - Persistent Memory" section — the rule
- `~/.claude/CLAUDE.md` "World Model - Three Architectures" — how the layers compose
- `~/.claude/CLAUDE.md` "Working Identity (BYOC)" — the BYOC framework
