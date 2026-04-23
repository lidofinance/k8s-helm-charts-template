# Lido Finance Helm Charts Template

This repository contains a Helm chart template designed specifically for Lido Finance applications. It provides a standardized way to deploy and manage Lido Finance services on Kubernetes clusters.

Available templates:

- `helm-chart/` for application workloads that teams consume as a dependency in their service charts
- `alerts/` for a shared library chart that renders team `PrometheusRule` resources from parent-chart files
- `grafana-dashboards/` for a shared library chart that renders team Grafana dashboard `ConfigMap`s from parent-chart files

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
- Shared Grafana dashboard rendering helpers for team charts
- Shared Prometheus alert rule rendering helpers for team charts

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
     helm lint alerts/
     helm lint grafana-dashboards/
     ```
   - [ ] Test template rendering:
     ```bash
     helm template lido-app helm-chart/
     helm dependency build <team-alerts-chart>
     helm template team-alerts <team-alerts-chart> --values <team-alerts-chart>/values-k8s-<env>.yaml
     helm dependency build <team-grafana-dashboards-chart>
     helm template team-grafana-dashboards <team-grafana-dashboards-chart> --values <team-grafana-dashboards-chart>/values-k8s-<env>.yaml
     ```
   - [ ] Validate values:
     ```bash
     helm template lido-app helm-chart/ --values helm-chart/values.yaml
     helm lint alerts/
     helm lint grafana-dashboards/
     ```

2. **Build and Package**
   - [ ] Package the chart:
     ```bash
     helm package helm-chart/
     helm package alerts/
     helm package grafana-dashboards/
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
| `minAvailable`                  | Max available for deployment        | `1`                      |
| `image.name`                    | Container registry/image            | `OVERRIDE-ME`            |
| `image.tag`                     | Container image tag                 | `OVERRIDE-ME`            |
| `image.pullPolicy`              | Image pull policy                   | `IfNotPresent`           |
| `service.type`                  | Kubernetes service type             | `ClusterIP`              |
| `service.ports`                 | Service ports configuration         | See values.yaml          |
| `resources`                     | CPU/Memory/Storage requests/limits  | See values.yaml          |
| `terminationGracePeriodSeconds` | Pod termination grace period        | `30`                     |
| `securityContext`               | Pod security context settings       | See values.yaml          |
| `serviceAccount.name`           | Service account name                | `sa-lido-default`        |
| `pvc.enabled`                   | Enable or disable PVC               | `false`                  |
| `pvcs`                          | List of PVCs, see values.yaml       | See values.yaml          |
| `containers`                    | List of containers with params      | See values.yaml          |
| `containers[].command`          | Override container entrypoint       | `nil`                    |
| `servicemonitor.endpoints`      | List of ServiceMonitors             | See values.yaml          |
| `openbao.enabled`               | Enable OpenBao secret injection     | `false`                  |
| `openbao.annotations`           | OpenBao agent annotations           | `{}`                     |
| `cronjobs`                      | List of cronjobs with params      | See values.yaml          |

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

It should be configured on a per-app per-env basis. For example apps in critical should probably have minAvailable >=1. But there are some exceptions like singlton apps. Keep in mind that you can't set up both maxUnavailable and minAvailable.

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

The template supports multiple containers within one Pod. You can set a list of containers under the `containers` value with their own name, image, env, tags, probes, volumes, etc. See values.yaml for examples.

Use `env` for native Kubernetes `EnvVar` entries when you need `valueFrom`, ordering or the same structure as a regular Deployment. For simple string key/value pairs `envMap` is available as a compatibility shortcut.

You can also override the container entrypoint using `command` (Kubernetes equivalent of Docker ENTRYPOINT):

```yaml
containers:
  - name: my-app
    image:
      name: nginx
      tag: 1.29.3
    command:
      - /bin/sh
      - -ec
    args:
      - echo "Hello world" && exec nginx -g 'daemon off;'
    env:
      - name: PORT
        value: "8080"
    envMap:
      FEATURE_X_ENABLED: "true"
```

### Cronjobs

You can setup a list of cronjobs. It's basically containers that run on a schedule. All the values inside `containers` are the same as in Deployment listed above.

### Ephemeral Storage

The chart passes the `resources` map to Kubernetes as-is, so you can use standard resource keys such as `ephemeral-storage` both globally and per container.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
    ephemeral-storage: 512Mi
  limits:
    cpu: 200m
    memory: 256Mi
    ephemeral-storage: 1Gi
```

If only one container needs a different value, set `containers[].resources`. Explicit container values take precedence over namespace `LimitRange` defaults (for now it's 3GiB).

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
helm install lido-app oci://ghcr.io/lidofinance/helm-charts --version 1.3.9 --values lido_app_value.yaml
```

Installation as a helm dependency(`Chart.yaml` example):
```yaml
apiVersion: v2
name: lido-app
version: 1.0.0
type: application
dependencies:
  - name: k8s-helm-charts-template
    alias: overrides
    version: 1.3.9
    repository: "oci://ghcr.io/lidofinance/helm-charts"
```

Published charts from this repository should follow the repository release tag version, for example `1.3.9`.
Team charts in `helm-charts-*` can keep their own local chart version such as `1.0.0`, but their dependency version should point to the published library chart version.

## Grafana Dashboards Template

Use `grafana-dashboards/` as a dependency in charts such as `csm-grafana-dashboards` in the team `helm-charts-*` repositories.

The parent team chart keeps:

- `dashboards/*.json`
- `values-k8s-*.yaml`
- a thin wrapper template that calls the shared helper

The shared library renders one ConfigMap per dashboard file with:

- label `grafana_dashboard: "1"`
- annotation `grafana_folder`

This matches the existing Grafana sidecar configuration in `k8s-infra/l2`, so ArgoCD only needs to deploy the team chart into the team namespace for dashboards to be discovered automatically.

Dashboard files live under `dashboards/`. Existing JSON dashboards from the old non-Kubernetes alerts-box layout can be copied there as-is and then referenced from values.

The values shape matches the monitoring charts already used in `helm-charts-csm`, `helm-charts-qa`, and `helm-charts-infra`.

To reduce boilerplate, the template also provides safe defaults:

- `name` defaults to `grafana-dashboard-<file basename without .json>`
- `namespace` defaults to the Helm release namespace
- `fileKey` defaults to the dashboard file basename
- `labels.grafana_dashboard` defaults to `"1"`
- `annotations.grafana_folder` defaults to `Custom`

Example values:

```yaml
configmapsFromFiles:
  - filePath: dashboards/application-overview.json
```

Example consumer chart:

```yaml
apiVersion: v2
name: grafana-dashboards
version: 1.0.0
type: application
dependencies:
  - name: grafana-dashboards
    alias: shared-grafana-dashboards
    version: 1.3.9
    repository: "oci://ghcr.io/lidofinance/helm-charts"
```

```yaml
{{ include "lido.grafanaDashboards.render" . }}
```

## Prometheus Alerts Template

Use `alerts/` as a dependency in charts such as `csm-alerts` in the team `helm-charts-*` repositories.

The parent team chart keeps:

- `files/*.yaml`
- `values-k8s-*.yaml`
- a thin wrapper template that calls the shared helper

Alert rule files live under `files/` and must contain the `PrometheusRule.spec` payload starting with `groups:`. Existing alert files from the old infra layout can be moved here after adapting expressions and labels to the Kubernetes metrics model.

The values shape matches the current team alerts charts.

To reduce boilerplate, the template also provides safe defaults:

- `name` defaults to the alert file basename without `.yaml` or `.rule.yaml`
- `namespace` defaults to the Helm release namespace

Example values:

```yaml
alertRules:
  - file: files/example-alert.yaml
```

Example consumer chart:

```yaml
apiVersion: v2
name: alerts
version: 1.0.0
type: application
dependencies:
  - name: alerts
    alias: shared-alerts
    version: 1.3.9
    repository: "oci://ghcr.io/lidofinance/helm-charts"
```

```yaml
{{ include "lido.alerts.render" . }}
```

Team Prometheus stacks discover these rules from namespaces labeled with `app.kubernetes.io/team`, which is how the current `k8s-infra/l2` setup scopes team monitoring.

## ArgoCD

Teams should register the consumer dashboards and alerts charts alongside their application charts in `apps/apps.yaml`. Example:

```yaml
- name: csm-alerts
  type: helm
  chartPath: csm-alerts
  repoURL: https://github.com/lidofinance/helm-charts-csm.git
  revision: "main"

- name: csm-grafana-dashboards
  type: helm
  chartPath: csm-grafana-dashboards
  repoURL: https://github.com/lidofinance/helm-charts-csm.git
  revision: "main"
```

Set the ArgoCD destination namespace to the team namespace so the rendered `PrometheusRule` and dashboard ConfigMaps are picked up by the team metrics and dashboards stacks automatically.

# Future Improvements

- [ ] Implement automated version bumping (bumpversion)
- [ ] Implement automated documentation updates (helm-docs)
- [ ] Add support for multiple environments (dev, staging, prod)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact the Lido Finance DevOps team or create an issue in this repository.
