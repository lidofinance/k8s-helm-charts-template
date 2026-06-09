# Changelog

## [1.5.7] - 04-06-2026

- Added: PodDisruptionBudget is auto-suppressed when the workload's effective max replicas is <= 1 (i.e. `replicas: 1` AND either HPA disabled or HPA `maxReplicas <= 1`). Prevents rendering ineffective PDBs for single-pod charts. No consumer values changes are required.
- Added: `helm template` now fails fast when both `PodDisruptionBudget.maxUnavailable` and `PodDisruptionBudget.minAvailable` are set (whenever the PDB is enabled, regardless of replica count), instead of producing an invalid PDB spec rejected at admission time.

## [1.5.6] - 19-05-2026

- Updating release-helmchart.yml github workflow; no functional changes.

## [1.5.5] - 19-05-2026

- Re-release of 1.5.4; no functional changes — 1.5.4 was never published.

## [1.5.4] - 13-05-2026

- Added: `serviceAccount.automountServiceAccountToken` (default `false`) on Deployment and CronJob templates so workloads no longer mount a Kubernetes API token by default.
- Added: dedicated projected ServiceAccount token volume for the OpenBao agent sidecar (configurable via `openbao.serviceAccountToken.volumeName` / `expirationSeconds`) so OpenBao injection continues to work when `automountServiceAccountToken: false`. The token volume is not mounted into application containers.

## [1.5.3] - 06-05-2026

- Fixed: PDB resource affected all Pods with label name. Even CronJobs.

## [1.5.2] - 05-05-2026

- Fixed: OpenBao sidecar container causing CronJobs to get stuck in the Progressing state.

## [1.5.1] - 24-04-2026

- Added CronJob support. See README.md and values.yaml for details.

## [1.4.1] - 15-04-2026

- Documented `ephemeral-storage` usage in chart values and README examples
- Added CI values and deployment tests covering `resources.requests/limits.ephemeral-storage`
- Added deployment test coverage for container-specific `containers[].resources.ephemeral-storage` overrides

## [1.4.0] - 10-04-2026

- Added support for `containers[].args` in the deployment template
- Added support for native Kubernetes `EnvVar` arrays via `containers[].env`
- Added `containers[].envMap` as a compatibility shortcut for simple key/value environment variables

## [1.3.9] - 03-04-2026

- Added support for `containers[].command` to override the container entrypoint in the deployment template
- Added example values and deployment tests covering command overrides

## [1.3.8] - 03-04-2026

- Fixed container image rendering in the deployment template so digest-based image references use `image@sha256:...` instead of a tag-style `image:sha256:...` format

## [1.3.7] - 26-03-2026

- Added support for container-level environment variables in the deployment template
- Added example `env` configuration and deployment tests for rendered environment variables

## [1.3.6] - 10-12-2025

- Added OCI chart publishing to GitHub Container Registry in the release workflow

## [1.3.5] - 04-12-2025

- Fixed the PodDisruptionBudget template so `maxUnavailable` and `minAvailable` are rendered only when explicitly set
- Added mandatory `team`, `app`, and `env` labels to the shared template labels
- Added `team` and `env` top-level values to support the new labels

## [1.3.4] - 04-12-2025

- Added OpenBao (Vault) agent injector configuration to chart values and documentation
- Added `minAvailable` support to the PodDisruptionBudget template and CI values
