# Sherlock V2

Deep research agent for Claude Code. Decomposes complex questions into a dependency graph, researches them in parallel, validates every finding, and produces cited reports.

## Install

```bash
# Add the marketplace
/plugin marketplace add trilogy-group/cc-skills-sherlock

# Install the plugin
/plugin install sherlock@sherlock-plugins
```

Or for local development:

```bash
claude --plugin-dir /path/to/cc-skills-sherlock
```

## Usage

```bash
# Start a new research session
/sherlock "What are the best neighborhoods in Austin for families under $600k?"

# Resume a previous session
/sherlock --resume

# List all sessions
/sherlock --list

# Regenerate report from existing research
/sherlock --report <session-id>

# Re-export updated report to Google Docs/Sheets
/sherlock --update-export <session-id>
```

## How It Works

1. **REFINE** — 2-3 clarifying questions to sharpen your goal
2. **PLAN** — Decomposes into a [beads](https://github.com/gastownhall/beads) dependency graph with real dependencies (`bd dep add`)
3. **EXECUTE** — Dispatches parallel researcher subagents (batch size from config)
4. **VERIFY** — Creates validation beads for every claim, dispatches validators in parallel
5. **REPORT** — Synthesizes into a cited markdown report + CSV with full provenance

## What's New in V2.1

- **Config-driven execution** — `~/.sherlock/config.yaml` controls batch size, model, bead budget, depth limit, and validation mode. No more hardcoded values.
- **Real dependency graph** — Beads are wired with `bd dep add`, `bd ready` finds dispatchable work. Parent beads close when children resolve.
- **Full validation mode** — Every claim gets a validation bead, dispatched in parallel. Not just spot-checks.
- **Structured JSON findings** — Researchers write JSON, not freeform text. Conductor parses reliably.
- **Retry on source failure** — Researchers try alternative sources when URLs return 403/404.
- **Cross-source contradiction detection** — Conflicting data is flagged and surfaced in the report.
- **Incremental CSV** — Data rows written after each batch, not just at the end.
- **Bead-level provenance** — Every CSV row and report claim traces to a specific bead ID.
- **Permission cleanup** — Stale domain-specific `WebFetch(domain:...)` entries are removed automatically.
- **Project-scoped permissions** — Permissions live in `.claude/settings.local.json` per project.
- **Google Workspace update-export** — `--update-export` pushes corrected reports without recreating.
- **Cost warning for Opus researchers** — Config warns before running expensive researcher models.

## Monitoring & Steering Research

### Reviewing beads/tasks in progress

- **Progress display** — After each batch, shows completed beads (with source domains and bead IDs), active researchers, and queued beads (from `bd ready`)
- **Press `t`** in Claude Code to toggle the task list view
- Type **`"summary"`** mid-session for a synthesis of all findings so far
- Type **`"threads"`** to see research threads with completion percentages

### Modifying or refining beads mid-session

- **`"focus on X"`** — Create new beads for X, deprioritize others
- **`"stop looking at Y"`** — Close Y-related beads
- **`"also check Z"`** — Add new research beads (within budget)
- **`"pause"`** / **`"report"`** / **`"quit"`** — Control flow

## What Makes It Different

- **Parallel research** via beads dependency graph — configurable batch size (default 4)
- **Every claim validated** — full validation creates verification beads for all findings
- **Structured provenance** — every CSV row and report claim traces to a bead ID
- **Cross-source contradiction detection** — conflicting data is flagged, not hidden
- **Trust Summary** in every report — honest accounting of validation results
- **Resumable sessions** — walk away and come back days later
- **Steerable** — redirect research mid-session
- **Config-driven** — batch size, model, budget, validation mode all configurable

## Prerequisites

- [beads CLI](https://github.com/gastownhall/beads) (`brew install beads`) — auto-installed on first run, verified working
- Claude Code with Opus model (conductor) and configurable researcher model
- [gogcli](https://gogcli.sh/) (`brew install gogcli`) — optional, enables Google Workspace export

## Additional Tools

### gogcli — Google Workspace Integration

[gogcli](https://gogcli.sh/) is an optional CLI that connects Sherlock to Google Workspace. When configured, Sherlock can export finished reports directly to Google Docs and structured data to Google Sheets — no copy-pasting or file uploads needed.

**What it enables:**
- **Google Docs** — Push completed reports as formatted Google Docs, shareable with your team instantly
- **Google Sheets** — Export CSV data (with source URLs and quotes) as a Google Sheet for collaborative analysis
- **Google Drive** — Search and manage research outputs alongside your other files
- **Gmail** — Send research reports directly via email
- **Calendar** — Reference calendar events for time-sensitive research context

**Install:**

```bash
brew install gogcli
```

**Setup:**

1. Create OAuth credentials in [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → OAuth 2.0 Client ID → Desktop app
2. Download the `client_secret` JSON, then register it:
   ```bash
   gog auth credentials ~/Downloads/client_secret_*.json
   ```
3. Add your Google account:
   ```bash
   gog auth add you@gmail.com
   ```

**Usage with Sherlock:**

After research completes, Sherlock will offer to push the report to Google Docs. You can also export or update any session:

```bash
/sherlock --export <session-id> --format docs
/sherlock --export <session-id> --format sheets
/sherlock --update-export <session-id>
```

To enable auto-export on every report, set `google.auto_push: true` in `~/.sherlock/config.yaml`.

## Permissions

Permissions are **project-scoped** via `.claude/settings.local.json`. The plugin ships with `settings.json` that grants blanket `WebSearch` and `WebFetch` permissions. On first run, Sherlock checks for these in the current project and offers to set them up. Stale domain-specific `WebFetch(domain:...)` entries from previous sessions are automatically cleaned up.

## Output

Reports are saved to `~/.sherlock/sessions/<id>/report/`:
- `report.md` — Full cited report with Trust Summary and evidence chain
- `data.csv` — Structured data with `Bead_ID`, `Source_URL`, `Source_Quote`, `Verified` columns (written incrementally)

## Configuration

Global config at `~/.sherlock/config.yaml` (auto-created on first run):

```yaml
defaults:
  researcher_count: 4       # parallel subagents per batch
  bead_budget: 50            # max research questions
  depth_limit: 4             # max decomposition depth
  validation_mode: full      # "full" = validate every claim, "spot-check" = 5-10 critical

models:
  conductor: opus            # always opus
  researcher: haiku          # haiku | sonnet | opus (WARNING: opus is 20-50x more expensive)

google:
  account: ""                # Google account for gogcli
  auto_push: false           # auto-export on completion
  export_format: docs        # docs | sheets | both
```

## Plugin Structure

```
.claude-plugin/
  plugin.json              # Plugin manifest
  marketplace.json         # Marketplace catalog
settings.json              # Bundled permissions (WebSearch, WebFetch, beads, python3)
skills/sherlock/
  SKILL.md                 # Main skill entry point (config loading, permission checks)
  conductor.md             # Conductor protocol (plan, execute, verify, report)
  researcher.md            # Researcher + validator subagent templates
  verification.md          # Beads-based validation protocol
  report-template.md       # Report + CSV output templates
  scripts/setup.sh         # Auto-install beads + verify + create ~/.sherlock/
```
