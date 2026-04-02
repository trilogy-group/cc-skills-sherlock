# Sherlock V2 — Deep Research Engine for Claude Code

## Vision

Sherlock V2 is a **Claude Code skill** that turns Claude into a deep research agent. You describe what you want to know, and Sherlock autonomously builds a dependency graph of questions, researches them in parallel using subagents, and synthesizes a polished report — all while letting you steer, redirect, and interrogate the process from your terminal.

The core insight: **research is a graph, not a conversation.** A complex question decomposes into sub-questions with dependencies between them. Sherlock makes this graph explicit (via [beads](https://github.com/gastownhall/beads)), executes it with massive parallelism, and gives you a terminal UX that makes the invisible work visible and steerable.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Claude Code Skill                   │
│                  `/sherlock <goal>`                   │
├─────────────────────────────────────────────────────┤
│                                                      │
│   ┌───────────┐    ┌──────────┐    ┌─────────────┐  │
│   │ Conductor │───▶│  Beads   │◀───│  Researcher │  │
│   │ (Planner) │    │  Graph   │    │  Subagents  │  │
│   └───────────┘    └──────────┘    └─────────────┘  │
│         │                │               │           │
│         ▼                ▼               ▼           │
│   ┌───────────┐    ┌──────────┐    ┌─────────────┐  │
│   │  Terminal  │    │ Session  │    │ MCP / Tools │  │
│   │    UX      │    │ Storage  │    │ (any configured)│
│   └───────────┘    └──────────┘    └─────────────┘  │
│                          │                           │
│                          ▼                           │
│                   ┌──────────┐                       │
│                   │  Report  │                       │
│                   │ (md/gdoc)│                       │
│                   └──────────┘                       │
└─────────────────────────────────────────────────────┘
```

### Components

| Component | Role |
|---|---|
| **Conductor** | The main Claude instance. Decomposes the goal, manages the beads graph, synthesizes findings, talks to the user. Never does research itself. |
| **Beads Graph** | The dependency-aware task graph (via `bd` CLI). Each bead is a single answerable research question. Tracks status, dependencies, findings, and lineage. |
| **Researcher Subagents** | Claude Code `Agent` instances that pick up ready beads (`bd ready`), research them using available tools, and write findings back. Multiple run in parallel. |
| **Terminal UX** | The interactive layer — a status dashboard and conversational interface the user toggles between. |
| **Session Storage** | Beads' embedded Dolt DB, persisted at `~/.sherlock/sessions/<id>/`. Enables resume across days/weeks. |
| **Report Generator** | Synthesizes all findings into a structured document (local markdown or Google Docs). |

---

## Beads as the Research Graph

Every research session is a beads database. The mapping:

| Beads Concept | Sherlock Concept |
|---|---|
| Epic (`bd-xxxx`) | The top-level research goal |
| Task (`bd-xxxx.1`) | A major research thread / sub-question |
| Sub-task (`bd-xxxx.1.1`) | An atomic, answerable question (leaf node) |
| `blocks` dependency | "I need this answer before I can answer that" |
| `relates_to` link | Cross-references between findings |
| `replies_to` link | Follow-up questions spawned from findings |
| Task status | `open` → `in_progress` → `resolved` / `rejected` |
| Task body | The question + context |
| Task comments | Findings, sources, evidence |

### Leaf Node Granularity Rule

A bead is a valid leaf node if and only if:

1. **It asks a single, specific question** (not compound — no "and" joining two distinct questions)
2. **It can be answered with a single research action** (one web search + reading results, one API call, one document scan)
3. **The answer is verifiable** — the researcher can determine if the answer is sufficient without needing more context
4. **It does not duplicate an existing bead** — before creating, the conductor searches existing beads for semantic overlap

The conductor enforces this via a **decomposition check**: after generating sub-beads, it reviews each one against these criteria. Any bead that fails gets decomposed further or merged with a duplicate.

### Loop Prevention

The V1 infinite loop problem is solved structurally:

1. **Duplicate detection**: Before creating a bead, semantic similarity check against all existing beads. If >80% similar, link to existing bead instead of creating new.
2. **Depth limit**: Maximum graph depth of 4 levels (configurable). At depth 4, the bead MUST be answerable directly — no further decomposition allowed.
3. **Bead budget**: Each session has a maximum bead count (default: 50, configurable). The conductor must prioritize which questions are worth researching within the budget.
4. **Staleness detection**: If a bead has been `in_progress` for >5 minutes with no findings written, it's marked stale and the conductor reassesses whether it's answerable.
5. **Convergence check**: After every batch of resolved beads, the conductor asks: "Do I have enough information to answer the original goal?" If yes, stop expanding — start synthesizing.

---

## The UX — In Detail

This is a Claude Code skill, so the entire UX lives in the terminal. But "terminal" doesn't mean "boring." The goal is an experience that feels like having a brilliant research team working for you, with a window into their work.

### Invocation

```
/sherlock "What are the best neighborhoods in Austin TX for families 
          with kids under 5, considering schools, parks, safety, 
          and home prices under $600k?"
```

Or with context:

```
/sherlock "Analyze whether we should migrate from DynamoDB to 
          PostgreSQL for our user service" --context ./docs/architecture.md
```

Or to resume:

```
/sherlock --resume          # lists recent sessions
/sherlock --resume abc123   # resumes specific session
```

### Phase 1: Goal Refinement (Interactive)

Before any research begins, the conductor has a brief conversation to sharpen the goal. This is NOT the V1 "fill in two boxes" pattern. It's a natural dialogue:

```
╭─ sherlock ──────────────────────────────────────────────╮
│                                                          │
│  I'd like to research neighborhoods in Austin for you.   │
│  A few things that would help me focus:                  │
│                                                          │
│  1. Are you looking to buy or rent?                      │
│  2. Do you have a commute destination (downtown, etc.)?  │
│  3. Any neighborhoods you've already considered or        │
│     ruled out?                                           │
│                                                          │
│  Or say "go" and I'll start with what I have.            │
│                                                          │
╰──────────────────────────────────────────────────────────╯
```

The user can answer, add more context, or just say "go." The conductor synthesizes this into:

```
╭─ sherlock ──────────────────────────────────────────────╮
│                                                          │
│  ✓ Goal locked:                                          │
│                                                          │
│  "Identify the top 3-5 neighborhoods in Austin, TX for   │
│  a family buying a home (<$600k) with kids under 5,      │
│  ranked by: school quality, park access, safety stats,   │
│  and commute to downtown."                               │
│                                                          │
│  I'll produce a comparison report with a recommendation. │
│                                                          │
│  Starting research...                                    │
│                                                          │
╰──────────────────────────────────────────────────────────╯
```

### Phase 2: Research Execution (The Dashboard)

Once research begins, the terminal switches to a **live status view** — a compact, information-dense dashboard that updates in real-time. This is the default view during active research.

```
╭─ sherlock ──── 12 min ── $0.38 so far ── 23/42 beads ──╮
│                                                          │
│  Austin Family Neighborhoods                  ⏳ Active  │
│                                                          │
│  Progress ████████████░░░░░░░░  23/42 beads resolved     │
│                                                          │
│  ▸ Active now (3 researchers)                            │
│    ◉ School ratings for Circle C Ranch       ⟳ 0:34      │
│    ◉ Crime stats for Mueller neighborhood    ⟳ 1:12      │
│    ◉ Park inventory within 1mi of Crestview  ⟳ 0:08      │
│                                                          │
│  ▸ Recently completed                                    │
│    ✓ Median home prices in Cedar Park         $485k      │
│    ✓ Elementary school ratings in Brentwood   8.2/10     │
│    ✓ Average commute from Circle C to downtown 28 min    │
│    ✓ Zillow listings under $600k in Mueller   14 found   │
│                                                          │
│  ▸ Queued (6 beads ready)                                │
│    ○ HOA fees in Circle C Ranch                          │
│    ○ Daycare availability near Mueller                   │
│    ○ Flood zone status for Crestview lots                │
│    ┈ 3 more                                              │
│                                                          │
│  ▸ Key findings so far                                   │
│    • Mueller and Brentwood emerge as top contenders —    │
│      both have walkable parks, strong schools, and       │
│      listings under budget.                              │
│    • Circle C has the best schools but longest commute.  │
│                                                          │
│  ─────────────────────────────────────────────────────── │
│  [s] summary  [t] threads  [d] drill-in  [c] chat       │
│  [p] pause    [r] report   [q] detach                    │
╰──────────────────────────────────────────────────────────╯
```

#### Dashboard Elements

| Element | Purpose |
|---|---|
| **Progress bar** | Total beads resolved / total beads (grows as new beads are discovered). Gives a sense of overall completion. |
| **Active now** | What the parallel researcher subagents are currently working on. Shows elapsed time per bead. The user can see work happening. |
| **Recently completed** | Last N resolved beads with one-line findings. Scrollable. Gives the user a stream of incoming data. |
| **Queued** | Beads that are ready (dependencies met) but waiting for a free researcher. Shows what's coming next. |
| **Key findings** | The conductor periodically synthesizes what's been learned so far into 2-3 bullet points. This is the "interim answer" from V1, but presented as evolving insight rather than a static placeholder. |
| **Hotkeys** | Single-key actions — no typing commands, just press a key. |

#### Hotkey Actions

| Key | Action |
|---|---|
| `s` | **Summary** — Conductor gives a natural language summary of everything found so far, confidence level, and what's still unknown. |
| `t` | **Threads** — Shows the major research threads (top-level beads) as a compact list with completion %. Like a table of contents for the research. |
| `d` | **Drill-in** — Prompts for a thread or bead ID, then shows the full detail: question, findings, sources, child beads. This replaces V1's node detail panel. |
| `c` | **Chat** — Drops into conversational mode (see below). |
| `p` | **Pause** — Pauses all researcher subagents. Research can be resumed. Good for reviewing before more work is done. |
| `r` | **Report** — Generates the final report from current findings (even if research isn't complete). |
| `q` | **Detach** — Leaves the dashboard but research continues in the background. Come back with `/sherlock --resume`. |

### Phase 2b: Chat Mode (Steering)

Pressing `c` from the dashboard drops into a conversational interface. The dashboard collapses to a minimal status bar at the top, and you can talk to the conductor:

```
╭─ sherlock ── 23/42 beads ── 3 active ── 14 min ────────╮
│                                                          │
│  You: I'm less interested in Cedar Park — it's too far   │
│       from downtown. Focus more on the central           │
│       neighborhoods.                                     │
│                                                          │
│  Sherlock: Got it. I'll:                                  │
│    • Reject the 4 remaining Cedar Park beads             │
│    • Add beads for central neighborhoods I haven't       │
│      covered yet: Hyde Park, North Loop, Cherrywood      │
│    • Reprioritize Mueller and Brentwood beads higher     │
│                                                          │
│  [Rejected 4 beads · Created 8 new beads · Reprioritized │
│   3 beads]                                               │
│                                                          │
│  Research is continuing with the new direction.           │
│  Press ESC to return to dashboard.                       │
│                                                          │
╰──────────────────────────────────────────────────────────╯
```

**What you can do in chat mode:**

- **Redirect**: "Stop looking at X, focus on Y"
- **Add context**: "Actually, my wife works in South Austin, so commute there matters too"
- **Ask questions**: "What have you found about school ratings so far?"
- **Challenge findings**: "That crime stat seems wrong — can you double-check with a different source?"
- **Add constraints**: "Also check if any of these neighborhoods have Montessori schools"
- **Request synthesis**: "Compare Mueller and Brentwood head-to-head"

Each user input in chat mode triggers the conductor to update the beads graph accordingly — rejecting beads, creating new ones, reprioritizing, or spawning targeted sub-research.

### Phase 3: Report Generation

When the user presses `r`, or when the conductor determines sufficient convergence:

```
╭─ sherlock ──────────────────────────────────────────────╮
│                                                          │
│  Research complete. 38/42 beads resolved (4 rejected).   │
│                                                          │
│  Generating report...                                    │
│                                                          │
│  ✓ Report saved: ~/.sherlock/reports/austin-neighborhoods │
│    ├── report.md          (full report)                  │
│    ├── comparison.md      (neighborhood comparison table)│
│    └── sources.md         (all sources cited)            │
│                                                          │
│  Push to Google Docs? [y/n]                              │
│                                                          │
╰──────────────────────────────────────────────────────────╯
```

#### Report Structure

The report is not a dump of bead findings. The conductor **synthesizes** — it reads all resolved beads and writes a coherent document:

```markdown
# Austin Family Neighborhoods: Research Report

## Executive Summary
[2-3 paragraph synthesis with clear recommendation]

## Methodology  
[What was researched, how many sources, what tools were used]

## Neighborhood Profiles
### 1. Mueller
[Narrative synthesis of all Mueller beads — schools, parks, 
 safety, prices, commute, pros/cons]

### 2. Brentwood
[Same structure]

### 3. Circle C Ranch
[Same structure]

## Comparison Matrix
| Factor        | Mueller | Brentwood | Circle C |
|---------------|---------|-----------|----------|
| Avg Price     | $520k   | $545k     | $480k    |
| School Rating | 7.8     | 8.2       | 9.1      |
| ...           |         |           |          |

## Recommendation
[Clear recommendation with reasoning]

## Sources
[Numbered list of all sources with URLs]

## Appendix: Raw Research Data
[Collapsed bead findings for anyone who wants the details]
```

**Google Docs export**: If the user says yes, Sherlock uses the Google Docs MCP tool (if configured) to create and format the document, then returns a shareable link.

**Spreadsheet export**: For data-heavy research (comparing vendors, analyzing metrics), the user can request a spreadsheet format. Sherlock generates a CSV or uses Google Sheets MCP.

---

## Parallel Execution Model

This is the core improvement over V1. The system uses beads' `bd ready` + `bd update --claim` to enable safe, parallel research.

### How It Works

```
Conductor (main Claude instance)
    │
    ├── Decomposes goal into beads
    ├── Sets dependencies between beads
    │
    │   ┌─────────────────────────────────────┐
    │   │         Researcher Pool              │
    │   │                                      │
    │   │  Agent 1: bd ready → claim → research│
    │   │  Agent 2: bd ready → claim → research│
    │   │  Agent 3: bd ready → claim → research│
    │   │  Agent 4: bd ready → claim → research│
    │   │                                      │
    │   │  (pool size: configurable, default 4)│
    │   └─────────────────────────────────────┘
    │
    ├── Monitors graph: convergence? new beads needed?
    ├── Synthesizes interim findings
    └── Generates final report
```

### Conductor Loop

The conductor runs a continuous loop:

```
1. Check graph state (bd ready, bd list --status=resolved)
2. If new findings exist → synthesize, check convergence
3. If convergence reached → stop, generate report
4. If gaps identified → create new beads, set dependencies
5. If stale beads → reassign or decompose further
6. Spawn/maintain researcher pool at target parallelism
7. Sleep briefly, repeat
```

### Researcher Agent Lifecycle

Each researcher subagent is a Claude Code `Agent` instance running on **Haiku** (fast, cheap, high-volume). Its prompt:

```
You are a Sherlock researcher. Your job:
1. Run `bd ready --json` to find available beads
2. Pick one and claim it: `bd update <id> --status=in_progress --claim`
3. Research the question using available tools (web search, MCP tools, etc.)
4. Write findings as a comment: `bd comment <id> "findings..."`
5. Resolve: `bd update <id> --status=resolved`
6. Repeat from step 1

Rules:
- Answer ONLY the specific question in the bead
- Cite sources with URLs
- If you can't find the answer, mark as rejected with reason
- If the question needs decomposition, DON'T decompose — 
  mark as rejected with note "needs decomposition" (the conductor handles this)
- Max 3 minutes per bead. If stuck, move on.
```

Researchers are stateless and interchangeable — any researcher can pick up any ready bead. This is how beads gives us safe parallelism without coordination overhead.

---

## Session Management

### Storage Layout

```
~/.sherlock/
├── config.yaml              # global config
├── sessions/
│   ├── abc123/
│   │   ├── .beads/          # beads database (Dolt)
│   │   ├── meta.json        # session metadata
│   │   └── report/          # generated artifacts
│   ├── def456/
│   │   ├── .beads/
│   │   ├── meta.json
│   │   └── report/
│   └── ...
└── reports/                 # symlinks to latest reports
```

### `meta.json`

```json
{
  "id": "abc123",
  "goal": "Best family neighborhoods in Austin TX...",
  "refined_goal": "Identify the top 3-5 neighborhoods...",
  "status": "active|paused|completed",
  "created_at": "2026-04-02T10:00:00Z",
  "updated_at": "2026-04-02T10:45:00Z",
  "bead_count": 42,
  "resolved_count": 38,
  "rejected_count": 4,
  "researcher_count": 4,
  "depth_limit": 4,
  "bead_budget": 50,
  "tags": ["real-estate", "austin"]
}
```

### Session Commands

| Command | Action |
|---|---|
| `/sherlock "goal"` | Start new research session |
| `/sherlock --resume` | List all sessions, pick one to resume |
| `/sherlock --resume <id>` | Resume specific session |
| `/sherlock --list` | List all sessions with status |
| `/sherlock --report <id>` | Regenerate report for a completed session |
| `/sherlock --delete <id>` | Delete a session and its data |
| `/sherlock --export <id> --format gdoc` | Export to Google Docs |
| `/sherlock --export <id> --format sheets` | Export to Google Sheets |

---

## Configuration

### `~/.sherlock/config.yaml`

```yaml
# Research behavior
defaults:
  researcher_count: 4        # parallel subagents
  bead_budget: 50            # max beads per session
  depth_limit: 4             # max graph depth
  convergence_threshold: 0.8 # % of beads resolved before synthesis
  researcher_timeout: 180    # seconds per bead before marking stale

# Model routing
models:
  conductor: opus            # goal refinement, decomposition, synthesis, reports
  researcher: haiku          # leaf node research (high volume, lower cost)
  # Override per-session with: /sherlock --researcher-model sonnet

# Cost tracking (uses published Anthropic API pricing)
cost:
  show_in_dashboard: true    # always show running cost
  opus_input_per_mtok: 15.00
  opus_output_per_mtok: 75.00
  haiku_input_per_mtok: 0.80
  haiku_output_per_mtok: 4.00

# Report preferences  
report:
  format: markdown           # markdown | html
  include_sources: true
  include_methodology: true
  include_raw_data: false    # include bead-level findings in appendix
  
# Google Docs integration (uses configured MCP)
google_docs:
  auto_push: false           # prompt before pushing
  folder_id: "..."           # Google Drive folder for reports

# Tool preferences
tools:
  # Sherlock will automatically use ALL configured MCP servers 
  # and Claude Code tools. These settings let you add hints about
  # which tools to prefer for certain question types.
  preferences:
    - pattern: "real estate|home price|listing"
      prefer: ["mcp__stratos__process_real_estate_listings"]
    - pattern: "aws|ec2|s3|lambda"  
      prefer: ["mcp__stratos__*"]  # example
```

### Tool Discovery

Sherlock doesn't maintain its own tool registry. It uses **whatever MCP servers and tools are configured in the user's Claude Code environment.** The conductor inspects available tools at session start and instructs researchers on what's available.

This means:
- Add a new MCP server to Claude Code → Sherlock can use it immediately
- No separate "extension" system to maintain
- Tool preferences in config are just hints, not requirements

---

## The Bead Lifecycle — Detailed Example

Let's trace a real example to make the system concrete.

**Goal**: "Should we migrate from DynamoDB to PostgreSQL for our user service?"

### Step 1: Conductor Decomposes

```
bd-a1f2  (epic) "Should we migrate from DynamoDB to PostgreSQL?"
├── bd-a1f2.1  "What are the current DynamoDB usage patterns?"
│   ├── bd-a1f2.1.1  "What is the read/write ratio on the users table?"
│   ├── bd-a1f2.1.2  "What query patterns are used most frequently?"
│   └── bd-a1f2.1.3  "What is the current monthly DynamoDB cost?"
├── bd-a1f2.2  "What would PostgreSQL look like for this workload?"
│   ├── bd-a1f2.2.1  "How would the data model change for relational?"
│   ├── bd-a1f2.2.2  "What PostgreSQL hosting options match our scale?"
│   └── bd-a1f2.2.3  "Estimated PostgreSQL cost for equivalent workload?"
├── bd-a1f2.3  "What are the migration risks?"
│   blocks: [bd-a1f2.1, bd-a1f2.2]  ← needs findings from both
│   ├── bd-a1f2.3.1  "What data consistency risks exist during migration?"
│   ├── bd-a1f2.3.2  "What application code changes are needed?"
│   └── bd-a1f2.3.3  "What is the estimated migration timeline?"
└── bd-a1f2.4  "Comparison and recommendation"
    blocks: [bd-a1f2.1, bd-a1f2.2, bd-a1f2.3]  ← needs everything
```

### Step 2: Researchers Execute in Parallel

Beads `bd-a1f2.1.1`, `bd-a1f2.1.2`, `bd-a1f2.1.3`, `bd-a1f2.2.1`, `bd-a1f2.2.2`, `bd-a1f2.2.3` all have no blockers → all 6 are immediately ready. With 4 researchers, 4 start immediately, 2 queue.

### Step 3: Dependencies Unlock

Once all `.1.x` beads resolve → `bd-a1f2.1` auto-resolves (conductor synthesizes child findings) → `bd-a1f2.3` becomes unblocked → its children become ready.

### Step 4: Convergence

Once `bd-a1f2.1`, `bd-a1f2.2`, `bd-a1f2.3` are all resolved, `bd-a1f2.4` becomes ready. The conductor handles this one directly (it's synthesis, not research). It reads all findings and produces the recommendation.

---

## Edge Cases & Error Handling

### Researcher Fails to Find Answer

Bead marked `rejected` with reason. Conductor decides:
- **Rephrase and retry**: Create a new bead with a rephrased question
- **Skip**: Mark as non-critical and note the gap in the report
- **Escalate**: In chat mode, ask the user "I couldn't find X — do you have a source, or should I skip it?"

### User Provides Contradicting Direction

If the user's steering conflicts with existing findings:
- Conductor acknowledges the conflict explicitly
- Asks: "My research found X, but you're saying Y. Should I discard that finding and research from your premise?"
- Doesn't silently overwrite findings

### Research Takes Too Long

- Dashboard shows elapsed time prominently
- Conductor proactively suggests: "I've been running for 30 minutes and have covered the major threads. Want me to wrap up with what I have, or keep going on the remaining 8 beads?"
- User can always press `r` for early report

### Tool/MCP Server Down

- Researcher logs the failure on the bead
- Conductor reassigns to a different researcher (maybe the tool was rate-limited)
- After 2 failures, bead is marked as blocked with reason, surfaced to user

---

## Implementation Plan

### Phase 1: Core Skill (MVP)

1. **Skill registration** — `/sherlock` command in Claude Code
2. **Beads integration** — Install `bd` CLI, manage session databases
3. **Conductor logic** — Goal refinement, decomposition, convergence checking
4. **Single researcher** — One subagent at a time (validates the model before parallelism)
5. **Basic terminal output** — Streaming text updates, no fancy dashboard yet
6. **Local markdown report** — Generated at completion
7. **Session persistence** — Resume sessions via `--resume`

### Phase 2: Parallel + Dashboard

8. **Researcher pool** — Multiple parallel subagents via Claude Code Agent tool
9. **Live dashboard** — Real-time terminal UI with status, progress, findings
10. **Hotkey system** — `s/t/d/c/p/r/q` navigation
11. **Chat mode** — Conversational steering mid-research
12. **Duplicate detection** — Semantic similarity check before bead creation

### Phase 3: Export + Polish

13. **Google Docs export** — Via MCP tool
14. **Google Sheets export** — For tabular data
15. **Tool preference hints** — Config-based tool routing
16. **Session management CLI** — `--list`, `--delete`, `--export`
17. **Compaction** — Use beads' compaction for very large research sessions

---

## Trust & Verification

Sherlock V2 treats trust as a first-class feature. Every report includes a verifiable evidence chain: **Report Claim → Inline Citation → Bead Finding → Source URL → Direct Quote from Page.**

### Three-Tier Fact Classification

| Tier | Marker | Meaning | Requirement |
|------|--------|---------|-------------|
| Verified | ✓ | Data extracted directly from a fetched page | URL + WebFetch + direct quote |
| Corroborated | ~ | Multiple sources agree | 2+ URLs with quotes, both fetched |
| Inference | ⚠ | AI conclusion from verified facts | References to supporting Tier 1/2 beads |
| Unsourced | ✗ | **Not allowed in reports** | — |

### Anti-Hallucination Guardrails

1. **Researchers must WebFetch every page they cite.** Search snippets are not evidence.
2. **Every finding includes a direct quote** from the source page. No quote = no citation.
3. **Conductor never adds facts during synthesis.** Report contains ONLY what's in bead findings.
4. **Training data is never a source.** Only information found through tools in the current session.
5. **Conductor spot-checks 2-3 critical claims** by re-fetching URLs before finalizing the report.
6. **Every report has a Trust Summary** showing the breakdown of Tier 1/2/3 claims.
7. **Full evidence chain in appendix.** Users can audit any claim back to source.

See `verification.md` for the complete protocol.

---

## What Makes This Better Than V1

| V1 Problem | V2 Solution |
|---|---|
| Bad UX — static tree view, detail panel | Live dashboard + conversational chat mode in terminal |
| Not enough parallelism | Researcher pool with beads-based work distribution |
| Task duplication / infinite loops | Duplicate detection, depth limits, bead budget, convergence checks |
| No way to resume | Persistent sessions via beads Dolt DB |
| Poor granularity — tasks too big or too small | Strict leaf node criteria + conductor validation |
| Separate tool from workflow | Claude Code skill — lives where you already work |
| Manual tool configuration | Uses all configured MCP servers automatically |
| Interim answer is useless placeholder | Rolling synthesis that updates as findings come in |
| Can't steer mid-research | Chat mode with graph mutation (reject, reprioritize, create beads) |
| Report is afterthought | First-class synthesized report with export to Docs/Sheets |

---

## Decisions

1. **Beads installation**: Auto-install `bd` CLI on first `/sherlock` run. Check for `bd` in PATH, if missing, install via the appropriate method (Go binary or npm package). No manual prerequisite.

2. **Model routing**: **Opus** for the conductor (goal refinement, decomposition, convergence, synthesis, report generation) and **Haiku** for researcher subagents (leaf node research). This optimizes cost — leaf research is high-volume, formulaic work; synthesis requires reasoning depth.

3. **Cost visibility**: No hard token budget. Instead, show **running cost** in the dashboard header so the user can make informed decisions. Easy termination via `Ctrl+C` or `q` (detach) or `p` (pause). The dashboard shows:
   - Elapsed time
   - Beads resolved / total
   - Estimated cost so far (based on token counts from subagent responses)
   - The user is always one keypress away from stopping.

4. **Collaborative research (future)**: Deferred but architecturally possible. The path:
   - Beads supports **server mode** (`dolt sql-server`) for concurrent multi-writer access
   - Two remote users would need a shared Dolt remote (DoltHub or self-hosted)
   - Each user's local beads instance syncs via `bd push` / `bd pull` (like git)
   - The conductor on each machine would see the other's work via the shared graph
   - **Blocker**: Claude Code skills are local-only today. This would require either (a) a shared Dolt server both users connect to, or (b) syncing the `.beads/` directory via DoltHub remotes. Option (b) is more practical — beads already supports `dolt remote` and merge. This would be a V3 feature.

5. **Research templates**: Deferred to V3.

---

## Cost Display

The dashboard header always shows running cost:

```
╭─ sherlock ──── 14 min ── $0.42 so far ── 23/42 beads ──╮
```

Cost is calculated from:
- **Conductor tokens**: Tracked from the main Claude instance (Opus pricing)
- **Researcher tokens**: Each subagent reports token usage on completion (Haiku pricing)
- Pricing uses published Anthropic API rates, updated in config

When the user pauses or enters chat mode, cost display persists:

```
╭─ sherlock ── PAUSED ── $0.67 total ── 31/42 beads ─────╮
│                                                          │
│  Research paused. 31 beads resolved, 11 remaining.       │
│                                                          │
│  [r] resume  [s] summary  [c] chat  [q] generate report │
│                                                          │
╰──────────────────────────────────────────────────────────╯
```

This gives the user full agency over cost without imposing artificial limits.
