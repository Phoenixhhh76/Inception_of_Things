#!/usr/bin/env bash
# install.sh — Install K3d + kubectl + argocd CLI
#
# This script installs everything needed to run Part 3 of the
# Inception-of-Things project on macOS (via Homebrew) or on a
# Linux distro (Fedora/Ubuntu/Debian) using the official installers.
#
# Usage: ./install.sh
#
# Prerequisites:
#   - Docker (Docker Desktop on macOS, or docker engine on Linux)
#   - For macOS: Homebrew (https://brew.sh)
#   - For Linux: curl, sudo

set -euo pipefail

log() { printf "\033[1;34m[install]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }

# --- 0. Detect OS -----------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="mac" ;;
  Linux)  PLATFORM="linux" ;;
  *)      err "Unsupported OS: $OS"; exit 1 ;;
esac
log "Detected platform: $PLATFORM"

# --- 1. Check Docker --------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  err "Docker is not installed. Install Docker Desktop (mac) or docker-ce (Linux) first."
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  err "Docker daemon is not running. Start Docker Desktop / dockerd."
  exit 1
fi
log "Docker is OK ($(docker --version))"

# --- 2. Install kubectl -----------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  log "kubectl already installed ($(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -1 | tr -d ' '))"
else
  log "Installing kubectl..."
  if [ "$PLATFORM" = "mac" ]; then
    brew install kubectl
  else
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
  fi
fi

# --- 3. Install k3d ---------------------------------------------------------
if command -v k3d >/dev/null 2>&1; then
  log "k3d already installed ($(k3d version | head -1))"
else
  log "Installing k3d..."
  if [ "$PLATFORM" = "mac" ]; then
    brew install k3d
  else
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi
fi

# --- 4. Install Argo CD CLI -------------------------------------------------
if command -v argocd >/dev/null 2>&1; then
  log "argocd CLI already installed ($(argocd version --client --short 2>/dev/null || true))"
else
  log "Installing argocd CLI..."
  if [ "$PLATFORM" = "mac" ]; then
    brew install argocd
  else
    curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    sudo install -m 555 argocd /usr/local/bin/argocd
    rm -f argocd
  fi
fi

# --- 5. Summary -------------------------------------------------------------
log "All tools installed."
log "Versions:"
docker  --version
kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -1 | sed 's/^/  /'
k3d     version | head -2 | sed 's/^/  /'
argocd  version --client --short 2>/dev/null | sed 's/^/  /' || true

log "Next step: ./scripts/create-cluster.sh"
