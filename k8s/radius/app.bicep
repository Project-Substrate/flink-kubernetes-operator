import radius as radius 'br:ghcr.io/radius-project/bicep-types-radius/index.json:latest'

@description('Environment (dev | staging | production)')
param environment string

@description('Application name')
param appName string = 'flink-kubernetes-operator'

@description('Container registry')
param containerRegistry string = 'ghcr.io/project-substrate'

@description('Image tag')
param imageTag string = 'latest'

@description('Production flag — controls imagePullPolicy')
param production bool = false

@description('Kubernetes namespace')
param namespace string = 'flink-operator'

@description('Number of replicas')
param replicas int = 1

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: appName
  properties: {
    description: 'Project-Substrate flink-kubernetes-operator — Apache Flink operator managing FlinkDeployment/FlinkSessionJob CRDs; port 8080'
    environment: environment
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: namespace
      }
    ]
  }
}

resource container 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'flink-kubernetes-operator'
  properties: {
    application: app.id
    container: {
      image: '${containerRegistry}/flink-kubernetes-operator:${imageTag}'
      imagePullPolicy: production ? 'IfNotPresent' : 'Always'
      ports: {
        metrics: {
          containerPort: 8080
          protocol: 'TCP'
        }
      }
      env: {
        ENVIRONMENT: environment
        KAFKA_BOOTSTRAP_SERVERS: 'ifers-kafka-bootstrap.kafka.svc.cluster.local:9092'
      }
      readinessProbe: {
        httpGet: {
          path: '/'
          port: 8085
        }
        initialDelaySeconds: 10
        periodSeconds: 15
      }
      livenessProbe: {
        httpGet: {
          path: '/'
          port: 8085
        }
        initialDelaySeconds: 30
        periodSeconds: 30
      }
    }
    runtimes: {
      kubernetes: {
        pod: {
          containers: [
            {
              name: 'flink-kubernetes-operator'
              resources: {
                requests: {
                  cpu: '200m'
                  memory: '256Mi'
                }
                limits: {
                  cpu: '1000m'
                  memory: '1Gi'
                }
              }
            }
          ]
          replicas: replicas
        }
      }
    }
  }
}

output applicationId string = app.id
