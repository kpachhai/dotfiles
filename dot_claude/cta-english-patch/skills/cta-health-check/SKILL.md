---
name: cta-health-check
description: |
  This skill should be used when the user asks for a "quick check", "overview",
  "how much did I spend", "check status", "summary", or wants a fast one-page summary
  of Claude Code token usage and costs. The lightest CTA workflow, completes in
  under 3 minutes. Can also be routed from the main cta skill.
---

# CTA Health Check — Quick Overview

One-page summary of Claude Code usage status. The lightest CTA workflow.

## Workflow

### Step 1: Sync Data
Execute `mcp__token-analyzer__sync_db`. Skip if already called in this conversation.

### Step 2: Global Analysis
Execute `mcp__token-analyzer__analyze_global` with no parameters.

### Step 3: Output Summary
Format results as the following table. Fill every row from the analyze_global response.

```markdown
## CTA Health Check Report

| Metric | Value |
|--------|-------|
| Total Sessions | X |
| Total Projects | X |
| Total Cost | $X.XX USD |
| Avg Cache Hit Rate | X.X% |
| Subagent Token Ratio | X.X% |

### Top 3 Projects (by cost)
1. project-name — $X.XX (N sessions)
2. ...
3. ...

### Top 3 Most Expensive Sessions
1. a1b2c3d4 — $X.XX (project-name)
2. ...
3. ...
```

### Step 4: Ask Direction
After presenting the summary, ask:
> "Which direction to drill down? Cost / Anomalies / Project / Trend"

Route the user's choice to the corresponding sub-skill:

| Choice | Invoke |
|--------|--------|
| Cost | `cta-cost-audit` |
| Anomalies | `cta-anomaly-hunt` |
| Project | `cta-project-review` |
| Trend | `cta-trend-watch` |

## Output Rules

- Use English for all prose. Keep technical identifiers as-is.
- Currency: `$X.XX USD`.
- Percentages: one decimal place (`85.3%`).
- session_id: first 8 characters only (`a1b2c3d4`).
- Token counts: thousands separator (`125,000`).
- Cache hit rate < 70%: mark with warning.
- Subagent ratio > 20%: mark with notice.

## Additional Resources

For MCP tool parameter details: `${CLAUDE_PLUGIN_ROOT}/skills/cta/references/tool-reference.md`
