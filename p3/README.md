# Part 3 — K3d + Argo CD (GitOps)

A local Kubernetes cluster (K3d on Docker) running Argo CD, which
auto-deploys an app from a public GitHub repository.

```
   GitHub (manifests)  ──pull──►  Argo CD  ──apply──►  dev namespace
        ▲                                                  │
        │                                                  ▼
       push                                          wil42/playground:v1
```

## Folder layout

```
p3/
├── README.md
├── scripts/
│   ├── install.sh         # install kubectl, k3d, argocd CLI
│   ├── create-cluster.sh  # k3d cluster create
│   ├── setup-argocd.sh    # install Argo CD + create dev namespace
│   ├── apply-app.sh       # register the Argo CD Application
│   ├── setup-all.sh       # run all of the above in order
│   └── cleanup.sh         # k3d cluster delete
└── confs/
    ├── cluster.yaml        # k3d cluster definition
    ├── dev-namespace.yaml  # the 'dev' namespace
    ├── application.yaml    # Argo CD Application (points to GitHub)
    └── manifests/          # ↓ these go into your PUBLIC GitHub repo
        ├── deployment.yaml # uses wil42/playground:v1 (port 8888)
        └── service.yaml    # ClusterIP on 8888
```

## Prerequisites

- Docker Desktop running
- macOS with Homebrew, **or** a Linux distro with curl + sudo
- A GitHub account and a public repo (instructions below)

## One-time setup

### 1. Install tools

```bash
./scripts/install.sh
```

Installs `kubectl`, `k3d`, `argocd` CLI. Idempotent.

### 2. Create your public GitHub repo

The project subject requires the repo name to contain a member's
login. Example: `iot-phoenix`.

```bash
# in some scratch directory
git clone https://github.com/<your-user>/iot-phoenix.git
cd iot-phoenix
mkdir -p manifests
cp /path/to/p3/confs/manifests/*.yaml manifests/
git add . && git commit -m "initial manifests" && git push
```

### 3. Point the Argo CD Application at your repo

Edit `confs/application.yaml` and replace the placeholder `repoURL:`
with your repo's HTTPS clone URL. Also confirm `targetRevision:` is
either `main` or `master` to match your repo's default branch.

### 4. Bring everything up

```bash
./scripts/create-cluster.sh   # k3d cluster
./scripts/setup-argocd.sh     # Argo CD + dev namespace
./scripts/apply-app.sh        # register the Application
```

Or in one shot:

```bash
./scripts/setup-all.sh
```

## Demo flow (v1 → v2 sync)

In **terminal A**, expose Argo CD UI:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# open https://localhost:8080  (admin / <password from setup-argocd.sh>)
```

In **terminal B**, expose the app:

```bash
kubectl port-forward -n dev svc/playground 8888:8888
```

In **terminal C**, verify v1:

```bash
curl http://localhost:8888/
# → {"status":"ok", "message": "v1"}
```

Now switch to v2 — **edit the file in your GitHub repo, not here**:

```bash
cd /path/to/iot-phoenix
sed -i '' 's|wil42/playground:v1|wil42/playground:v2|' manifests/deployment.yaml
git commit -am "bump to v2" && git push
```

Argo CD auto-syncs within ~3 minutes. To force an immediate sync,
either click **Sync** in the UI or run:

```bash
argocd app sync playground
```

Verify the new pod is up and curl returns v2:

```bash
kubectl get pods -n dev -w        # wait for the new pod to be Ready
curl http://localhost:8888/
# → {"status":"ok", "message": "v2"}
```

## Cleanup

```bash
./scripts/cleanup.sh
```

Deletes the `iot` k3d cluster. Your GitHub repo is untouched.

## Troubleshooting

**`argocd-server` pod stuck in `Pending`:** check `kubectl describe pod`;
usually it's resource limits — give Docker Desktop more RAM (≥ 4 GB).

**App stays `OutOfSync`:** check the repo URL/branch in `application.yaml`,
and that the manifests folder path matches `path:` in the spec.

**Can't reach `localhost:8888`:** the port-forward only runs while the
shell that launched it is alive. Keep terminal B open.
