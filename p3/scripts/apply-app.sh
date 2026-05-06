#!/usr/bin/env bash
# apply-app.sh — Register our Argo CD Application.
#
# This is the GitOps wiring. After this runs, Argo CD will:
#   1. Clone the GitHub repo specified in p3/confs/application.yaml
#   2. Apply every manifest under the `path` (manifests/) into 'dev'
#   3. Auto-sync on every git push (within ~3 min, or instantly via UI)
#
# Prereq: you have already updated `repoURL:` in application.yaml to
#         point at your own public GitHub repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_FILE="${SCRIPT_DIR}/../confs/application.yaml"

log() { printf "\033[1;34m[app]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

# Sanity check: warn if the URL still looks unfilled.
REPO_URL="$(awk '/repoURL:/ {print $2; exit}' "${APP_FILE}")"
if [ -z "${REPO_URL}" ] || [[ "${REPO_URL}" == *"phoenix/iot-phoenix"* ]]; then
  warn "application.yaml has a placeholder repoURL: ${REPO_URL}"
  warn "Edit ${APP_FILE} and set it to your own public repo URL."
  exit 1
fi
log "Using repoURL: ${REPO_URL}"

log "Applying Argo CD Application manifest..."
kubectl apply -f "${APP_FILE}"

log "Waiting for Argo CD to register the Application..."
sleep 3

log "Application status:"
kubectl get application -n argocd playground -o wide || true

cat <<EOF

------------------------------------------------------------
The Argo CD Application is registered.

Watch sync progress:
  kubectl get application -n argocd playground -w

Or open the UI (in another terminal):
  kubectl port-forward -n argocd svc/argocd-server 8080:443
  open https://localhost:8080

Once Synced/Healthy, reach the app:
  kubectl port-forward -n dev svc/playground 8888:8888 &
  curl http://localhost:8888/
------------------------------------------------------------
EOF
