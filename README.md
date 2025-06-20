# Lido Finance Helm Charts Template

This repository contains a Helm chart template designed specifically for Lido Finance applications. It provides a standardized way to deploy and manage Lido Finance services on Kubernetes clusters.

## Overview

The template includes pre-configured settings for:

- Deployment configurations
- Service definitions
- Health checks and probes
- Resource management
- Ingress configurations
- Prometheus monitoring integration
- Pod Disruption Budget
- Horizontal Pod Autoscaler
- Service Monitor for Prometheus
- Security Context configurations

## Prerequisites

- Kubernetes cluster (version 1.19+)
- Helm 3.x
- Access to Lido Finance container registry
- Prometheus Operator (for ServiceMonitor support)

### Development Workflow

1. **Testing**

   - [ ] Run Helm lint:
     ```bash
     helm lint helm-chart/
     ```
   - [ ] Test template rendering:
     ```bash
     helm template lido-app helm-chart/
     ```
   - [ ] Validate values:
     ```bash
     helm template lido-app helm-chart/ --values helm-chart/values.yaml
     ```

2. **Build and Package**
   - [ ] Package the chart:
     ```bash
     helm package helm-chart/
     ```
   - [ ] Create index file:
     ```bash
     helm repo index . --url https://lido-artifactory/lido-app-template
     ```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter                       | Description                         | Default                  |
| ------------------------------- | ----------------------------------- | ------------------------ |
| `name`                          | Application name                    | `OVERRIDE-ME`            |
| `replicaCount`                  | Number of replicas                  | `1`                      |
| `maxSurge`                      | Max surge for deployment            | `1`                      |
| `maxUnavailable`                | Max unavailable for deployment      | `1`                      |
| `image.registry`                | Container registry                  | `harbor.k8s-sandbox.org` |
| `image.name`                    | Container image name                | `OVERRIDE-ME`            |
| `image.tag`                     | Container image tag                 | `OVERRIDE-ME`            |
| `image.pullPolicy`              | Image pull policy                   | `IfNotPresent`           |
| `service.type`                  | Kubernetes service type             | `ClusterIP`              |
| `service.ports`                 | Service ports configuration         | See values.yaml          |
| `resources`                     | CPU/Memory resource requests/limits | See values.yaml          |
| `terminationGracePeriodSeconds` | Pod termination grace period        | `30`                     |
| `securityContext`               | Pod security context settings       | See values.yaml          |
| `serviceAccount.name`           | Service account name                | `sa-lido-default`        |

### Health Checks

The chart includes pre-configured health checks:

- Startup probe: `/healthz` endpoint (port 8080)
  - failureThreshold: 3
  - periodSeconds: 3
- Liveness probe: `/healthz` endpoint (port 8080)
  - initialDelaySeconds: 3
  - periodSeconds: 3
- Readiness probe: `/healthz` endpoint (port 8080)
  - initialDelaySeconds: 3
  - periodSeconds: 3

### Monitoring

Prometheus monitoring is enabled by default with the following features:

- Service Monitor for Prometheus Operator integration
- Default metrics endpoint: `/_metrics`
- Liveness probe metrics: `/_livenessProbe`
- Prometheus scrape annotations on deployment

### Pod Disruption Budget

Pod Disruption Budget is enabled by default with:

- maxUnavailable: 1

### Horizontal Pod Autoscaler

Horizontal Pod Autoscaler is enabled by default with:

- minReplicas: 1
- maxReplicas: 3
- averageUtilization: 70%

### Ingress

Ingress is disabled by default. To enable it:

1. Set `ingress.enabled` to `true`
2. Configure your host and paths in the `ingress.rules` section
3. Optionally configure TLS
4. Default ingress class: `nginx-internal`

### Security Context

Default security context settings:

- runAsUser: 65534
- runAsGroup: 65534
- fsGroup: 65534
- readOnlyRootFilesystem: true (controls whether the container's root filesystem is mounted as read-only)

## Customization

To customize the deployment, create a custom values file:

```yaml
# custom-values.yaml
name: my-service
replicaCount: 2
image:
  name: my-service
  tag: v1.0.0
```

Then install using:

```bash
helm install lido-app lido-artifactory/lido-app-template --version 0.0.1 --values lido_app_value.yaml
```

# Future Improvements

- [ ] Add unit tests (helm-unittest)
- [ ] Add CI/CD pipeline for automated testing
- [ ] Implement automated version bumping (bumpversion)
- [ ] Implement automated documentation updates (helm-docs)
- [ ] Add support for multiple environments (dev, staging, prod)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact the Lido Finance DevOps team or create an issue in this repository.
