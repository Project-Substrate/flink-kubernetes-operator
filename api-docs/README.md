# flink-kubernetes-operator API docs (local Redoc viewer)

`index.html` is a static, dependency-free [Redoc](https://github.com/Redocly/redoc)
viewer for `../openapi.yaml`. Open it directly in a browser (or serve the repo
root with any static file server) to browse the spec.

## What this is

- A read-only rendering of the checked-in `openapi.yaml`.
- Accessible by default: skip link to the reference content, a focusable
  `<main>` landmark, a `<noscript>` fallback that links straight to the raw
  spec, and a `prefers-reduced-motion` safe skip-link transition.

## What this is *not*

- **Not wired into any deployment.** No Service/Ingress serves this page
  today.
- **Not a description of the operator's real behavior.** This repo is the
  upstream Apache Flink Kubernetes operator; its primary interface is
  Kubernetes CRDs (`FlinkDeployment`, `FlinkSessionJob`, etc.) reconciled by
  controllers, not a bespoke REST API. `../openapi.yaml` documents only
  `/healthz` and `/metrics` and carries a literal `[TODO: Add detailed
  description]` placeholder in `info.description`. The `bearerAuth` security
  scheme is declared but not demonstrably wired to any specific route in the
  spec — noted here rather than "fixed" by guessing which routes it gates.
- **No auth story beyond the declared scheme.** Not verified against the
  running operator here.

## Gaps / follow-ups (not fabricated, just not done)

1. No CI job renders or lints this page (the repo's own `e2e-tests/` are
   Kubernetes integration scripts, not doc checks).
2. `info.description` still contains the literal `[TODO: Add detailed
   description]` placeholder — left as-is rather than inventing
   operator-specific prose.
3. No deployment/serving path.
4. Whether an HTTP API surface beyond health/metrics is the right model for
   this operator (vs. documenting the CRD schemas it reconciles, which is
   how the upstream Flink operator project actually documents itself) is an
   open question this change does not attempt to answer.
