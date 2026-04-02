#!/usr/bin/env bash
# Sherlock V2 — Environment Setup
# Checks for beads CLI, creates ~/.sherlock/, verifies permissions.
set -euo pipefail

SHERLOCK_HOME="${HOME}/.sherlock"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Check and install beads ---
if ! command -v bd &>/dev/null; then
    echo -e "${YELLOW}Beads CLI (bd) not found. Installing...${NC}"
    if command -v brew &>/dev/null; then
        brew install beads 2>&1 && echo -e "${GREEN}Beads installed via Homebrew.${NC}"
    elif command -v npm &>/dev/null; then
        npm install -g @beads/bd 2>&1 && echo -e "${GREEN}Beads installed via npm.${NC}"
    else
        echo -e "${RED}Cannot install beads. Install manually: brew install beads${NC}"
        exit 1
    fi
fi

if ! command -v bd &>/dev/null; then
    echo -e "${RED}Beads CLI still not found after install attempt.${NC}"
    exit 1
fi

echo -e "${GREEN}bd: $(which bd)${NC}"

# --- Create directories ---
mkdir -p "${SHERLOCK_HOME}/sessions"
echo -e "${GREEN}Sessions: ${SHERLOCK_HOME}/sessions/${NC}"

# --- Create default config if missing ---
if [ ! -f "${SHERLOCK_HOME}/config.yaml" ]; then
    cat > "${SHERLOCK_HOME}/config.yaml" << 'YAML'
# Sherlock V2 Configuration
defaults:
  researcher_count: 4
  bead_budget: 50
  depth_limit: 4
  convergence_threshold: 0.8
  researcher_timeout: 180

models:
  conductor: opus
  researcher: haiku

cost:
  show_in_dashboard: true
  opus_input_per_mtok: 15.00
  opus_output_per_mtok: 75.00
  haiku_input_per_mtok: 0.80
  haiku_output_per_mtok: 4.00

report:
  format: markdown
  include_sources: true
  include_methodology: true
  include_raw_data: true

google_docs:
  auto_push: false
YAML
    echo -e "${GREEN}Config: ${SHERLOCK_HOME}/config.yaml${NC}"
fi

echo -e "${GREEN}Sherlock environment ready.${NC}"
