# Lido Finance Helm Charts Template

This repository contains a Helm chart template designed specifically for Lido Finance applications. It provides a standardized way to deploy and manage Lido Finance services on Kubernetes clusters.

Available templates:

- `helm-chart/` for application workloads that teams consume as a dependency in their service charts
- `alerts/` for a shared library chart that renders team `PrometheusRule` resources from parent-chart files
- `grafana-dashboards/` for a shared library chart that renders team Grafana dashboard `ConfigMap`s from parent-chart files
- `alertmanager-routes/` for a shared library chart that renders team `AlertmanagerConfig` resources (Alertmanager routing) from parent-chart files

## Overview

The template includes pre-configured settings for:

- Deployment configurations
- StatefulSet configurations
- Service definitions
- ConfigMap rendering
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
- Shared Alertmanager routing (AlertmanagerConfig) rendering helpers for team charts

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
     helm lint alertmanager-routes/
     ```
   - [ ] Test template rendering:
     ```bash
     helm template lido-app helm-chart/
     helm dependency build <team-alerts-chart>
     helm template team-alerts <team-alerts-chart> --values <team-alerts-chart>/values-k8s-<env>.yaml
     helm dependency build <team-grafana-dashboards-chart>
     helm template team-grafana-dashboards <team-grafana-dashboards-chart> --values <team-grafana-dashboards-chart>/values-k8s-<env>.yaml
     helm dependency build <team-alertmanager-routes-chart>
     helm template team-alertmanager-routes <team-alertmanager-routes-chart> --values <team-alertmanager-routes-chart>/values-k8s-<env>.yaml
     ```
   - [ ] Validate values:
     ```bash
     helm template lido-app helm-chart/ --values helm-chart/values.yaml
     helm lint alerts/
     helm lint grafana-dashboards/
     helm lint alertmanager-routes/
     ```

2. **Build and Package**
   - [ ] Package the chart:
     ```bash
     helm package helm-chart/
     helm package alerts/
     helm package grafana-dashboards/
     helm package alertmanager-routes/
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
| `replicas`                      | Number of replicas when HPA is disabled | `1`                  |
| `maxSurge`                      | Max surge for deployment            | `1`                      |
| `maxUnavailable`                | Max unavailable for deployment      | `1`                      |
| `deployment.strategy`           | Deployment rollout strategy override | `RollingUpdate`          |
| `statefulset.enabled`           | Enable StatefulSet rendering        | `false`                  |
| `statefulset.serviceName`       | StatefulSet governing Service name  | `name`                   |
| `statefulset.podManagementPolicy` | StatefulSet pod management policy | `nil`                    |
| `statefulset.updateStrategy`    | StatefulSet update strategy         | `RollingUpdate`          |
| `statefulset.volumeClaimTemplates` | Per-pod PVC templates for StatefulSet | `nil`                 |
| `PodDisruptionBudget.enabled`   | Enable PodDisruptionBudget           | `true`                   |
| `PodDisruptionBudget.minAvailable` | Minimum available pods; used as an effective default when neither policy is set | `1` |
| `PodDisruptionBudget.maxUnavailable` | Maximum unavailable pods          | `nil`                    |
| `image.name`                    | Container registry/image            | `OVERRIDE-ME`            |
| `image.tag`                     | Container image tag                 | `OVERRIDE-ME`            |
| `image.pullPolicy`              | Image pull policy                   | `IfNotPresent`           |
| `service.type`                  | Kubernetes service type             | `ClusterIP`              |
| `service.clusterIP`             | Service clusterIP override, e.g. `None` for headless Services | `nil`  |
| `service.publishNotReadyAddresses` | Publish pod addresses before readiness | `nil`                |
| `service.annotations`          | Service annotations; blackbox probing is opt-in | See values.yaml      |
| `service.ports`                 | Service ports configuration         | See values.yaml          |
| `resources`                     | CPU/Memory/Storage requests/limits  | See values.yaml          |
| `terminationGracePeriodSeconds` | Pod termination grace period        | `30`                     |
| `securityContext`               | Pod security context settings       | See values.yaml          |
| `serviceAccount.name`           | Service account name                | `sa-lido-default`        |
| `serviceAccount.automountServiceAccountToken` | Automount default Kubernetes API token | `false`       |
| `pvc.enabled`                   | Enable or disable PVC               | `false`                  |
| `pvcs`                          | List of PVCs, see values.yaml       | See values.yaml          |
| `containers`                    | List of containers with params      | See values.yaml          |
| `initContainers`                | List of initContainers with same shape as `containers`, probes optional | `nil` |
| `configMaps`                    | List of ConfigMaps to render        | `nil`                    |
| `affinity`                      | Kubernetes pod affinity and anti-affinity configuration | `{}`       |
| `containers[].command`          | Override container entrypoint       | `nil`                    |
| `servicemonitor.enabled`        | Enable ServiceMonitor rendering     | `true`                   |
| `servicemonitor.endpoints`      | ServiceMonitor endpoints            | See values.yaml          |
| `openbao.enabled`               | Enable OpenBao secret injection     | `false`                  |
| `openbao.annotations`           | OpenBao agent annotations           | `{}`                     |
| `openbao.serviceAccountToken.volumeName` | Projected token volume for OpenBao agent auth | `openbao-token` |
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
- Prometheus scrape annotations on deployment

Set `servicemonitor.enabled: false` when the workload must not create a ServiceMonitor.

Blackbox probing through Service annotations is opt-in so non-HTTP Services are not probed accidentally:

```yaml
service:
  annotations:
    prometheus.io/probe: "true"
    prometheus.io/path: /_livenessProbe
```

### Pod Disruption Budget

Pod Disruption Budget is enabled by default with:

- minAvailable: 1

It should be configured on a per-app per-env basis. For example, critical applications should normally keep at least one pod available, while singleton applications may need to disable the PDB.

Set at most one of `PodDisruptionBudget.maxUnavailable` or `PodDisruptionBudget.minAvailable`; setting both makes `helm template` fail. When neither is set, the chart renders `minAvailable: 1`. The PodDisruptionBudget is auto-suppressed when the effective max replicas — the max of `replicas` and, when HPA is enabled, `HorizontalPodAutoscaler.maxReplicas` — is `<= 1`, so a single-pod chart renders no PDB even with the default `enabled: true`.

When upgrading from a chart that used `minAvailable: 0` only to clear the inherited default alongside `maxUnavailable`, remove `minAvailable`; explicit zero is now treated as a configured value.

### Horizontal Pod Autoscaler

Horizontal Pod Autoscaler is enabled by default with:

- minReplicas: 1
- maxReplicas: 3
- averageUtilization: 70%

When `HorizontalPodAutoscaler.enabled` is `true`, the chart omits
`Deployment.spec.replicas` so that the HPA is the only controller managing the
replica count. Configure the lower bound with
`HorizontalPodAutoscaler.minReplicas`; the top-level `replicas` value is used
only when the HPA is disabled.

When upgrading to chart version 1.9.4 or later, no values schema changes are
required. If an HPA-enabled application previously relied on `replicas` as its
baseline, move that value to `HorizontalPodAutoscaler.minReplicas`. Also verify
that CPU requests represent normal application usage because CPU utilization
targets are calculated relative to the requests.

### PersistentVolumeClaim

PersistentVolumeClaim is disabled by default. To enable it:

1. Set `pvc.enabled` to `true`
2. Set list of PVCs with params under the `pvcs` value.

### Read-only root file system

Please keep in mind that `readOnlyRootFilesystem: true` will be enforced in the future. So if your containers need read-write access to some directories (e.g. cache or temp files) you need to mount them separately, please see values.yaml for examples.

### emptyDir volumes

The `require-emptydir-sizelimit` Kyverno policy (Audit) flags any `emptyDir` volume
without a `sizeLimit`. To keep manifests off that report by default, any `emptyDir`
under `volumes` that does not set its
own `sizeLimit` is rendered with `defaultEmptyDirSizeLimit` (default `1Gi`). Set a
per-volume `sizeLimit` to override, or tune `defaultEmptyDirSizeLimit` for the release.

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

### ConfigMaps and initContainers

Use `configMaps` to render small application configuration owned by the release. Values under `data` are rendered with Helm `tpl`, so they can refer to other chart values.

When `configMaps` is non-empty, the rendered ConfigMaps are checksummed into the Deployment or StatefulSet pod template. Changing their data therefore rolls the workload, including ConfigMaps mounted with `subPath`.

`initContainers` use the same shape as `containers`, including image defaults, command/args, env, resources, security context, and volume mounts. Unlike regular containers, readiness and liveness probes are optional.

### Pod affinity

`affinity` accepts the native Kubernetes affinity object and is applied to both Deployment and StatefulSet pods. For example, this preferred anti-affinity spreads replicas across nodes:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          topologyKey: kubernetes.io/hostname
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: my-app
```

### StatefulSet

StatefulSet rendering is opt-in with `statefulset.enabled: true`. Set `deployment.enabled: false` when the chart should render only the StatefulSet workload. `statefulset.serviceName` defaults to `name`; for stable pod DNS, pair it with a headless Service:

```yaml
deployment:
  enabled: false

statefulset:
  enabled: true
  serviceName: my-app
  podManagementPolicy: Parallel
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: longhorn-standard
        resources:
          requests:
            storage: 10Gi

service:
  clusterIP: None
  publishNotReadyAddresses: true
```

### Cronjobs

You can set up a list of cronjobs. It's basically containers that run on a schedule. All the values inside `containers` are the same as in Deployment listed above.

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

When OpenBao injection is enabled, the chart keeps `automountServiceAccountToken: false`
and adds a dedicated projected ServiceAccount token volume for the injected OpenBao
agent. The token carries a fixed `openbao` JWT audience matching the OpenBao Kubernetes
auth role, so it is not a valid kube-apiserver credential; the audience is owned by infra
and is not chart-configurable. The application containers do not mount this token unless
you explicitly add that mount yourself.

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

## Alertmanager Routes Template

Use `alertmanager-routes/` as a dependency in a team chart such as `csm-alertmanager-routes` in the team `helm-charts-*` repositories.

The parent team chart keeps:

- `files/*.yaml`
- `values-k8s-*.yaml`
- a thin wrapper template that calls the shared helper

Each route file holds an `AlertmanagerConfig` spec: the `route` and `receivers` keys in camelCase. prometheus-operator merges every team `AlertmanagerConfig` into the team Alertmanager, so a team writes and changes its own routing without an infra deploy.

To reduce boilerplate, the template also provides safe defaults:

- `name` defaults to the route file basename without `.yaml` or `.routes.yaml`
- `namespace` defaults to the Helm release namespace

### What infra provides and what teams bring

Infra owns the base routing on each team Alertmanager and it stays in place regardless of team routing: a matchers-less catch-all that pages the team's own OpsGenie, and a Watchdog deadman that reports to the SRE OpsGenie.

Teams bring their own routes and receivers. A team route is evaluated first and can notify Slack or Telegram; any alert a team does not route falls through to the infra catch-all. Teams do not manage the OpsGenie or deadman routing.

### Credentials

Receiver credentials are never set in the chart and never shipped as a Secret. Infra injects them into the team Alertmanager from OpenBao as files.

- Slack: omit the per-receiver `apiURL`; the route inherits the infra-injected Alertmanager `global.slack_api_url_file`.
- Telegram: set `botTokenFile` to `/vault/secrets/telegram`, the fixed path infra injects the token to. Telegram has no global, so the file is referenced per receiver.

Example values:

```yaml
alertmanagerConfigs:
  - file: files/example-routes.yaml
```

Example consumer chart:

```yaml
apiVersion: v2
name: alertmanager-routes
version: 1.0.0
type: application
dependencies:
  - name: alertmanager-routes
    alias: shared-alertmanager-routes
    version: 1.9.0
    repository: "oci://ghcr.io/lidofinance/helm-charts"
```

```yaml
{{ include "lido.alertmanagerRoutes.render" . }}
```

Render the `AlertmanagerConfig` into the team namespace. The team Alertmanager selects it through the namespace's `app.kubernetes.io/team` label, the same scoping used for team alert rules.

## ArgoCD

Teams should register the consumer dashboards, alerts, and alertmanager-routes charts alongside their application charts in `apps/apps.yaml`. Example:

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

- name: csm-alertmanager-routes
  type: helm
  chartPath: csm-alertmanager-routes
  repoURL: https://github.com/lidofinance/helm-charts-csm.git
  revision: "main"
```

Set the ArgoCD destination namespace to the team namespace so the rendered `PrometheusRule`, dashboard ConfigMaps, and `AlertmanagerConfig` are picked up by the team metrics, dashboards, and Alertmanager stacks automatically.

# Future Improvements

- [ ] Implement automated version bumping (bumpversion)
- [ ] Implement automated documentation updates (helm-docs)
- [ ] Add support for multiple environments (dev, staging, prod)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact the Lido Finance DevOps team or create an issue in this repository.
