# work-operating-model (vendored)

The `work-operating-model` skill from OB1 - a 5-layer elicitation interviewer that turns tacit work patterns into structured Open Brain data and agent-ready exports (SOUL.md, USER.md, HEARTBEAT.md). Adopted via parallel-tool check Q6 (lens v1.4.4): solution shipped upstream, integrates with our existing Open Brain.

## Two-Part Adoption

This skill REQUIRES the paired **Work Operating Model Activation recipe** in your-data-repo (schema + MCP server). The skill is the conversation behavior; the recipe is the data layer.

**Skill side (this directory):**
- Vendored at `dotfiles/dot_claude/skills/work-operating-model/` (chezmoi-managed)
- Refreshable from upstream via `executable_refresh-from-upstream.sh`

**Recipe side (your-data-repo repo):**
- Schema: `your-data-repo/open-brain/migrations/005-work-operating-model.sql`
- MCP server: deployed as a SECOND Edge Function (`work-operating-model-mcp`) alongside the existing `open-brain-mcp`
- Procedure: `your-data-repo/open-brain/README.md` "Work Operating Model MCP" section

Both sides must be in sync. Refreshing one without the other = broken.

## Pinning

`PINNED_COMMIT` records the upstream OB1 SHA. As of 2026-05-03 we are at `42ccebd...` - same pin as our your-data-repo `OB1_PIN`. When bumping your-data-repo's pin, also bump this one.

## Refreshing

```bash
cd ~/repos/.../dotfiles/dot_claude/work-operating-model-meta

# Skill-only refresh (most common - no upstream schema/server changes):
./executable_refresh-from-upstream.sh

# Bump pin (verify upstream schema/server didn't change first):
COMMIT=<new-sha> ./executable_refresh-from-upstream.sh
```

After: `chezmoi apply --force`, then commit + push.

If the upstream schema or MCP server changed at the new commit, ALSO update your-data-repo:
- Apply additive migration to `your-data-repo/open-brain/migrations/`
- Redeploy the `work-operating-model-mcp` edge function
- See your-data-repo README for the full procedure

## Why This Pattern (vs n-agentic-harnesses)

`n-agentic-harnesses` is skill-files-only (markdown + YAML, no runtime). Vendor + chezmoi apply = done.

`work-operating-model` adds a runtime (MCP server tools + persistent state in Supabase tables). Skill alone is non-functional. Both sides required.

Track as Active Shim #6 in `your-meta-repo/workspace/your-meta-repo-meta/agent-stack-literacy.md`.
