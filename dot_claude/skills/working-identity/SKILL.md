---
name: working-identity
description: |
  Conversation-first workflow for extracting and maintaining a portable AI working
  identity across the four BYOC layers (Domain / Workflow / Style / Artifact).
  Use when the user wants to bootstrap or refresh their working identity for use
  across AI vendors, tools, or employers - or when entering a new tool/role and
  needing to seed it with the user's existing working patterns.
  Persists per-layer entries to Open Brain via the `[Domain]` / `[Workflow]` /
  `[Style]` / `[Artifact]` prefixes (personal machine) AND to the local file
  `~/.claude/working-identity.md` (cross-machine fallback - canonical store on
  work machine, export target on personal machine).
version: 1.0.0
---

# Working Identity (BYOC)

## Purpose

Working identity is the fifth category of professional capital - alongside skills, network, abilities, and track record. Unlike those four, it lives outside the user's head on third-party AI servers by default, fragmented across accounts that cannot talk to each other. This skill captures it back into user-controlled infrastructure so it is portable across AI vendors, employers, and tools.

The skill walks through four extraction phases - one per BYOC layer - producing structured Open Brain captures (personal machine) plus a markdown snapshot at `~/.claude/working-identity.md` (both machines, paste-able into any AI).

This is NOT the same as `work-operating-model` (which maps how the user's WORK runs). This skill maps how the user works WITH AI.

## When To Use

**Strong triggers:**
- User says "extract my working identity," "bootstrap a new AI with my context," "let's update my BYOC profile," or asks how to make their AI working style portable across tools.
- User is about to onboard a new AI tool (work-issued AI, ChatGPT, Perplexity, Gemini, etc.) and wants to seed it with their existing working patterns.
- User has had a major project completion and wants to capture artifact-layer rationale before it decays.
- User invokes this skill explicitly via `/working-identity`.

**When NOT to use:**
- Trivial prompt-tuning for a single conversation (just write a system prompt inline)
- The user's `[Friction]` corrections are the right loop (use `learn-and-improve` Phase 0, not this skill)
- Mapping how the user's work runs (use `work-operating-model` instead - operating rhythms, recurring decisions, dependencies)

## Required Tools

Before doing anything else, confirm what is available in the current environment:

- The base Open Brain capture tool, usually `capture_thought` (or `mcp__open-brain__capture_thought`)
- The base Open Brain search tool, usually `search_thoughts`
- File read/write access to `~/.claude/working-identity.md`

If Open Brain MCP tools are missing (work computer, regulated environment), continue in `--no-open-brain` mode: write only to `~/.claude/working-identity.md`. Do not warn the user about missing Open Brain - just proceed in markdown-only mode.

If file access to `~/.claude/working-identity.md` is also blocked, stop and say so clearly.

## Non-Negotiable Rules

1. **Layer order is fixed:** Domain → Workflow → Style → Artifact. Each layer builds on the previous. Do not skip ahead unless the user explicitly says "skip Layer N."

2. **Start concrete, not abstract.** Ask about specific recent work, recent corrections, recent surprises. Do not open with abstract questions like "what is your working style?" - the user cannot answer that cleanly. Ask "what did the AI get right last week without being told?" instead.

3. **Search Open Brain first as hint, not fact.** Before each layer interview, run `search_thoughts` for existing entries with the layer's prefix. Treat results as tentative context. Confirm with the user before re-persisting anything that already exists.

4. **Save only after explicit confirmation.** Show a checkpoint summary at the end of each layer. Ask for confirmation or corrections. Only THEN call `capture_thought` (or write to the markdown file).

5. **Portability tag is mandatory on `[Domain]` and `[Artifact]` entries.** Default for `[Domain]` is `sensitive`. `[Workflow]` and `[Style]` default to `portable`. The user can override per entry. If the user is unsure, default to `sensitive` and say so.

6. **Persist lean memory.** Five to fifteen entries per layer is plenty. Do not capture every micro-pattern. Capture the durable ones - the patterns the user expects to apply across AI tools / employers / years.

7. **Do not silently smooth contradictions.** If a `[Style]` entry says "user prefers terse" but a recent `[Friction]` says "user wanted more detail here," surface the contradiction and let the user resolve it.

8. **Do not outsource comprehension to the AI.** The user must review and edit each entry before persistence. Auto-generation without review is dark identity.

## Workflow

### Phase 0: Session Start

1. Confirm tool availability (Open Brain MCP + file access). Set mode (`--with-open-brain` or `--no-open-brain`).
2. Read `~/.claude/working-identity.md` if it exists. Show the user the current state - which layers have entries, which are empty.
3. Ask which layers to work on this session. Default suggestion: all four if it is a fresh extraction, or one specific layer if the user wants a focused refresh.
4. Confirm portability defaults with the user (sensitive for Domain, portable for Workflow + Style, mixed for Artifact).

### Phase 1: Layer 1 - Domain (Industry vocabulary, products, market dynamics)

**Search first:** `search_thoughts` for `[Domain]` to see existing entries.

**Interview prompts (use 3-5 per session, not all):**
- "What industry / market are you currently working in? Give me the 30-second elevator version."
- "What 5-10 acronyms or terms do you use weekly that an outside AI wouldn't know?"
- "What products / platforms / tools do you reference daily? (Names, not categories.)"
- "What's the regulatory environment - what compliance frameworks shape your decisions?"
- "Who are your competitors / counterparties / vendors? Just the names that recur."
- "What's a question someone in your role would have a strong opinion on that an outsider wouldn't?"

**For each answer, ask the portability question:** "Is this safe to surface at a future employer / client, or is it specific enough to where you work now that it should stay sensitive?"

**Checkpoint:** show a summary of 5-15 candidate entries with portability tags. User confirms / edits / removes.

**Persist:** for each confirmed entry, call `capture_thought` with format `[Domain] <topic>: <one or two sentence description>. Portability: <portable|sensitive|block>` (skip the call if `--no-open-brain`). Always also append to the `## Domain` section of `~/.claude/working-identity.md` in the same format.

### Phase 2: Layer 2 - Workflow (Stated structural preferences)

**Search first:** `search_thoughts` for `[Workflow]`.

**Interview prompts (use 3-5):**
- "When you ask an AI for research, what structure do you want back? Length, sections, citation style?"
- "When you ask for a code review, what do you want first - the bugs, the style notes, the architectural concerns?"
- "What does a 'good first draft' look like for a doc / spec / blog post in your workflow?"
- "What sequence of steps do you follow when analyzing a new problem? (Give a recent example.)"
- "What format / template do you want for internal memos, summaries, status updates?"
- "What do you want the AI to do AFTER finishing the main work - summary, next steps, both, neither?"

**Checkpoint and persist** as in Phase 1, but the prefix is `[Workflow]` and Portability defaults to `portable` (these are durable working patterns, rarely employer-specific).

### Phase 3: Layer 3 - Style (Unstated / inferred behavioral patterns)

This is the hardest layer. The user often does not consciously know their own style preferences - they have only corrected when something felt wrong.

**Search first:** `search_thoughts` for `[Style]` AND `[Friction]`. The Friction thoughts are negative signals (what NOT to do); they imply a positive Style preference.

**Two-pronged interview:**

**Prong A - Reactive corrections to positive style:**
- Show the user 3-5 recent `[Friction]` entries. For each, ask: "What's the underlying preference here? If we capture it as a positive `[Style]` rule, what would it say?"
- Example translation: `[Friction] user pushed back on trailing summary` → `[Style] user prefers terse responses, no trailing summaries when the diff is self-explanatory`.

**Prong B - Right-without-being-told inference:**
- Ask: "What has the AI gotten right recently without you having to instruct it? Things you didn't have to correct?"
- Probe: "When you asked for X recently, how did the AI know to format it as Y? You didn't tell it to format that way - the AI inferred it. What's the inference?"
- Capture these as positive `[Style]` entries.

**Other prompts (use 2-3):**
- "When do you want the AI to challenge you vs just execute? Give an example of each."
- "How much preamble before getting to the answer is okay? When does it become annoying?"
- "What's your default technical depth? When should the AI go deeper, when should it stay high-level?"

**Checkpoint and persist:** prefix is `[Style]`, Portability defaults to `portable`.

### Phase 4: Layer 4 - Artifact (Built-output rationale)

This layer is project-driven. Skip this phase if the user has not completed any meaningful artifact recently.

**Search first:** `search_thoughts` for `[Artifact]` AND for `[Decision]` thoughts referencing the project paths. Existing `[Decision]` thoughts often have the rationale - check before re-eliciting.

**Per project (last 30-60 days, or user-specified):**
- "What's the project path / canonical location?"
- "What was built? One line."
- "What were the 2-3 key tradeoffs you made? What did you consider and reject?"
- "What would this artifact tell a future employer about how you think? (Not the artifact itself - the way you approached it.)"
- "Is the rationale safe to surface at a future employer (`portable`), or is it specific enough that it should stay (`sensitive`)? Most artifact-rationale is portable; the artifact CONTENT is often sensitive."

**Capture format:** `[Artifact] <project name>: **Path:** <path>. **What:** <one line>. **Tradeoffs:** <2-3 tradeoffs>. **Demonstrated capability:** <what this tells a future employer>. Portability: <portable|sensitive>`.

**Checkpoint and persist** with `[Artifact]` prefix and explicit Portability tag.

### Phase 5: Trade-Secret Filter Sweep

Run after Phases 1-4 complete. For each `[Domain]` and `[Artifact]` entry just captured, ask the user:

- "If this entry surfaced verbatim at your next employer, would you be uncomfortable?"
- "Is there any company-confidential string in here? A specific product code, internal acronym only used at one place, regulatory submission detail?"

For any "yes" answer, switch the entry's tag to `sensitive` (or `block` for unrecoverable confidentiality breaches). For `block` entries, delete the entry and recapture with the offending string removed.

This sweep is the IT-acceptance and legal-safety story. Friction at write-time is the right place for it.

### Phase 6: Markdown Snapshot (Cross-Tool Export)

After all layers complete, ensure `~/.claude/working-identity.md` reflects the current state. The file's four sections (Domain / Workflow / Style / Artifact) should each have the entries from this session plus any pre-existing entries.

If the user wants a vendor-agnostic snapshot for a non-Claude tool (ChatGPT, Perplexity, etc.):
- Filter out anything Claude-Code-specific (skill names, agent types, hook configs - these are infrastructure references, not portable identity).
- Filter out anything tagged `sensitive` or `block` (cross-tool means cross-employer-by-default unless the user overrides).
- Output to `~/Documents/working-identity-portable-v<N>.md` with version number.
- Tell the user the file is ready to paste as a system-prompt-style header.

If the user is on the work machine (no Open Brain), Phase 6 has already happened in-place during Phases 1-4 (every capture also wrote to the markdown file).

## Canonical Entry Formats

### `[Domain]`
```
[Domain] <topic>: <one or two sentence description>. Portability: <portable|sensitive|block>
```

### `[Workflow]`
```
[Workflow] <artifact type or workflow>: <preference description>. Portability: portable
```

### `[Style]`
```
[Style] <situation or trigger>: <observed preference, ideally with the trigger that revealed it>. Portability: portable
```

### `[Artifact]`
```
[Artifact] <project name>: **Path:** <canonical location>. **What:** <one-line summary>. **Tradeoffs:** <2-3 key tradeoffs>. **Demonstrated capability:** <what this tells a future employer about how I think>. Portability: <portable|sensitive>
```

## Checkpoint Format

Before persisting any layer's entries, show:

```
## Layer <N>: <Layer Name> - Checkpoint

Found <X> existing entries in Open Brain (and/or working-identity.md). 

Adding <Y> new entries this session:

1. <prefix> <one-line summary>. Portability: <tag>
2. <prefix> <one-line summary>. Portability: <tag>
...

Modifying <Z> existing entries:

A. <prefix> <existing> → <new>

Confirm to persist? (yes / edit / cancel)
```

Wait for explicit user confirmation. Only then call `capture_thought` and append to `~/.claude/working-identity.md`.

## Markdown File Append Format

When writing to `~/.claude/working-identity.md`, append entries to the appropriate section. Use this format:

```markdown
## Domain
- **<topic>** (Portability: <tag>) - <description>
- **<topic>** (Portability: <tag>) - <description>
```

Same pattern for `## Workflow`, `## Style`, `## Artifact`. Do not delete existing entries unless the user explicitly says to. Append, don't overwrite.

## Tone

- Be conversational, not interrogative. The user is articulating something tacit; pressure produces dishonest answers.
- Show the work. Reflect back what the user said in your own words before persisting; let them correct.
- Praise specific, concrete answers. Push back gently on abstractions ("can you give me the most recent example?").
- One layer at a time. Do not collapse layers into one mega-interview.

## Common Mistakes

- **Skipping the search-first step.** Existing entries may already cover what you are about to ask. Always `search_thoughts` for the layer's prefix at the start of each phase.
- **Persisting before confirmation.** The work-operating-model precedent is non-negotiable: checkpoint summary + explicit confirmation before any `capture_thought` call.
- **Treating Layer 3 like Layers 1-2.** Style is harder. Use both prongs (reactive Friction translation + proactive right-without-being-told inference).
- **Forgetting the Phase 5 sweep.** The trade-secret filter is the difference between "portable asset" and "legal liability." Do not skip it.
- **Auto-generating entries from chat history without user review.** Dark identity. The user must review every entry before persistence.

## Version

1.0.0 - Initial release. Mirrors the `work-operating-model` skill pattern (conversation-first, checkpoint-confirm-persist) but for the four BYOC layers (Domain / Workflow / Style / Artifact) instead of the five operating-model layers. Cross-machine: persists to Open Brain via core `capture_thought` (not a separate recipe MCP) on personal machine; persists only to `~/.claude/working-identity.md` on work machine. Portability tag (portable / sensitive / block) mandatory on Domain and Artifact entries. Phase 5 is the trade-secret filter sweep that makes the asset cross-employer-safe.
