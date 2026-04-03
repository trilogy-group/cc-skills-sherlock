# Report Template

Adapt sections based on research type — not every section applies to every report.

---

## Markdown Report Template

```markdown
# {{REPORT_TITLE}}

> Researched by Sherlock V2 on {{DATE}}
> {{BEAD_COUNT}} questions investigated | {{TIME_ELAPSED}} | {{SOURCE_COUNT}} sources

---

## Trust Summary

| Metric | Value |
|--------|-------|
| Factual claims in report | {{N}} |
| Claims with source URL + quote | {{N}} ({{%}}) |
| Validation mode | {{full / spot-check}} |
| Claims validated | {{N}} / {{TOTAL}} |
| Validation results | {{N}} confirmed, {{N}} corrected, {{N}} refuted, {{N}} source dead |
| Contradictions found | {{N — with details in Findings section}} |
| Unique sources cited | {{N}} |
| Source types | {{e.g. "government (4), primary data (8), media (3)"}} |
| Unverifiable claims | {{N or "None"}} — {{noted in report as [Unverified]}} |

*Every factual claim links to its source. Click any link to verify. Every claim traces to a bead ID in the appendix.*

---

## Executive Summary

{{2-3 paragraphs. Lead with the conclusion. Every factual statement has an inline link.

Example: The median home price in Mueller is $520,000 ([Zillow](https://zillow.com/mueller)).
School ratings average 8.2/10 ([GreatSchools](https://greatschools.org/...)).}}

---

## Methodology

- **Goal:** {{REFINED_GOAL}}
- **Decomposition:** {{THREAD_COUNT}} research threads, {{BEAD_COUNT}} questions
- **Sources:** {{SOURCE_COUNT}} sources: {{types}}
- **Validation:** {{VALIDATION_MODE}} — {{N}} claims validated by independent re-fetch of source URLs
- **Contradictions:** {{N}} cross-source conflicts detected; {{N}} resolved, {{N}} noted in report
- **Limitations:** {{gaps, date ranges, ambiguities}}

---

## Findings

### {{Thread 1 Title}}

{{Narrative synthesis. Every factual claim has an inline hyperlink:

Mueller's median home price is $520,000 ([Zillow](https://zillow.com/mueller-austin)).
The neighborhood has seen 8% YoY price growth ([Redfin](https://redfin.com/...)).
This makes Mueller one of the best values in central Austin [Inference — based on price
data from Zillow and Redfin above].

If sources disagreed (contradiction surfacing):
Crime data varies: Austin PD reports 12/1000 ([APD](https://austintexas.gov/...))
while NeighborhoodScout reports 15/1000 ([NS](https://neighborhoodscout.com/...)).
The gap likely reflects different reporting periods [Inference].

If a claim was corrected during validation:
The program amount is $10,900/year ([TX Comptroller](https://comptroller.texas.gov/))
— *corrected from initial finding of ~$10,000 during validation*.}}

### {{Thread 2 Title}}

{{Same structure}}

---

## Contradictions

{{Skip if no contradictions found. Otherwise list each one:

| Topic | Source A | Source B | Resolution |
|-------|----------|----------|------------|
| {{topic}} | {{claim}} ([source](url)) | {{claim}} ([source](url)) | {{which is correct, or "Unresolved — both values noted in report"}} |

}}

---

## Comparison

{{If comparing options. Skip if not applicable.}}

| Factor | {{Option A}} | {{Option B}} | {{Option C}} |
|--------|-------------|-------------|-------------|
| {{F1}} | {{val}} | {{val}} | {{val}} |

---

## Recommendation

**{{One-sentence recommendation}}**

{{1-2 paragraphs with reasoning, referencing specific findings with links.}}

**Caveats:** {{important assumptions}}

**Next steps:**
1. {{action}}
2. {{action}}

---

## Sources

{{Numbered list. Every URL that appears in the report, with what was used from it.}}

1. [{{Title}}]({{URL}}) — {{what data was extracted}}
2. [{{Title}}]({{URL}}) — {{what data was extracted}}
...

---

## Appendix: Evidence Chain

<details>
<summary>Raw research data ({{BEAD_COUNT}} beads)</summary>

### {{Thread Title}}

**{{Bead question}}** (bead: `{{bead_id}}`) — {{status}}
- Answer: {{answer field}}
- Source: [{{domain}}]({{sources[0].url}})
- Quote: "{{sources[0].quote}}"
- Confidence: {{high/medium/low}}
- Validated: {{yes/no}} — {{verdict if yes}} (validation bead: `{{validation_bead_id}}`)
- Contradictions: {{any contradictions found, or "None"}}

</details>
```

---

## CSV Template

For data-heavy research, produce a CSV alongside the markdown report.

**Required columns:**
```
Bead_ID,{{domain columns}},Source_URL,Source_Quote,Verified,Commentary
```

- `Bead_ID`: The research bead that produced this finding (provenance tracking)
- `Source_URL`: At least one URL per data row — no exceptions
- `Source_Quote`: The key quote supporting that row's data
- `Verified`: `✓` (confirmed), `~` (corrected), `✗` (refuted/dropped), `?` (unverified)
- `Commentary`: The "so what" from a business perspective

**Rules for CSV:**
- Every data row MUST have Bead_ID, Source_URL, Source_Quote — no exceptions
- Write the header row FIRST, then append rows incrementally after each research batch
- If a state/item has no program, Source_URL should point to the source confirming no program exists
- Corrected values during validation should be noted in Commentary: "Corrected from X to Y during validation"

---

## Adaptation by Research Type

**Comparison research** (neighborhoods, vendors): Emphasize Comparison table. Lead exec summary with ranking.

**Investigative research** (why X happened): Skip Comparison. Structure Findings by causal chain.

**Data collection** (50-state survey): CSV is the primary output. Report summarizes patterns and highlights. Write CSV incrementally.

**Decision research** (should we do X): Pros/cons structure. Recommendation section is most important.

## Tone

- **Direct and honest.** State findings confidently but flag uncertainty.
- **Data-driven.** Every claim links to its source.
- **Readable.** Write for a smart non-expert.
- **Actionable.** End with concrete next steps.
