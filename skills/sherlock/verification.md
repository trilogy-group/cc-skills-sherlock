# Verification Protocol

## The Problem

LLMs hallucinate facts, URLs, statistics, and entire sources. A confident tone doesn't equal accuracy. Sherlock solves this with a layered verification approach.

---

## Layer 1: Researcher Requirements (Built Into Prompt)

Every researcher MUST:
1. **WebFetch every page they cite** — search snippets are not evidence
2. **Include a direct quote** from the source page in SOURCE_QUOTE
3. **Include the full URL** in SOURCE_URL
4. **Never use training data as a source** — only what tools find now
5. **Report honestly** when data can't be found

If a researcher's findings lack a SOURCE_URL or SOURCE_QUOTE, the conductor **rejects the finding and re-opens the bead**.

---

## Layer 2: Conductor Spot-Check (Between Research and Report)

After all research beads are resolved, the conductor personally verifies 5-10 critical claims:

### What to spot-check:
1. **Quantitative claims** — prices, statistics, ratings, percentages
2. **Claims driving the recommendation** — the ones that matter most
3. **Low-confidence findings** — researcher said CONFIDENCE: low or medium
4. **Single-source findings** — only one URL, no corroboration

### How to spot-check:
```
For each claim to verify:
1. Read the bead's SOURCE_1_URL
2. WebFetch the URL
3. Search the page content for the quoted text
4. Compare: does the page say what the researcher claimed?
```

### Possible outcomes:
- **CONFIRMED** — Quote found on page, data matches claim
- **CORRECTED** — Data on page differs slightly (e.g., $515k vs $520k). Use the correct number.
- **REFUTED** — Page contradicts the claim. Drop from report.
- **SOURCE_DEAD** — 404 or unreachable. Try to find alternative. Mark [Unverified] if not.
- **NOT_ON_PAGE** — Page loads but data isn't there. Strong hallucination signal. Drop from report.

### Record the tally:
This goes directly into the Trust Summary:
```
Spot-checked: 8 claims
  Confirmed: 6
  Corrected: 1 (updated in report)
  Source dead: 1 (marked [Unverified])
```

---

## Layer 3: Citations in Output

Evidence must be visible WHERE THE USER READS IT — not buried in a database.

### In the report:
```markdown
Mueller's median price is $520,000 ([Zillow](https://zillow.com/mueller-austin)).
```

### In the CSV:
```csv
State,Program,Amount,...,Source_URL,Source_Quote
Arizona,ESA,$10300,...,https://arizonaempowermentscholarship.org/,"All K-12 students eligible"
```

### In the progress display:
```
✓ Mueller median price → $520k
  source: zillow.com/mueller-austin
```

### Trust Summary (every report):
Honest accounting of what was and wasn't verified. If you didn't spot-check, say "0 claims spot-checked."

---

## What This Protocol Does NOT Do

- **It doesn't guarantee 100% accuracy.** Web sources can be wrong, outdated, or biased.
- **It doesn't verify every single claim.** Spot-checking covers 5-10 critical ones.
- **It doesn't replace domain expertise.** The user should validate conclusions in their area of expertise.

What it DOES do:
- Makes every claim **traceable** to a specific source
- Makes the research **auditable** — any claim can be checked by clicking the link
- Makes gaps and uncertainty **transparent** — the user knows what's verified and what's not
- Catches the most dangerous errors — hallucinated URLs, fabricated statistics, dead sources
