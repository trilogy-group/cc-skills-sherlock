# Sherlock V2

Deep research agent for Claude Code. Decomposes complex questions into a dependency graph, researches them in parallel, verifies findings, and produces cited reports.

## Install

```bash
# From a plugin marketplace (once published)
/plugin install sherlock@your-marketplace

# Or test locally
claude --plugin-dir /path/to/sherlock-cc
```

## Usage

```bash
# Start a new research session
/sherlock:sherlock "What are the best neighborhoods in Austin for families under $600k?"

# Resume a previous session
/sherlock:sherlock --resume

# List all sessions
/sherlock:sherlock --list

# Regenerate report from existing research
/sherlock:sherlock --report <session-id>
```

## How It Works

1. **REFINE** — Sherlock asks 2-3 clarifying questions to sharpen your goal
2. **PLAN** — Decomposes into a [beads](https://github.com/gastownhall/beads) dependency graph
3. **EXECUTE** — Dispatches parallel Haiku researcher subagents (4 at a time)
4. **VERIFY** — Conductor spot-checks critical claims by re-fetching source URLs
5. **REPORT** — Synthesizes findings into a cited markdown report + CSV

## What Makes It Different

- **Parallel research** via beads task graph — 4 researchers work simultaneously
- **Every claim has a source URL and direct quote** — traceable evidence chain
- **Conductor spot-checks** critical claims before writing the report
- **Trust Summary** in every report — honest accounting of what was verified
- **Resumable sessions** — walk away and come back days later
- **Steerable** — redirect research mid-session ("stop looking at X, focus on Y")

## Prerequisites

- [beads CLI](https://github.com/gastownhall/beads) (`brew install beads`) — auto-installed on first run
- Claude Code with Opus model (conductor) and Haiku (researchers)

## Permissions

The plugin ships with `settings.json` that grants blanket `WebSearch` and `WebFetch` permissions. This is required — without it, you'll be prompted for every web request (~300-500 per session).

## Output

Reports are saved to `~/.sherlock/sessions/<id>/report/`:
- `report.md` — Full cited report with Trust Summary
- `data.csv` — Structured data with Source_URL and Source_Quote columns

## Configuration

Global config at `~/.sherlock/config.yaml` (auto-created on first run):

```yaml
defaults:
  researcher_count: 4     # parallel subagents
  bead_budget: 50          # max research questions
  depth_limit: 4           # max decomposition depth
models:
  conductor: opus
  researcher: haiku
```

## File Structure

```
.claude-plugin/plugin.json    # Plugin manifest
settings.json                  # Bundled permissions (WebSearch, WebFetch, beads)
skills/sherlock/
  SKILL.md                     # Main skill entry point
  conductor.md                 # Conductor protocol (plan, execute, verify, report)
  researcher.md                # Researcher subagent prompt template
  verification.md              # Trust & verification protocol
  report-template.md           # Report + CSV output templates
  scripts/setup.sh             # Auto-install beads + create ~/.sherlock/
```
