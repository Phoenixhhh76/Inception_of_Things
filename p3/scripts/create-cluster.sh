#!/usr/bin/env bash
# create-cluster.sh — Create the K3d cluster used by Part 3.
#
# Idempotent: if a cluster named "iot" already exists, it is reused.
#
# After this script:
#   - kubectl is pointed at the new cluster (k3d-iot-* context)
#   - localhost:8888 and localhost:8080 reach the cluster's loadbalancer

set -euo pipefail

CLUSTER_NAME="iot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../confs/cluster.yaml"

log() { printf "\033[1;34m[cluster]\033[0m %s\n" "$*"; }

if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
  log "Cluster '${CLUSTER_NAME}' already exists. Reusing."
else
  log "Creating cluster '${CLUSTER_NAME}'..."
  k3d cluster create --config "${CONFIG_FILE}"
fi

log "Waiting for the cluster to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

log "kubectl context:"
kubectl config current-context

log "Nodes:"
kubectl get nodes -o wide
