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

## Prerequisites

- Kubernetes cluster (version 1.19+)
- Helm 3.x
- Access to Lido Finance container registry

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

| Parameter        | Description                         | Default                  |
| ---------------- | ----------------------------------- | ------------------------ |
| `name`           | Application name                    | `OVERRIDE-ME`                    |
| `replicaCount`   | Number of replicas                  | `1`                      |
| `image.registry` | Container registry                  | `harbor.k8s-sandbox.org` |
| `image.name`     | Container image name                | `OVERRIDE-ME`            |
| `image.tag`      | Container image tag                 | `OVERRIDE-ME`            |
| `service.type`   | Kubernetes service type             | `ClusterIP`              |
| `service.ports`  | Service ports configuration         | See values.yaml          |
| `resources`      | CPU/Memory resource requests/limits | See values.yaml          |

### Health Checks

The chart includes pre-configured health checks:

- Startup probe: `/healthz` endpoint
- Liveness probe: `/healthz` endpoint
- Readiness probe: `/healthz` endpoint

### Monitoring

Prometheus monitoring is enabled by default with the following annotations:

- `prometheus.io/scrape: "true"`
- `prometheus.io/path: "/_metrics"`

### Ingress

Ingress is disabled by default. To enable it:

1. Set `ingress.enabled` to `true`
2. Configure your host and paths in the `ingress.rules` section
3. Optionally configure TLS

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
helm install lido-app lido-artifactory/lido-app-templat --version 0.0.1 --values lido_app_value.yaml
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

