# Changelog

## [1.4.0]

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
