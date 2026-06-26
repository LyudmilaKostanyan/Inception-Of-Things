# Inception-of-Things — Implementation Plan

Ordered, checkpoint-driven plan. Each milestone ends with a verifiable state.
Do the parts **in order** (p1 → p2 → p3 → bonus). Pair this with
`LEARNING_GUIDE.md` for the concepts behind each step.

> Provider: **VirtualBox on Windows** for p1/p2. Run `vagrant up` from a Windows
> shell in the part's folder; edit files from WSL/VS Code as you like.
> `LOGIN` = the 42 login naming the machines and the Part 3 repo.

---

## Milestone 0 — Setup
- [ ] Install **VirtualBox** + **Vagrant** on Windows; `vagrant --version` works.
- [ ] Confirm a throwaway VM can take a host-only IP on `192.168.56.x`.
- [ ] Create repo skeleton (see structure below) and a top-level `README.md`.

```
p1/   Vagrantfile  scripts/  confs/
p2/   Vagrantfile  scripts/  confs/
p3/   scripts/  confs/
bonus/                         (optional)
README.md
```

---

## Milestone 1 — Part 1: 2-node K3s cluster (`p1/`)

**Deliverables**
- `p1/Vagrantfile` — 2 VMs: `LOGINS` (192.168.56.110), `LOGINSW`
  (192.168.56.111), latest stable distro, 1 CPU, 1024 MB.
- `p1/scripts/server.sh` — installs K3s in **server** mode, pins node IP +
  flannel interface, exposes the node-token to the worker.
- `p1/scripts/worker.sh` — installs K3s in **agent** mode, joins via
  `K3S_URL` + token.
- `kubectl` available on the server.

**Build order**
1. Vagrantfile with both machine definitions + private network + provider sizing.
2. server.sh first; bring up only the server; confirm single-node Ready.
3. worker.sh; bring up the worker; confirm it joins.

**Checkpoint (must pass before p2)**
- [ ] `vagrant ssh LOGINS` and `vagrant ssh LOGINSW` work, passwordless.
- [ ] `kubectl get nodes -o wide` → **2 nodes Ready**, correct `192.168.56.x` IPs.

---

## Milestone 2 — Part 2: 3 apps + Ingress (`p2/`)

**Deliverables**
- `p2/Vagrantfile` — single VM `LOGINS` / 192.168.56.110.
- `p2/scripts/install.sh` — K3s server + `kubectl apply -f /vagrant/confs/`.
- `p2/confs/` — 3 Deployments (app2 with `replicas: 3`), 3 Services, 1 Ingress
  (host rules `app1.com`, `app2.com`, default → app3).

**Build order**
1. VM up with K3s server only; verify default Traefik Ingress controller present.
2. Add app1 Deployment+Service; verify reachable.
3. Add app2 (3 replicas) and app3.
4. Add the Ingress; wire auto-apply into provisioning.

**Checkpoint**
- [ ] `kubectl get pods` → app2 is **3/3**.
- [ ] `curl -H "Host: app1.com" http://192.168.56.110` → app1; `app2.com` →
      app2; unknown host → app3.

---

## Milestone 3 — Part 3: K3d + Argo CD GitOps (`p3/`)

**Deliverables**
- `p3/scripts/install.sh` — installs Docker, kubectl, K3d; creates cluster;
  creates namespaces `argocd` + `dev`; installs Argo CD; applies the Application.
- `p3/confs/` — k3d cluster config (optional) + `argocd-application.yaml`.
- **Separate public GitHub repo** (name contains `LOGIN`) holding the app's
  `deployment.yaml` (image `wil42/playground:v1`, port 8888).

**Build order**
1. install.sh up to a working empty K3d cluster (`kubectl get nodes`).
2. Create the two namespaces; install Argo CD into `argocd`.
3. Create + push the public GitHub repo with `deployment.yaml` at `v1`.
4. Apply the Argo CD `Application` (source = that repo, dest ns = `dev`,
   automated sync on).
5. `port-forward` the app and confirm v1 responds.

**Checkpoint (the money demo)**
- [ ] `kubectl get ns` shows `argocd` + `dev`; `kubectl get pods -n dev` Running.
- [ ] Edit tag `v1→v2` in GitHub, push → Argo CD auto-syncs →
      `curl http://localhost:8888/` returns `v2`. Rehearse this end-to-end.

---

## Milestone 4 — Bonus: local GitLab (`bonus/`, optional)
Only attempt when the mandatory part is **flawless**.
- [ ] Install GitLab via **Helm** into namespace `gitlab`.
- [ ] Host the app repo in local GitLab.
- [ ] Repoint the Argo CD `Application` from GitHub → local GitLab; full Part 3
      flow still works.

---

## Milestone 5 — Defense prep
- [ ] `README.md` documents bring-up commands for each part.
- [ ] Can rebuild any part from clean (`vagrant destroy` / fresh cluster).
- [ ] Can explain server vs agent, K3s vs K3d, Ingress routing, and GitOps sync.

---

## Risk / gotcha log (fill in as you hit them)
- K3s binding to NAT IP instead of host-only → pin node IP + flannel iface (p1).
- Ingress default/unknown-host behavior → test explicitly (p2).
- Argo CD watches the **GitHub** repo, not `p3/confs/` (p3).
- GitLab RAM footprint (bonus).
