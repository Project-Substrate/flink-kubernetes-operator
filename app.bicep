// =============================================================================
// Substrate — flink-kubernetes-operator Radius Application Definition
// =============================================================================
// Flink Kubernetes Operator service (port 8080).
//
// Usage:
//   rad deploy app.bicep --parameters environment=substrate-prod imageTag=latest
// =============================================================================
import radius as radius from 'br:ghcr.io/radius-project/bicep-types-radius/index.json'

@description('Radius environment name')
param environment string

@description('Application name')
param application string = 'substrate-flink-kubernetes-operator'

@description('Container registry')
param containerRegistry string = 'ghcr.io/project-substrate'

@description('Image tag')
param imageTag string = 'latest'

@description('Kubernetes namespace')
param namespace string = 'substrate'

@description('Replica count')
param replicas int = 1

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: application
  properties: {
    environment: environment
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: namespace
      }
    ]
  }
}

resource otelCollector 'Applications.Core/extenders@2023-10-01-preview' = {
  name: 'otel-collector'
  properties: {
    application: app.id
    environment: environment
    resourceProvisioning: 'manual'
    kind: 'otel-collector'
    endpoint: 'http://otel-collector.otel-system.svc.cluster.local:4317'
    protocol: 'grpc'
  }
}

resource container 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'flink-kubernetes-operator'
  properties: {
    application: app.id
    container: {
      image: '${containerRegistry}/flink-kubernetes-operator:${imageTag}'
      imagePullPolicy: 'Always'
      ports: {
        http: {
          containerPort: 8080
          protocol: 'TCP'
        }
      }
      env: {
        ENVIRONMENT: { value: environment }
        PORT: { value: '8080' }
        OTEL_SERVICE_NAME: { value: 'flink-kubernetes-operator' }
        OTEL_EXPORTER_OTLP_ENDPOINT: { value: 'http://otel-collector.otel-system.svc.cluster.local:4317' }
        LOG_FORMAT: { value: 'json' }
        LOG_LEVEL: { value: 'INFO' }
        OTEL_TRACES_SAMPLER: { value: 'parentbased_traceidratio' }
        OTEL_TRACES_SAMPLER_ARG: { value: '0.1' }
        OTEL_METRICS_EXPORTER: { value: 'otlp' }
        OTEL_LOGS_EXPORTER: { value: 'otlp' }
      }
      readinessProbe: {
        httpGet: { path: '/healthz', port: 8080 }
        initialDelaySeconds: 10
        periodSeconds: 10
      }
      livenessProbe: {
        httpGet: { path: '/healthz', port: 8080 }
        initialDelaySeconds: 20
        periodSeconds: 30
      }
    }
    connections: {
      otel: { source: otelCollector.id }
    }
    runtimes: {
      kubernetes: {
        pod: {
          containers: [
            {
              name: 'flink-kubernetes-operator'
              resources: {
                requests: { cpu: '100m', memory: '256Mi' }
                limits: { cpu: '500m', memory: '512Mi' }
              }
            }
          ]
          replicas: replicas
          imagePullSecrets: [{ name: 'ghcr-pull-secret' }]
        }
      }
    }
  }
}

output applicationId string = app.id
output serviceEndpoint string = 'http://flink-kubernetes-operator.${namespace}.svc.cluster.local:8080'
