#!/usr/bin/env bash
# setup-all.sh — One-shot bootstrap for Part 3.
#
# Runs every script in order. Stops on the first failure.
# Intended for fresh machines or for resetting the demo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf "\033[1;32m[setup-all]\033[0m %s\n" "$*"; }

log "Step 1/4 — install tooling"
"${SCRIPT_DIR}/install.sh"

log "Step 2/4 — create k3d cluster"
"${SCRIPT_DIR}/create-cluster.sh"

log "Step 3/4 — install Argo CD"
"${SCRIPT_DIR}/setup-argocd.sh"

log "Step 4/4 — register the Argo CD Application"
"${SCRIPT_DIR}/apply-app.sh"

log "Done. See README for next steps."
