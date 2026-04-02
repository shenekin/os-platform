# Tekton on Kubernetes: build and push to Azure Container Registry (ACR)

This guide walks a **newcomer** from zero to a working **clone → Docker build (Kaniko) → push to ACR** pipeline on **Azure Kubernetes Service (AKS)** using **Tekton Pipelines**.

**Where the files live**

- Primary folder: **`/home/ekin/Documents/azure_aks/tekton`**
- You may also have a copy under your app repo: **`tekton/`** — keep them in sync.

**Day-to-day operations** (what clone/build/push mean, how to re-run the pipeline, edit config, watch logs): see **`operation_tekton.md`** in this folder.

---

## Table of contents

1. [What you are installing (picture)](#what-you-are-installing-picture)
2. [Prerequisites](#0-prerequisites)
3. [Connect `kubectl` to your cluster](#1-connect-kubectl-to-your-cluster)
4. [Install Tekton Pipelines on the cluster](#2-install-tekton-pipelines-on-the-cluster)
5. [Verify Tekton is installed](#3-verify-tekton-is-installed)
6. [Create the `jenkins` namespace](#4-create-the-jenkins-namespace)
7. [Install Tekton Catalog Tasks (git-clone, kaniko)](#5-install-tekton-catalog-tasks-git-clone-kaniko)
8. [Azure Container Registry (ACR) and Kubernetes secrets](#6-azure-container-registry-acr-and-kubernetes-secrets)
9. [Configure this repo and apply manifests](#7-configure-this-repo-and-apply-manifests)
10. [Watch the pipeline and verify the image](#8-watch-the-pipeline-and-verify-the-image)
11. [Optional: Tekton Dashboard and `tkn` CLI](#9-optional-tekton-dashboard-and-tkn-cli)
12. [What Tekton objects mean](#what-tekton-objects-mean-short)
13. [Files in this directory](#files-in-this-directory-full-list)
14. [Configuration files and workflow](#configuration-files-configyaml)
15. [Pipeline parameters and YAML notes](#pipeline-parameters-and-yaml-notes)
16. [Why this repo uses PVC, fsGroup, and Kaniko secrets](#why-this-repo-uses-pvc-fsgroup-and-kaniko-secrets)
17. [Troubleshooting](#troubleshooting-quick-reference)
18. [Customizing for another service](#customizing-for-another-service)
19. [Summary](#summary)
20. **`operation_tekton.md`** — day-to-day operations (Git → clone/build/push → ACR)

---

## Operations guide (clone → build → push)

For detailed **operational** steps after the cluster is set up (editing **`config-pipelinerun-auth-service.yaml`**, regenerating the PipelineRun, re-applying, watching logs, and what “clone / build / push” mean in Tekton), open:

**[`operation_tekton.md`](operation_tekton.md)**

---

## What you are installing (picture)

```text
GitHub repo
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  AKS cluster                                             │
│  ┌──────────────┐    ┌─────────────┐    ┌────────────┐  │
│  │ Tekton       │    │ Pipeline    │    │ TaskRuns   │  │
│  │ Pipelines    │───▶│ clone-build │───▶│ git-clone  │  │
│  │ (controller) │    │ -push-kaniko│    │ + kaniko   │  │
│  └──────────────┘    └─────────────┘    └─────┬──────┘  │
│                                                  │       │
└──────────────────────────────────────────────────┼───────┘
                                                   ▼
                                         Azure Container Registry
                                         (e.g. myregistry.azurecr.io)
```

You install **Tekton Pipelines** once (cluster-wide). Then you add **Tasks**, **Pipeline**, **PipelineRun**, and **secrets** so builds can push images to **ACR**.

---

## 0. Prerequisites

| Requirement | Why |
|-------------|-----|
| **Azure subscription** and permission to use ACR and AKS | Registry and cluster live in Azure. |
| **AKS cluster** already created | Tekton runs on Kubernetes. |
| **Azure CLI** (`az`) | [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — login and ACR. |
| **`kubectl`** | [Install](https://kubernetes.io/docs/tasks/tools/) — talk to the cluster. |
| **Python 3** + **PyYAML** (optional but recommended) | `pip install -r requirements.txt` to regenerate `pipelinerun-auth-service.yaml` from config. |
| **Git repo with a `Dockerfile` at the repo root** (or adjust Pipeline params later) | Kaniko builds from `./Dockerfile` by default. |

**Replace placeholders** in commands below:

- `YOUR_ACR_NAME` — short ACR name (e.g. `ekinregistry`), **not** the full hostname.
- `YOUR_REGISTRY_HOST` — login server, e.g. `ekinregistry.azurecr.io` (no `https://`).

This repo’s example configs use **`ekinregistry.azurecr.io`** — change them in **`config-pipelinerun-auth-service.yaml`** if yours differs.

---

## 1. Connect `kubectl` to your cluster

```bash
az login
az aks get-credentials --resource-group YOUR_RESOURCE_GROUP --name YOUR_AKS_NAME
kubectl config current-context
kubectl get nodes
```

You should see your AKS nodes. If not, fix the context before continuing.

---

## 2. Install Tekton Pipelines on the cluster

Tekton adds **Custom Resource Definitions (CRDs)** such as `Pipeline`, `PipelineRun`, `Task`, `TaskRun`.

Install the **official release** (check [Tekton Pipelines releases](https://github.com/tektoncd/pipeline/releases) if you want a pinned version instead of `latest`):

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

Wait until the Tekton controller pods are running:

```bash
kubectl get pods -n tekton-pipelines
```

Wait until pods like `tekton-pipelines-controller` and `tekton-pipelines-webhook` are **Running**.

---

## 3. Verify Tekton is installed

```bash
kubectl get crd | grep tekton
kubectl api-resources --api-group=tekton.dev
```

You should see resources such as **`pipelines`**, **`pipelineruns`**, **`tasks`**, **`taskruns`**.

If you see **no** `tekton.dev` resources, the install from step 2 did not succeed — repeat it or check cluster permissions.

---

## 4. Create the `jenkins` namespace

This repo’s YAML uses namespace **`jenkins`**. You can use another name, but then you must change **`namespace:`** in every manifest and in **`config-*.yaml` files**.

```bash
kubectl create namespace jenkins
```

---

## 5. Install Tekton Catalog Tasks (git-clone, kaniko)

The **Pipeline** references two **Tasks** by name: **`git-clone`** and **`kaniko`**. Install them **into the same namespace** (`jenkins`) where you will run the Pipeline:

```bash
kubectl apply -n jenkins -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.10/git-clone.yaml
kubectl apply -n jenkins -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/kaniko/0.7/kaniko.yaml
```

Verify:

```bash
kubectl get tasks -n jenkins
```

You should see **`git-clone`** and **`kaniko`**.

If a URL returns 404, open [tektoncd/catalog — task](https://github.com/tektoncd/catalog/tree/main/task), pick the latest **git-clone** and **kaniko** subfolders, and use the raw `git-clone.yaml` / `kaniko.yaml` URLs from there.

---

## 6. Azure Container Registry (ACR) and Kubernetes secrets

### 6.1 Ensure you can log in to ACR

1. Log in to Azure: `az login`
2. Log in to your registry (replace `YOUR_ACR_NAME`):

   ```bash
   az acr login --name YOUR_ACR_NAME
   ```

   This refreshes **`~/.docker/config.json`** on your machine with credentials for ACR.

### 6.2 Create Kubernetes secrets in `jenkins`

Still on a machine where **`kubectl`** points at your AKS cluster:

**Secret A — Tekton / ServiceAccount (`kubernetes.io/dockerconfigjson`)**

```bash
kubectl -n jenkins create secret generic acr-dockerconfig \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

Optional but recommended annotation (helps Tekton resolve credentials for that registry):

```bash
kubectl -n jenkins annotate secret acr-dockerconfig \
  tekton.dev/docker-0=https://YOUR_REGISTRY_HOST --overwrite
```

Use your real hostname, e.g. `https://ekinregistry.azurecr.io`.

**Secret B — Kaniko (`config.json` filename)**

Kaniko reads **`config.json`** under `/kaniko/.docker`. Derive it from the same Docker config:

```bash
kubectl get secret acr-dockerconfig -n jenkins -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d > /tmp/c.json
kubectl -n jenkins create secret generic acr-dockerconfig-kaniko --from-file=config.json=/tmp/c.json
rm /tmp/c.json
```

When ACR tokens expire, run **`az acr login`** again and **recreate** these secrets (delete old `Secret` objects first if names clash).

---

## 7. Configure this repo and apply manifests

```bash
cd /home/ekin/Documents/azure_aks/tekton
```

1. **Edit `config-pipelinerun-auth-service.yaml`** — set Git URL, branch, **`acr.loginServer`**, **`imageRepo`**, **`imageTag`**, and ensure **`dockerconfig.secretName`** matches **`acr-dockerconfig-kaniko`** (unless you renamed the secret).

2. **Regenerate the PipelineRun manifest** (needs PyYAML):

   ```bash
   pip install -r requirements.txt
   python3 render-from-config.py
   ```

3. **Apply in order** (ServiceAccount → Pipeline → PipelineRun):

   ```bash
   kubectl apply -f tekton-sa.yaml
   kubectl apply -f clone-build-push-kaniko.yaml
   kubectl apply -f pipelinerun-auth-service.yaml
   ```

**Important:** Apply **`clone-build-push-kaniko.yaml`** before the PipelineRun references it. If a previous PipelineRun failed with “Pipeline not found”, delete the old run and re-apply:

```bash
kubectl delete pipelinerun clone-build-push-kaniko -n jenkins
kubectl apply -f pipelinerun-auth-service.yaml
```

---

## 8. Watch the pipeline and verify the image

```bash
kubectl get pipelinerun -n jenkins -w
kubectl get taskrun -n jenkins
kubectl logs -n jenkins -l tekton.dev/pipelineRun=clone-build-push-kaniko --all-containers=true --tail=200
```

**ACR** (replace names):

```bash
az acr repository show --name YOUR_ACR_NAME --repository YOUR_REPO_NAME
az acr repository show-tags --name YOUR_ACR_NAME --repository YOUR_REPO_NAME
```

---

## 9. Optional: Tekton Dashboard and `tkn` CLI

**Dashboard** — install from [Tekton Dashboard releases](https://github.com/tektoncd/dashboard/releases), then:

```bash
kubectl -n tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```

Open **http://127.0.0.1:9097** (authentication depends on your setup; often a token or kubeconfig).

**`tkn` CLI** — [install](https://tekton.dev/docs/cli/), then e.g. `tkn pipelinerun logs -f clone-build-push-kaniko -n jenkins`.

---

## What Tekton objects mean (short)

| Object | Role |
|--------|------|
| **Task** | Reusable “job” (e.g. `git-clone`, `kaniko`). Usually installed from the [Tekton catalog](https://github.com/tektoncd/catalog). |
| **Pipeline** | Ordered list of Tasks, parameters, and **workspaces** (shared folders). |
| **PipelineRun** | One execution of a Pipeline with concrete parameter values and workspace bindings. |
| **ServiceAccount** | Identity for pods; Tekton can attach registry **Secrets** for image push. |
| **Workspace** | A volume shared between Tasks (source code, Docker config, etc.). |

---

## Files in this directory (full list)

### Kubernetes manifests (`kubectl apply`)

| File | Kind | Purpose |
|------|------|---------|
| `tekton-sa.yaml` | `ServiceAccount` | `tekton-sa` in `jenkins`; references Secret `acr-dockerconfig`. |
| `clone-build-push-kaniko.yaml` | `Pipeline` | Defines parameters, tasks (`fetch-repository` → `build-and-push`), workspaces. |
| `pipelinerun-auth-service.yaml` | `PipelineRun` | Example run for **auth-service** (Git, ACR, PVC, `fsGroup`, Kaniko dockerconfig). |

Catalog **Tasks** are **not** in this folder — install them in [step 5](#5-install-tekton-catalog-tasks-git-clone-kaniko).

### Parameter bundles (do **not** `kubectl apply`)

| File | Pairs with |
|------|------------|
| `config-tekton-sa.yaml` | `tekton-sa.yaml` |
| `config-clone-build-push-kaniko.yaml` | `clone-build-push-kaniko.yaml` |
| `config-pipelinerun-auth-service.yaml` | `pipelinerun-auth-service.yaml` |

### Helpers

| File | Purpose |
|------|---------|
| `render-from-config.py` | Writes `pipelinerun-auth-service.yaml` from `config-pipelinerun-auth-service.yaml`. |
| `render-from-config.sh` | Runs `python3 render-from-config.py`. |
| `requirements.txt` | Lists **PyYAML** for the renderer. |

---

## Configuration files (`config-*.yaml`)

These files use the prefix **`config-`** plus the same basename as the manifest. They are **not** Kubernetes resources — **do not** `kubectl apply` them.

- **`config-pipelinerun-auth-service.yaml`** — main place for **per-build** values. After editing, run **`python3 render-from-config.py`**, then **`kubectl apply -f pipelinerun-auth-service.yaml`**.
- **`config-tekton-sa.yaml`** / **`config-clone-build-push-kaniko.yaml`** — copy values into **`tekton-sa.yaml`** and **`clone-build-push-kaniko.yaml`** when you change namespaces or Hub task names (no generator for those two yet).

---

## Pipeline parameters and YAML notes

| Parameter | Meaning |
|-----------|---------|
| `git-url` | HTTPS clone URL. |
| `git-revision` | Branch, tag, or commit SHA. |
| `acr-login-server` | Registry hostname only (no `https://`). |
| `image-repo` | Repository name under that registry. |
| `image-tag` | Tag to push. |

**Use `git-url` for the Git URL** — not `auth-service` (that name is for the **image** in ACR via `image-repo`).

**Tekton:** Hyphenated parameters in the Pipeline must use **`$(params['git-url'])`** style, not `$(params.git-url)`.

---

## Why this repo uses PVC, fsGroup, and Kaniko secrets

1. **`shared-data` + `volumeClaimTemplate`** — Each TaskRun is a **separate Pod**. Plain `emptyDir` gave **each pod its own empty volume**, so Kaniko saw **no Dockerfile**. A **PVC** shares the same disk between clone and build.

2. **`fsGroup: 65532`** — Azure Disk PVCs can have root-owned `lost+found`. The **git-clone** task runs as non-root (UID **65532**); `fsGroup` makes the volume writable for git.

3. **`dockerconfig` workspace + `acr-dockerconfig-kaniko`** — Kaniko looks for **`config.json`** under `/kaniko/.docker`. Tekton’s default credential path is not enough; mount an **Opaque** secret with key **`config.json`** (same JSON as `.dockerconfigjson`).

---

## Troubleshooting (quick reference)

| Symptom | Likely cause |
|---------|----------------|
| `no matches for kind "PipelineRun"` | Tekton Pipelines not installed — [step 2](#2-install-tekton-pipelines-on-the-cluster). |
| `tasks.tekton.dev "git-clone" not found` | Install catalog Tasks in **`jenkins`** — [step 5](#5-install-tekton-catalog-tasks-git-clone-kaniko). |
| `pipelineRun missing parameters: [git-url]` | Param name must be **`git-url`**. |
| `non-existent variable in $(params.git-url)` | Use **`$(params['git-url'])`** in the Pipeline. |
| `CouldntGetPipeline` / pipeline not found | Apply **`clone-build-push-kaniko.yaml`** first; delete stale PipelineRun. |
| Kaniko: no Dockerfile | Use **PVC** for `shared-data`, not emptyDir-only. |
| Git: permission denied on PVC | **`fsGroup: 65532`** on PipelineRun `podTemplate`. |
| Kaniko: `401` / `UNAUTHORIZED` to ACR | **`az acr login`**, recreate **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`**. |
| `render-from-config.py` fails | Install PyYAML: **`pip install -r requirements.txt`**. |

---

## Customizing for another service

1. Edit **`config-pipelinerun-auth-service.yaml`** (or copy it) with new Git URL, branch, and **`acr.imageRepo`** / **`imageTag`**.
2. Run **`python3 render-from-config.py`** and **`kubectl apply -f pipelinerun-auth-service.yaml`** (or use a new `metadata.name` to avoid replacing the same run).
3. Ensure the repo has a **`Dockerfile`** at the path you use (default `./Dockerfile` at repo root).

---

## Summary

| Step | Action |
|------|--------|
| 1 | Install **Tekton Pipelines** on AKS. |
| 2 | Create **`jenkins`** namespace, install **git-clone** + **kaniko** Tasks. |
| 3 | **ACR login** + create **`acr-dockerconfig`** and **`acr-dockerconfig-kaniko`** secrets. |
| 4 | Apply **`tekton-sa.yaml`**, **`clone-build-push-kaniko.yaml`**, then **`pipelinerun-auth-service.yaml`** (after **`render-from-config.py`** if you use config files). |

**Artifacts in this folder:** `tekton-sa.yaml`, `clone-build-push-kaniko.yaml`, `pipelinerun-auth-service.yaml`, **`config-*.yaml`**, **`render-from-config.py`**, **`requirements.txt`**.

Keep this directory in version control so you can repeat the same steps on a new cluster.
