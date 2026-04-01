---
name: quick-research
description: Quick research on a topic - gather facts, verify claims, produce a concise brief. Usage - /quick-research <topic>
user-invocable: true
---

# Quick Research Skill

## Purpose

Rapidly research a topic and produce a concise, cited brief. This is the lightweight version of deep research - meant for quick answers backed by evidence.

## Process

### Step 1: Define Scope

From the user's topic ($ARGUMENTS), identify:
- The core question to answer
- 2-3 sub-questions
- What "done" looks like (comparison? state of the art? how-to?)

### Step 2: Research (5-10 minutes equivalent)

1. Search for authoritative sources
2. Cross-reference key claims across 2+ sources
3. Collect quantitative data where available
4. Note contradictions and gaps

### Step 3: Output Brief

```markdown
## Research Brief: <Topic>

**Date**: <today>
**Confidence**: High / Medium / Low

### Key Findings

1. **Finding**: <statement>
   - Source: <URL>
   - Confidence: High/Medium/Low

2. **Finding**: <statement>
   - Source: <URL>
   - Confidence: High/Medium/Low

3. **Finding**: <statement>
   - Source: <URL>
   - Confidence: High/Medium/Low

### Summary

<3-5 sentences synthesizing the findings>

### Open Questions

- <what couldn't be verified>
- <what needs deeper investigation>
```

## Rules

- Always cite sources
- Date the research
- Flag anything you couldn't verify
- Lead with the most important finding
- Keep it under 500 words
