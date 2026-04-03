# Operating Tekton: from Git repository to clone → build → push

This document explains **what you do by hand** versus **what Tekton does for you**, and how to run the pipeline **again and again** after the cluster is already set up (install steps are in **`README.md`**).

**Folder:** `/home/ekin/Documents/azure_aks/tekton`

---

## 1. What “clone, build, push” means here

| Step | In plain English | Who does it in this setup |
|------|-------------------|---------------------------|
| **Clone** | Download your application source code from Git (GitHub, Azure DevOps, etc.) into a folder on the build machine. | **Tekton Task `git-clone`** — runs inside a pod on AKS. |
| **Build** | Turn that source into a **container image** using a **`Dockerfile`** (instructions for layers, base image, commands). | **Tekton Task `kaniko`** — runs Kaniko (no Docker daemon needed). |
| **Push** | Upload the built image to a **registry** so Kubernetes or other systems can pull it. | **Same Kaniko step** — pushes to **Azure Container Registry (ACR)**. |

You do **not** run `git clone`, `docker build`, or `docker push` on your laptop for the normal flow. You **start a PipelineRun** on the cluster; Tekton runs those steps in order.

---

## 2. The chain of objects (what triggers what)

```text
You (kubectl / config)
        │
        ▼
   PipelineRun          ← you create this (or re-apply it)
        │
        ▼
   Pipeline              ← already applied: clone-build-push-kaniko
        │
        ├── TaskRun: fetch-repository   → runs Hub Task "git-clone"
        │         (clone)
        │
        └── TaskRun: build-and-push     → runs Hub Task "kaniko"
                  (build + push)
```

- **`Pipeline`** = recipe (two stages: clone, then build/push).
- **`PipelineRun`** = one execution of that recipe with **your** Git URL, branch, image name, tag.

You **do not** trigger `build-and-push` by itself. Tekton always runs **`fetch-repository` first**, then **`build-and-push`** (`runAfter` in the Pipeline). Starting a **PipelineRun** starts **both** steps in order.

---

## 3. How to trigger the pipeline (clone → then build-and-push)

There is **no separate button** only for `build-and-push`. You start a **PipelineRun**; the cluster runs **git-clone**, then **Kaniko** automatically.

### 3.1 Method A — Recommended: `config` → render → `kubectl apply`

Use this every time you want a new build (new branch, new tag, etc.).

```bash
# 1) Go to the folder that contains the YAML
cd /home/ekin/Documents/azure_aks/tekton

# 2) Edit build parameters (Git URL, branch, ACR image name/tag)
nano config-pipelinerun-auth-service.yaml
#    Under parameters: git.url, git.revision, acr.loginServer, acr.imageRepo, acr.imageTag

# 3) Regenerate the PipelineRun manifest from the config
pip install -r requirements.txt    # once, if PyYAML is not installed
python3 render-from-config.py

# 4) Remove an old run with the SAME name (if it already exists)
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins --ignore-not-found

# 5) THIS LINE TRIGGERS THE PIPELINE (clone + build + push)
kubectl apply -f pipelinerun-auth-service.yaml
```

After step **5**, Tekton creates a **PipelineRun** object. Watch it:

```bash
kubectl get pipelinerun -n jenkins
kubectl get taskrun -n jenkins
```

You should see TaskRuns whose names contain **`fetch-repository`** (clone) and **`build-and-push`** (Kaniko build + push to ACR).

**Logs (clone step and build/push step):**

```bash
kubectl logs -n jenkins -l tekton.dev/pipelineRun=clone-build-push-kaniko --all-containers=true --tail=300 -f
```

(If you changed `metadata.name` in the YAML, replace `clone-build-push-kaniko` in the label with your name.)

### 3.2 Method B — Skip the config file: edit `pipelinerun-auth-service.yaml` directly

If you do **not** use `render-from-config.py`, edit **`pipelinerun-auth-service.yaml`** and set `spec.params` (`git-url`, `git-revision`, `acr-login-server`, `image-repo`, `image-tag`), then:

```bash
cd /home/ekin/Documents/azure_aks/tekton
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins --ignore-not-found
kubectl apply -f pipelinerun-auth-service.yaml
```

### 3.3 Method C — Optional: `tkn pipeline start` (Tekton CLI)

If you use the **`tkn`** CLI, you can start the same **Pipeline** with parameters and workspaces. Workspaces must match what **`pipelinerun-auth-service.yaml`** uses (PVC + Secret). That is easy to get wrong on the command line, so **Method A is still recommended**.

```bash
tkn pipeline start clone-build-push-kaniko -n jenkins --showlog
```

`tkn` may prompt for params and workspaces interactively, or you can pass flags — see:

```bash
tkn pipeline start clone-build-push-kaniko -h
```

**Practical tip:** Starting from the generated **`pipelinerun-auth-service.yaml`** with **`kubectl apply`** (Method A) avoids retyping workspaces and secrets.

### 3.4 Method D — `kubectl create` (only if you use `generateName`)

If your PipelineRun YAML uses **`metadata.generateName:`** instead of **`name:`**, use **`kubectl create -f`** (not `apply`) so each run gets a unique name. The YAML in this repo uses a fixed **`name:`**, so **`kubectl apply`** is correct.

### 3.5 One-line reminder

| You run | What Tekton runs next |
|---------|------------------------|
| `kubectl apply -f pipelinerun-auth-service.yaml` | `fetch-repository` (clone) → then `build-and-push` (Kaniko + push) |

### 3.6 Run the pipeline **again** (after clone + build-and-push already succeeded)

A finished **PipelineRun** is **not** updated in place when you `kubectl apply` the same file again — Kubernetes/Tekton often keep the old object. To start a **new** run (new clone + new build + new push), remove the old **PipelineRun** object, then apply again.

**Same Git branch and same image tag (rebuild same thing):**

```bash
cd /home/ekin/Documents/azure_aks/tekton
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins
kubectl apply -f pipelinerun-auth-service.yaml
```

**New branch, new tag, or new repo (change parameters first):**

```bash
cd /home/ekin/Documents/azure_aks/tekton
nano config-pipelinerun-auth-service.yaml    # edit git.revision, acr.imageTag, etc.
python3 render-from-config.py
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins
kubectl apply -f pipelinerun-auth-service.yaml
```

**Watch the new run:**

```bash
kubectl get pipelinerun -n jenkins -w
kubectl get taskrun -n jenkins
```

If you renamed **`metadata.name`** in the YAML, use that name in **`kubectl delete pipelinerun NAME -n jenkins`**.

---

## 4. Before you operate: one-time assumptions

These should already be done (see **`README.md`**):

- Tekton Pipelines installed on the cluster.
- Namespace **`jenkins`** exists.
- Tasks **`git-clone`** and **`kaniko`** installed in **`jenkins`**.
- Secrets **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`** exist in **`jenkins`**.
- **`tekton-sa.yaml`** and **`clone-build-push-kaniko.yaml`** already applied.

If any of that is missing, fix **`README.md`** first; this file is about **day-to-day operation**.

---

## 5. How Tekton “clones” (you don’t run `git clone` yourself)

### 5.1 What the pipeline passes

The **Pipeline** takes a parameter **`git-url`** (HTTPS URL of the repo) and **`git-revision`** (branch name, tag, or commit SHA).

Example:

- `git-url`: `https://github.com/your-org/your-service.git`
- `git-revision`: `main` or `develop` or `v1.2.0` or a full commit hash

Those values come from **`config-pipelinerun-auth-service.yaml`** → after **`python3 render-from-config.py`** they appear in **`pipelinerun-auth-service.yaml`** under `spec.params`.

### 5.2 What happens in the cluster

1. Tekton starts a **pod** for the **git-clone** task.
2. That pod runs the catalog **git-clone** task, which runs `git` logic equivalent to: clone that URL and check out that revision into a **workspace** (a shared disk volume for this pipeline run).
3. The next task (**kaniko**) sees the **same workspace**, so it finds your **`Dockerfile`** at the path you configured (default: **`./Dockerfile`** at the **root of the cloned repo**).

### 5.3 If you needed to clone manually (for debugging only)

On any machine with Git:

```bash
git clone https://github.com/your-org/your-service.git
cd your-service
git checkout YOUR_BRANCH_OR_TAG
```

Tekton does the equivalent **inside the cluster**; you only need the manual clone to **inspect** files or test locally.

---

## 6. How Tekton “builds” (you don’t run `docker build` yourself)

### 6.1 What Kaniko uses

- **Dockerfile path** — in this pipeline, parameter **`DOCKERFILE`** is **`./Dockerfile`** (relative to the clone root).
- **Context** — **`CONTEXT`** is **`.`** (the repository root after clone).

So your repo must contain **`Dockerfile`** at the **top level** unless you change the Pipeline to another path.

### 6.2 What happens in the cluster

1. The **kaniko** executor runs **without** the Docker daemon.
2. It reads the Dockerfile and layers, then produces an **OCI image**.
3. It **tags** the image as:

   `YOUR_ACR_LOGIN_SERVER/YOUR_IMAGE_REPO:YOUR_TAG`  
   Example: `ekinregistry.azurecr.io/auth-service:v1`

   Those pieces come from **`acr-login-server`**, **`image-repo`**, **`image-tag`** in your **PipelineRun** params (via config file).

### 6.3 If you needed to build manually (local debugging)

On a machine with Docker:

```bash
docker build -t myregistry.azurecr.io/auth-service:v1 .
docker push myregistry.azurecr.io/auth-service:v1
```

You would need **`docker login`** to ACR first. In Tekton, **Kaniko** uses the **`acr-dockerconfig-kaniko`** secret mounted as **`config.json`** instead of your laptop’s Docker config.

---

## 7. How Tekton “pushes” (you don’t run `docker push` yourself)

1. Kaniko finishes the image and **pushes** it to the registry in **`acr-login-server`**.
2. Authentication uses the **dockerconfig** workspace (secret **`acr-dockerconfig-kaniko`** with key **`config.json`**).
3. After success, the image appears in **ACR** under repository **`image-repo`** with tag **`image-tag`**.

### 7.1 Verify from your laptop

```bash
az acr repository show --name YOUR_ACR_NAME --repository YOUR_REPO_NAME
az acr repository show-tags --name YOUR_ACR_NAME --repository YOUR_REPO_NAME
```

---

## 8. Day-to-day: run the pipeline again (most common flow)

### Step A — Change what to build (Git + image)

1. Open **`config-pipelinerun-auth-service.yaml`**.
2. Under **`parameters`**, edit what you need:

   - **`git.url`** — repository to clone.
   - **`git.revision`** — branch or tag (e.g. `main`, `feature/xyz`, `v2`).
   - **`acr.loginServer`** — e.g. `ekinregistry.azurecr.io`.
   - **`acr.imageRepo`** — repository name in ACR (e.g. `auth-service`).
   - **`acr.imageTag`** — new tag each release if you want (e.g. `v1.0.1` or Git short SHA).

3. Save the file.

### Step B — Regenerate the PipelineRun manifest

```bash
cd /home/ekin/Documents/azure_aks/tekton
pip install -r requirements.txt    # once, if PyYAML missing
python3 render-from-config.py
```

This **overwrites** **`pipelinerun-auth-service.yaml`** from the config. Always review **`git diff pipelinerun-auth-service.yaml`** if you use version control.

### Step C — Apply to the cluster

If a **PipelineRun** with the **same name** already exists and finished (or failed), Kubernetes may **not** let you change important fields. Easiest pattern:

```bash
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins
kubectl apply -f pipelinerun-auth-service.yaml
```

(If you use a **different** `metadata.name` in the config, adjust the delete command to that name.)

### Step D — Watch until it succeeds

```bash
kubectl get pipelinerun -n jenkins -w
```

Press **Ctrl+C** when you see **Succeeded** or **Failed**.

Detailed logs:

```bash
kubectl get taskrun -n jenkins
kubectl logs -n jenkins -l tekton.dev/pipelineRun=clone-build-push-kaniko --all-containers=true --tail=300
```

If you installed **`tkn`**:

```bash
tkn pipelinerun logs -f clone-build-push-kaniko -n jenkins
```

---

## 9. What each file is for when operating

| File | When you touch it |
|------|-------------------|
| **`config-pipelinerun-auth-service.yaml`** | Every time you change **which repo**, **branch**, or **image name/tag** to build. |
| **`render-from-config.py`** | Run after editing the config (regenerates **`pipelinerun-auth-service.yaml`**). |
| **`pipelinerun-auth-service.yaml`** | Usually **generated**; only edit by hand if you stopped using the script. |
| **`clone-build-push-kaniko.yaml`** | Rarely — only if you change **Pipeline** structure (e.g. Dockerfile path). |
| **`tekton-sa.yaml`** | Rarely — when changing **ServiceAccount** or secret names. |

---

## 10. Typical scenarios

### 10.1 “I merged to `main`; rebuild and push `v2`”

1. Set **`git.revision`** to **`main`** (or the merge commit SHA).
2. Set **`acr.imageTag`** to **`v2`**.
3. **`python3 render-from-config.py`**
4. **`kubectl delete pipelinerun ...`** then **`kubectl apply -f pipelinerun-auth-service.yaml`**

### 10.2 “Build a feature branch”

1. Set **`git.revision`** to **`feature/my-feature`** (exact branch name on the remote).
2. Use a distinct **`imageTag`** (e.g. **`feature-my-feature-1`**) so you do not overwrite production tags.

### 10.3 “Pipeline failed at clone”

- Check **HTTPS URL** and that the branch/tag **exists**.
- **Private repo:** you need extra Tekton setup (SSH secret or `basic-auth` workspace on **git-clone**). This guide assumes **public** clone or credentials already configured.

### 10.4 “Pipeline failed at build/push”

- **401 / UNAUTHORIZED:** run **`az acr login`**, recreate **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`** (see **`README.md`**).
- **No Dockerfile:** ensure **`Dockerfile`** exists at repo **root** (or change Pipeline **`DOCKERFILE`** / **`CONTEXT`**).

---

## 11. Quick reference commands

```bash
# Where you work
cd /home/ekin/Documents/azure_aks/tekton

# Edit build parameters
nano config-pipelinerun-auth-service.yaml

# Regenerate + apply
python3 render-from-config.py
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins --ignore-not-found
kubectl apply -f pipelinerun-auth-service.yaml

# Status
kubectl get pipelinerun -n jenkins
kubectl get taskrun -n jenkins

# Logs (replace label if you changed PipelineRun name)
kubectl logs -n jenkins -l tekton.dev/pipelineRun=clone-build-push-kaniko --all-containers=true --tail=200
```

---

## 12. How this differs from “manual CI” on your laptop

| Action | On your laptop (manual) | With Tekton (this project) |
|--------|-------------------------|----------------------------|
| Clone | `git clone` | **git-clone** task in AKS |
| Build | `docker build` | **kaniko** task in AKS |
| Push | `docker push` after `docker login` | **kaniko** push using **Kubernetes secrets** |
| Trigger | You run commands | You **`kubectl apply`** a **PipelineRun** (or CI system triggers it later) |

The value of Tekton: **repeatable builds on the cluster** with the same recipe, no local Docker required for the pipeline execution.

---

## 13. Where to read next

- **Install Tekton, ACR secrets, first-time apply:** **`README.md`** in the same folder.
- **YAML file list and troubleshooting table:** **`README.md`**.


## 14. tkn pipeline start` (interactive / CLI)
# Tekton operations (clone-build-push-kaniko)
## Prerequisites
- Pipeline `clone-build-push-kaniko` and tasks (`git-clone`, `kaniko`) installed in namespace `jenkins`.
- Secret `acr-dockerconfig-kaniko` in `jenkins` with valid ACR credentials (`config.json` / `.dockerconfigjson`).
- Service account `tekton-sa` with permission to run the pipeline.
## Files in this directory
| File | Purpose |
|------|---------|
| `workspace-shared-data-pvc.yaml` | PVC `spec` for `tkn` workspace `shared-data` (VolumeClaimTemplate). |
| `pod-template-fs.yaml` | Optional `fsGroup: 65532` for PVC writes (matches `pipelinerun-auth-service.yaml`). |
## Commands to run
### Option A: `tkn pipeline start` (interactive / CLI)
Run from any directory; use absolute paths as below.
```bash
tkn pipeline start clone-build-push-kaniko -n jenkins \
  -s tekton-sa \
  -p git-url="https://github.com/shenekin/auth-service.git" \
  -p git-revision="dev-secret-19044" \
  -p acr-login-server="ekinregistry.azurecr.io" \
  -p image-repo="auth-service" \
  -p image-tag="v2" \
  -w name=shared-data,volumeClaimTemplateFile=/developer/IAC/Third-party/tekton/with_azure_aks/workspace-shared-data-pvc.yaml \
  -w name=dockerconfig,secret=acr-dockerconfig-kaniko \
  --pod-template=/developer/IAC/Third-party/tekton/with_azure_aks/pod-template-fs.yaml
Notes:

volumeClaimTemplateFile must point to a real .yaml / .yml file (not a placeholder). The file must contain a PVC spec (see workspace-shared-data-pvc.yaml).
Omit --pod-template=... if you do not need fsGroup (drop it if you see no permission errors on the workspace).
---

## 15.  401 / UNAUTHORIZED
*401 / UNAUTHORIZED:** run **`az acr login`**, recreate **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`** (see **`README.md`**).
- **401 / UNAUTHORIZED:** run **`./refresh-acr-secrets.sh`** in the Tekton folder (after **`az login`**), or manually run **`az acr login`** and recreate **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`** (see **`README.md`** §6.2). Then **`kubectl delete pipelinerun clone-build-push-kaniko -n jenkins`** and **`kubectl apply -f pipelinerun-auth-service.yaml`** again.
- **No Dockerfile:** ensure **`Dockerfile`** exists at repo **root** (or change Pipeline **`DOCKERFILE`** / **`CONTEXT`**).
Fix it now
Log in to Azure (if needed):

az login
Point kubectl at your AKS cluster (if needed):

az aks get-credentials --resource-group YOUR_RG --name YOUR_AKS
From your Tekton folder, refresh ACR and push the same credentials into the two secrets Kaniko uses:

cd /developer/IAC/Third-party/tekton/with_azure_aks
./refresh-acr-secrets.sh
If your registry short name is not ekinregistry, pass it:

./refresh-acr-secrets.sh YOUR_ACR_SHORT_NAME
This runs az acr login, then recreates acr-dockerconfig and acr-dockerconfig-kaniko in namespace jenkins, matching README.md §6.2.

Start a new pipeline run so pods do not reuse stale mounts:

kubectl delete pipelinerun clone-build-push-kaniko -n jenkins --ignore-not-found
kubectl apply -f pipelinerun-auth-service.yaml
*Document version: written for operators using `/home/ekin/Documents/azure_aks/tekton` with Pipeline `clone-build-push-kaniko` and PipelineRun `clone-build-push-kaniko` in namespace `jenkins`.*
