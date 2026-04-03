# Verification Protocol

## The Problem

LLMs hallucinate facts, URLs, statistics, and entire sources. A confident tone doesn't equal accuracy. Sherlock solves this with a layered verification approach and **beads-based validation tasks**.

---

## Layer 1: Researcher Requirements (Built Into Prompt)

Every researcher MUST:
1. **WebFetch every page they cite** — search snippets are not evidence
2. **Include a direct quote** from the source page in the JSON findings
3. **Include the full URL** in the sources array
4. **Never use training data as a source** — only what tools find now
5. **Report honestly** when data can't be found
6. **Retry on 403/404** — try alternative sources before reporting SOURCE_DEAD
7. **Flag contradictions** — if sources disagree, report it in the contradictions field

If a researcher's findings lack a source URL or quote, the conductor **rejects the finding and re-opens the bead**.

---

## Layer 2: Beads-Based Validation (After Research, Before Report)

**Validation is a first-class phase with its own beads.** This replaces the old "conductor spot-checks 5-10 claims" approach.

### Validation modes (set in `~/.sherlock/config.yaml` → `defaults.validation_mode`):

**`full` (default):** Create a validation bead for EVERY resolved research bead. Every claim gets independently verified.

**`spot-check`:** Create validation beads for 5-10 critical claims only. Prioritize:
- Quantitative claims (prices, statistics, ratings, percentages)
- Claims that drive the recommendation
- Low-confidence findings (researcher said confidence: "low" or "medium")
- Single-source findings (only one URL, no corroboration)

### Creating validation beads:

For each claim to validate:

```bash
export BEADS_DIR="$HOME/.sherlock/sessions/$SESSION_ID/.beads"

# Create the validation bead at P3 (deeper than research beads)
bd create "VALIDATE: <claim summary> — verify against <source_url>" -p 3

# Wire it to the epic so report waits for validation
bd dep add $EPIC_ID $VALIDATION_BEAD_ID
```

### Dispatching validators:

Use the **Validation Template** from `researcher.md`. Dispatch in parallel batches of `$BATCH_SIZE`:

```
Agent(
  model: "$RESEARCHER_MODEL",
  description: "Validate: <5-word summary>",
  prompt: <filled validation template>
)
```

Each validator:
1. WebFetches the source URL (or finds an alternative if dead)
2. Checks the page for the claimed data
3. Reports a verdict: CONFIRMED, CORRECTED, REFUTED, SOURCE_DEAD, NOT_ON_PAGE
4. Closes the validation bead with the verdict

### Processing validation results:

| Verdict | Action |
|---------|--------|
| **CONFIRMED** | Mark original bead as `[Validated ✓]`. Keep in report. |
| **CORRECTED** | Update original bead's data with correct values. Flag in CSV `Verified` column as `~`. |
| **REFUTED** | Drop the claim from the report. Note the gap. Create re-research bead if critical. |
| **SOURCE_DEAD** | Validator should have tried alternatives. If still dead, mark as `[Unverified]`. |
| **NOT_ON_PAGE** | Strong hallucination signal. Drop from report. Create re-research bead. |

### Recording the tally:

```
Validated: 35 claims
  Confirmed: 30
  Corrected: 3 (updated in report)
  Refuted: 1 (dropped from report)
  Source dead: 1 (marked [Unverified])
  Not on page: 0
```

This goes directly into the Trust Summary.

---

## Layer 3: Cross-Source Contradiction Detection

**During the EXECUTE phase**, the conductor checks for contradictions after each batch:

1. Scan newly resolved beads for conflicting data with existing findings
2. If found, create a **contradiction resolution bead**:
   ```
   "RESOLVE: <topic> — Source A (<domain>) says X, Source B (<domain>) says Y"
   ```
3. Dispatch a researcher to investigate and determine which is correct (or note the disagreement)
4. The report's Findings section must surface unresolved contradictions:
   ```markdown
   Data varies between sources: [Source A](url) reports X while
   [Source B](url) reports Y. The discrepancy may reflect [explanation].
   ```

---

## Layer 4: Citations in Output

Evidence must be visible WHERE THE USER READS IT — not buried in a database.

### In the report:
```markdown
Mueller's median price is $520,000 ([Zillow](https://zillow.com/mueller-austin)).
```

### In the CSV:
```csv
Bead_ID,State,Program,Amount,...,Source_URL,Source_Quote,Verified,Commentary
abc123-d76,Arizona,ESA,$7500,...,https://azed.gov/esa,"All K-12 eligible",✓,Gold standard
```

### In the progress display:
```
✓ Mueller median price → $520k
  source: zillow.com/mueller-austin [bead: abc123-x1y]
```

### Trust Summary (every report):
Honest accounting of what was and wasn't verified. Shows full validation tally, not just spot-check count.

---

## What This Protocol Does NOT Do

- **It doesn't guarantee 100% accuracy.** Web sources can be wrong, outdated, or biased.
- **It doesn't replace domain expertise.** The user should validate conclusions in their area of expertise.

What it DOES do:
- Makes every claim **traceable** to a specific source AND a specific bead
- Makes the research **auditable** — any claim can be checked by clicking the link or querying the bead
- Makes gaps and uncertainty **transparent** — the user knows what's verified and what's not
- Catches the most dangerous errors — hallucinated URLs, fabricated statistics, dead sources
- In `full` validation mode, **every single claim** is independently verified before it enters the report
