#!/usr/bin/env bash
# cleanup.sh — Tear down the K3d cluster created for Part 3.
#
# Safe to re-run; does nothing if the cluster doesn't exist.

set -euo pipefail

CLUSTER_NAME="iot"
log() { printf "\033[1;34m[cleanup]\033[0m %s\n" "$*"; }

if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
  log "Deleting cluster '${CLUSTER_NAME}'..."
  k3d cluster delete "${CLUSTER_NAME}"
else
  log "No cluster named '${CLUSTER_NAME}' to delete."
fi
