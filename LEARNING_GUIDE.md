# Inception-of-Things — Learning Guide

A concept-first guide. The goal is to **understand**, not copy. For each part:
read the concepts → write it yourself → run the self-checks → only look up hints
if a check fails. When you get stuck on something specific, search the keywords
listed before reaching for a full solution.

> Environment decision: run **Vagrant + VirtualBox from Windows** (PowerShell),
> not from inside WSL2. The `192.168.56.0/24` IPs are VirtualBox's default
> host-only network, which works natively on Windows but is awkward through
> WSL2's NAT. Part 3 (Docker/K3d) runs fine inside WSL2.
>
> Replace `LOGIN` everywhere with the 42 login you choose. Machines are
> `LOGINS` (Server) and `LOGINSW` (ServerWorker). The Part 3 GitHub repo name
> must contain that login.

---

## Part 1 — K3s + Vagrant (2 nodes)

### Concepts to learn first
- Vagrant lifecycle: `up`, `ssh`, `halt`, `destroy`, `provision`, and what a
  `Vagrantfile` actually is (Ruby DSL).
- VirtualBox networking: NAT vs **host-only / private network** — why
  `192.168.56.x` matters and which VM interface it lands on.
- K3s **server** (controller) vs **agent** (worker), and how an agent joins:
  it needs the server URL + a **node-token**.

### Figure out the *how* yourself
1. One `Vagrantfile`, two machine definitions. Research `config.vm.define`,
   `.hostname`, `.network`, and the provider block for CPU/RAM.
2. Provision each node with a shell script in `scripts/`. Find the K3s install
   one-liner and the env vars controlling **server vs agent** mode.
3. Solve the token hand-off: how does the worker read the server's token?
   (Hint: what folder do both VMs already share?)

### Research keywords
`vagrant private_network`, `vagrant provider virtualbox cpu memory`,
`k3s INSTALL_K3S_EXEC`, `K3S_URL K3S_TOKEN`,
`/var/lib/rancher/k3s/server/node-token`.

### Self-check — you're done when
- [ ] `vagrant ssh` reaches both machines, passwordless.
- [ ] `ip a` shows `.110` / `.111` on the host-only interface.
- [ ] On the server, `kubectl get nodes -o wide` shows **both** nodes `Ready`
      with the correct internal IPs.

### The trap that wastes hours
K3s may bind to the NAT IP (`10.0.2.15`) instead of `192.168.56.110`, so the
worker can't join. Look into the K3s flags that pin the **node IP** and the
**flannel interface**. Don't move on until both nodes report the right IP.

---

## Part 2 — K3s + 3 apps behind an Ingress

### Concepts to learn first
- Core Kubernetes objects: **Deployment**, **Service**, **Ingress**,
  and **replicas**.
- **Host-based routing**: how the `Host:` header selects the backend.
- Which Ingress controller K3s ships by default (you don't install one —
  find out which, and why that matters).

### Figure out the *how* yourself
1. Single VM. Reuse a trimmed Part 1 server provisioning.
2. Three Deployments + Services; app2 has **3 replicas**. Pick images that
   visibly identify themselves so you can tell which answered.
3. One Ingress: rules for `app1.com`, `app2.com`, and a **default** (any other
   host) → app3.
4. Apply `confs/` automatically during provisioning.

### Research keywords
`kubernetes ingress host rules`, `ingress default backend`, `k3s traefik`,
`kubectl apply -f`, `kubectl get pods -o wide`.

### Self-check
- [ ] app2 shows **3/3** replicas (`kubectl get deploy` / `get pods`).
- [ ] From the host: `curl -H "Host: app1.com" http://192.168.56.110` → app1;
      `app2.com` → app2; an **unknown** host → app3.

### Trap
Decide deliberately how "default" is expressed (a rule with no host vs a
catch-all) and **test the unknown-host case explicitly** — evaluators will.

---

## Part 3 — K3d + Argo CD (GitOps)

### Concepts to learn first
- **K3s vs K3d** — be able to explain the difference out loud (defense asks).
- GitOps: Argo CD watches a Git repo and reconciles the cluster to match it.
- Docker image **tagging** (`v1`/`v2`), and what an Argo CD `Application`
  resource declares (source repo, path, destination namespace, sync policy).

### Figure out the *how* yourself
1. Install script: Docker → kubectl → K3d → create cluster → create namespaces
   `argocd` + `dev` → install Argo CD.
2. Create a **separate public GitHub repo** (name contains your login) holding
   the app's `deployment.yaml`.
3. Write the Argo CD `Application` manifest (kept in `p3/confs/`) pointing at
   that GitHub repo, target namespace `dev`, **automated sync** enabled.
4. Expose the app to test it (think `port-forward`).

### Research keywords
`k3d cluster create`, `argocd install manifest`,
`argocd Application yaml automated sync`, `wil42/playground` (port 8888),
`kubectl port-forward`.

### Self-check
- [ ] `kubectl get ns` shows `argocd` + `dev`.
- [ ] `kubectl get pods -n dev` shows the app Running.
- [ ] Change the image tag `v1→v2` in the **GitHub** repo and push → Argo CD
      auto-syncs → `curl http://localhost:8888/` flips from `v1` to `v2`.
      **This is the money demo — rehearse it.**

### Trap
The deployment manifest Argo CD watches lives in the **GitHub repo**, not in
`p3/confs/`. Keep that separation straight or auto-sync does nothing visible.

---

## Bonus — local GitLab (only if mandatory is flawless)

Install GitLab via **Helm** into a `gitlab` namespace, host the app repo there,
and repoint your Argo CD `Application` from GitHub to local GitLab. Concepts:
Helm charts/values, and the networking to reach an in-cluster GitLab. It is
RAM-hungry — size the host accordingly.

---

## Defense-readiness checklist
- [ ] Explain server vs agent, K3s vs K3d, and what an Ingress does — in your
      own words.
- [ ] Bring any part up from a clean `vagrant destroy` / fresh cluster with no
      notes.
- [ ] Demo Ingress host routing and the Argo CD v1→v2 sync live.
