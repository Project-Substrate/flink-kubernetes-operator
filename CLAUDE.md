# CLAUDE.md — flink-kubernetes-operator

## Purpose

The Apache Flink Kubernetes Operator manages the full lifecycle of Apache Flink streaming jobs on Kubernetes — deploy, upgrade, suspend, resume, and delete Flink Application, Session, and Job deployments via native Kubernetes custom resources. It also includes a Flink Job Autoscaler that dynamically adjusts parallelism based on observed throughput. Magnon uses this to operate real-time stream processing pipelines across Project-Substrate clusters.

## Tech Stack

- **Language:** Java (Maven multi-module, `org.apache.flink:flink-kubernetes-operator-parent` v1.14-SNAPSHOT)
- **Key modules:** `flink-kubernetes-operator` (controller), `flink-kubernetes-operator-api` (CRD types), `flink-kubernetes-webhook`, `flink-autoscaler`, `flink-autoscaler-plugin-jdbc`
- **Frameworks:** Java Operator SDK (JOSDK), Fabric8 Kubernetes client
- **Build:** Maven (`pom.xml` at root); Helm charts in `helm/`
- **Current API version:** `v1beta1`

## Dev Commands

```bash
# Build all modules (skip tests for speed)
mvn clean install -DskipTests

# Build and run all tests
mvn clean verify

# Run a specific module's tests
mvn test -pl flink-kubernetes-operator

# Build Docker image
mvn clean install -Pdocker -DskipTests

# Deploy via Helm (development cluster)
helm install flink-kubernetes-operator helm/flink-kubernetes-operator \
  --set image.repository=<registry>/flink-kubernetes-operator \
  --set image.tag=local

# Run e2e tests (requires a running cluster)
cd e2e-tests && ./run-e2e.sh
```

## Key Invariants

- The API is at `v1beta1`; all CRD changes must preserve backward compatibility — do not remove or rename fields without a deprecation cycle.
- Flink job upgrades are **stateful**: the operator triggers a savepoint before stopping the old job and restores from it when starting the new one. Never bypass the savepoint mechanism in production upgrade paths.
- The autoscaler scales based on the `backpressureTime` and `busyTime` metrics from the Flink REST API; do not change the scaling thresholds without load testing.
- Webhook validation runs on all `FlinkDeployment` and `FlinkSessionJob` creates/updates — changes to the webhook module require re-issuing TLS certs.
- The JDBC autoscaler plugin stores scaling history in the configured database; the schema is managed by Flyway migrations — never edit migration files already applied.

## What NOT To Do

- Do not set `spec.restartNonce` in automated tooling; it forces an unconditional restart and bypasses the savepoint flow.
- Do not modify `flink-kubernetes-operator-api` types without updating the generated CRD YAML in `helm/flink-kubernetes-operator/crds/` — the two must stay in sync.
- Do not run integration or e2e tests against a production cluster; they create and delete namespaces.
- Do not use `mvn -DskipTests` for release builds — all tests must pass before tagging.
- Do not change the operator's leader-election namespace without updating the Helm chart RBAC rules; the operator will fail to start.
