---
name: cta-cost-audit
description: |
  This skill should be used when the user asks about "monthly costs", "cost report",
  "how much did I spend this month", "monthly audit", "budget", or needs to understand cost
  distribution by project, model, or time period. Supports cross-month comparison
  and model cost optimization suggestions. Can also be routed from the main cta skill.
---

# CTA Cost Audit — Monthly Cost Report

Generate structured monthly cost reports with daily breakdown, project breakdown, and model cost comparison.

## Workflow

### Step 1: Sync Data

Execute `mcp__token-analyzer__sync_db`. Skip if already called in this conversation.

### Step 2: Generate Report

Execute `mcp__token-analyzer__cost_report` with:
- `month`: user-specified YYYY-MM, or current month by default
- `daily`: true
- `project_path`: optional, only if user specifies a project

### Step 3: Output Report

Format results into the following structure. Fill every section from the cost_report response.

```markdown
## CTA Monthly Cost Report — YYYY-MM

**Monthly Total Cost: $X.XX USD**

### Daily Cost
| Date | Cost | Sessions | Notes |
|------|------|----------|-------|
| 03-01 | $X.XX | N | |
| 03-05 | $X.XX | N | <- peak day |

### By Project
| Project | Cost | Share |
|---------|------|-------|
| project-a | $X.XX | XX.X% |

### By Model
| Model | Cost | Tokens | Avg per Million Tokens |
|-------|------|--------|------------------------|
| claude-opus-4-6 | $X.XX | X | $X.XX |
| claude-sonnet-4-6 | $X.XX | X | $X.XX |
| claude-haiku-4-5 | $X.XX | X | $X.XX |

### Optimization Suggestions
- (Calculate savings if Opus usage were replaced by Sonnet where applicable)
```

### Step 4 (Optional): Drill Down

If the user asks about a specific project, execute `mcp__token-analyzer__analyze_project` with that project_path.

### Step 5 (Optional): Cross-Month Comparison

If the user requests comparison, call `cost_report` for the previous month and calculate:
- Month-over-month cost change (absolute and percentage)
- Which projects drove the change

## Behavior Rules

1. Default to current month. Accept YYYY-MM format for historical months.
2. Mark peak days automatically in the daily breakdown.
3. Include "per million token" average in model breakdown for cost comparison.
4. If Opus accounts for >50% of cost, proactively suggest evaluating Sonnet for applicable tasks.
5. For cross-month comparison, show delta as both absolute (`$X.XX`) and percentage (`+X.X%`).

## Output Rules

- Use English for all prose. Keep technical identifiers as-is.
- Currency: `$X.XX USD`.
- Percentages: one decimal place (`85.3%`).
- Token counts: thousands separator (`125,000`).
- Large output (>50K chars): write to `${TMPDIR:-/tmp}/cta-cost-report.md`, report path.

## Additional Resources

For MCP tool parameter details: `${CLAUDE_PLUGIN_ROOT}/skills/cta/references/tool-reference.md`
