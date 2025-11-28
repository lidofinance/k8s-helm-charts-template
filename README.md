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
- Persistent Volume Claims for storage
- OpenBao (Vault) Agent Injector for secret management

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
| `replicas`                      | Number of replicas                  | `1`                      |
| `maxSurge`                      | Max surge for deployment            | `1`                      |
| `maxUnavailable`                | Max unavailable for deployment      | `1`                      |
| `image.name`                    | Container registry/image            | `OVERRIDE-ME`            |
| `image.tag`                     | Container image tag                 | `OVERRIDE-ME`            |
| `image.pullPolicy`              | Image pull policy                   | `IfNotPresent`           |
| `service.type`                  | Kubernetes service type             | `ClusterIP`              |
| `service.ports`                 | Service ports configuration         | See values.yaml          |
| `resources`                     | CPU/Memory resource requests/limits | See values.yaml          |
| `terminationGracePeriodSeconds` | Pod termination grace period        | `30`                     |
| `securityContext`               | Pod security context settings       | See values.yaml          |
| `serviceAccount.name`           | Service account name                | `sa-lido-default`        |
| `pvc.enabled`                   | Enable or disable PVC               | `false`                  |
| `pvcs`                          | List of PVCs, see values.yaml       | See values.yaml          |
| `containers`                    | List of containers with params      | See values.yaml          |
| `servicemonitor.endpoints`      | List of ServiceMonitors             | See values.yaml          |
| `openbao.enabled`               | Enable OpenBao secret injection     | `false`                  |
| `openbao.annotations`           | OpenBao agent annotations           | `{}`                     |

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

- Service Monitor for Prometheus Operator integration (Can be configured with additional endpoints)
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

### PersistentVolumeClaim

PersistentVolumeClaim is disabled by default. To enable it:

1. Set `pvc.enabled` to `true`
2. Set list of PVCs with params under the `pvcs` value.

### Read-only root file system

Please keep in mind that `readOnlyRootFilesystem: true` will be enforced in the future. So if your containers need read-write access to some directories (e.g. cache or temp files) you need to mount them separately, please see values.yaml for examples.

### Ingress

Ingress is disabled by default. To enable it:

1. Set `ingress.enabled` to `true`
2. Configure your host and paths in the `ingress.rules` section
3. Optionally configure TLS
4. Default ingress class: `nginx-internal`

### Containers

The template supports multiple containers within one Pod. You can set a list of containers under the `cotainers` value with their own name, image, tags, probes, volumes, etc. See values.yaml for examples.

### OpenBao (Vault) Secret Injection

OpenBao Agent Injector is disabled by default. To enable it:

1. Set `openbao.enabled` to `true`
2. Configure annotations in the `openbao.annotations` section

**Example configuration:**

```yaml
openbao:
  enabled: true
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "<TEAMNAME>-team-ro"
    vault.hashicorp.com/agent-inject-secret-app: "secret/data/<TEAMNAME>-team/<APPNAME>-app/<SECRETS>"
    vault.hashicorp.com/agent-pre-populate: "true"
    vault.hashicorp.com/template-static-secret-render-interval: "30s"
    vault.hashicorp.com/agent-inject-template-app: |
      {{`{{- with secret "secret/data/<TEAMNAME>-team/<APPNAME>-app/<SECRETS>" -}}`}}
      {{`{{- range $k, $v := .Data.data -}}`}}
      {{`export `}}{{`{{ $k }}`}}{{`="{{ $v }}"`}}
      {{`{{ end -}}`}}
      {{`{{- end -}}`}}
```

**Using secrets in your container:**

```yaml
containers:
  - name: my-app
    image:
      name: nginx
      tag: 1.29.3
    command: ["/bin/bash", "-c"]
    args:
      - |
        set -euo pipefail
        # Wait for secrets to be injected
        while [ ! -f /vault/secrets/app ]; do
          sleep 0.1
        done

        # Load secrets as environment variables
        . /vault/secrets/app

        # Start your application
        exec nginx -g 'daemon off;'
```

**Optional: Reload application on secret update**

To reload your application when secrets are updated, add the reload command annotation:

```yaml
openbao:
  enabled: true
  annotations:
    # ... other annotations ...
    vault.hashicorp.com/agent-inject-command-app: |
      kill -HUP $(pidof nginx)
```

### Security Context

Default security context settings:

- runAsUser: 65534
- runAsGroup: 65534
- fsGroup: 65534
- fsGroupChangePolicy: OnRootMismatch
- readOnlyRootFilesystem: true (controls whether the container's root filesystem is mounted as read-only)
- runAsNonRoot: true (force non-root user)
- allowPrivilegeEscalation: false (block `setuid` or `sudo` actions)
- capabilities:
    drop: ["ALL"] (drop all capabilities)
- seccompProfile:
    type: RuntimeDefault (default seccomp profile)
- appArmorProfile:
    type: RuntimeDefault (default apparmor profile)

## Customization

To customize the deployment, create a custom values file:

```yaml
# custom-values.yaml
name: my-service
replicas: 2
image:
  name: my-service
  tag: v1.0.0
```

Then install using:

```bash
helm install lido-app lido-artifactory/lido-app-template --version 0.0.1 --values lido_app_value.yaml
```

# Future Improvements

- [ ] Implement automated version bumping (bumpversion)
- [ ] Implement automated documentation updates (helm-docs)
- [ ] Add support for multiple environments (dev, staging, prod)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact the Lido Finance DevOps team or create an issue in this repository.
