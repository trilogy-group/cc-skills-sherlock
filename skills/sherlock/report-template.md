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
| Claims spot-checked by conductor | {{N}} / {{TOTAL}} |
| Spot-check results | {{N}} confirmed, {{N}} corrected, {{N}} failed |
| Unique sources cited | {{N}} |
| Source types | {{e.g. "government (4), primary data (8), media (3)"}} |
| Unverifiable claims | {{N or "None"}} — {{noted in report as [Unverified]}} |

*Every factual claim links to its source. Click any link to verify.*

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
- **Verification:** Conductor spot-checked {{N}} critical claims by re-fetching URLs
- **Limitations:** {{gaps, date ranges, ambiguities}}

---

## Findings

### {{Thread 1 Title}}

{{Narrative synthesis. Every factual claim has an inline hyperlink:

Mueller's median home price is $520,000 ([Zillow](https://zillow.com/mueller-austin)).
The neighborhood has seen 8% YoY price growth ([Redfin](https://redfin.com/...)).
This makes Mueller one of the best values in central Austin [Inference — based on price
data from Zillow and Redfin above].

If sources disagreed:
Crime data varies: Austin PD reports 12/1000 ([APD](https://austintexas.gov/...))
while NeighborhoodScout reports 15/1000 ([NS](https://neighborhoodscout.com/...)).
The gap likely reflects different reporting periods [Inference].}}

### {{Thread 2 Title}}

{{Same structure}}

---

## Comparison

{{If comparing options. Skip if not applicable.}}

| Factor | {{Option A}} | {{Option B}} | {{Option C}} |
|--------|-------------|-------------|-------------|
| {{F1}} | {{val}} | {{val}} | {{val}} |
| {{F2}} | {{val}} | {{val}} | {{val}} |

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

**{{Bead question}}** ({{bead ID}}) — {{status}}
- Answer: {{ANSWER field}}
- Source: [{{domain}}]({{SOURCE_1_URL}})
- Quote: "{{SOURCE_1_QUOTE}}"
- Confidence: {{high/medium/low}}
- Spot-checked: {{yes/no}} — {{result if yes}}

</details>
```

---

## CSV Template

For data-heavy research, produce a CSV alongside the markdown report.

**Required columns:**
```
{{domain columns}},Source_URL,Source_Quote,Commentary
```

Example for the education choice research:
```
State,Program_Name,Type,Amount,Eligibility,Physical_School,Virtual_School,Homeschool_Apps,Supplemental_Apps,Status,Source_URL,Source_Quote,Commentary
Arizona,Empowerment Scholarship Account,ESA,~$10300,Universal - all K-12,Yes,Yes,Yes,Yes,Active,https://arizonaempowermentscholarship.org/,"All K-12 students in Arizona are eligible to receive an ESA",Gold standard ESA. Broadest coverage.
```

**Rules for CSV:**
- Every data row MUST have a Source_URL — no exceptions
- Every data row MUST have a Source_Quote — the key text supporting the data
- If a state/item has no program, Source_URL should point to the source confirming no program exists
- Commentary provides the "so what" from a business perspective

---

## Adaptation by Research Type

**Comparison research** (neighborhoods, vendors): Emphasize Comparison table. Lead exec summary with ranking.

**Investigative research** (why X happened): Skip Comparison. Structure Findings by causal chain.

**Data collection** (50-state survey): CSV is the primary output. Report summarizes patterns and highlights.

**Decision research** (should we do X): Pros/cons structure. Recommendation section is most important.

## Tone

- **Direct and honest.** State findings confidently but flag uncertainty.
- **Data-driven.** Every claim links to its source.
- **Readable.** Write for a smart non-expert.
- **Actionable.** End with concrete next steps.
