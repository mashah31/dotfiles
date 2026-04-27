---
globs: "k8s/**"
---

# Kubernetes / Helm Rules (GKE + Cloud SQL)

## Every Deployment must have
- Rolling update strategy
- Non-root `securityContext` (drop ALL caps, read-only FS)
- Resource requests + limits
- Liveness, readiness, and startup probes

## Rules
- No hardcoded secrets in `values.yaml` — use `external-secrets` (Google Secret Manager)
- HPA + PDB required in prod
- Image tags pinned to git SHA — never `:latest`
- Cloud SQL for prod Postgres — never run your own Postgres in prod
- One Helm chart per service; share via `_helpers.tpl`
