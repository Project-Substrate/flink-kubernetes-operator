# DEPRECATED — Helm Chart

This Helm chart for the Flink Kubernetes Operator is **deprecated and must not be used**.

**Reason:** Project-Substrate uses Kustomize + Bicep/Radius + ArgoCD. Helm is explicitly not part of the stack (see `k8s/CLAUDE.md`).

**Migration:** Use the Kustomize manifests in `k8s/base/flink-operator/` for deploying the Flink Kubernetes Operator. ArgoCD auto-syncs from `main`.

**Status:** Kept for historical reference only. Do not deploy.
