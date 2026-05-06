#!/usr/bin/env bash
# setup-argocd.sh — Install Argo CD into the cluster and prepare access.
#
# Steps:
#   1. Create the 'argocd' namespace (idempotent)
#   2. Apply the upstream Argo CD install manifest into 'argocd'
#   3. Create the 'dev' namespace (where our app lives)
#   4. Wait for argocd-server to be ready
#   5. Print the initial admin password and how to reach the UI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="${SCRIPT_DIR}/../confs"

log() { printf "\033[1;34m[argocd]\033[0m %s\n" "$*"; }

# --- 1. argocd namespace -----------------------------------------------------
log "Creating argocd namespace (if missing)..."
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd

# --- 2. Install Argo CD ------------------------------------------------------
log "Applying Argo CD install manifest (this can take ~30s)..."
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# --- 3. dev namespace --------------------------------------------------------
log "Creating dev namespace..."
kubectl apply -f "${CONFS_DIR}/dev-namespace.yaml"

# --- 4. Wait for Argo CD -----------------------------------------------------
log "Waiting for argocd-server deployment..."
kubectl wait --for=condition=available deploy/argocd-server -n argocd --timeout=300s
log "Waiting for argocd-repo-server deployment..."
kubectl wait --for=condition=available deploy/argocd-repo-server -n argocd --timeout=300s

# --- 5. Print credentials ----------------------------------------------------
ADMIN_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo '')"

cat <<EOF

------------------------------------------------------------
Argo CD is up.

  UI:        https://localhost:8080  (after running port-forward)
  Username:  admin
  Password:  ${ADMIN_PW}

To open the UI, run in a separate terminal:

  kubectl port-forward -n argocd svc/argocd-server 8080:443

(The browser will warn about a self-signed cert — accept and proceed.)
------------------------------------------------------------
EOF
