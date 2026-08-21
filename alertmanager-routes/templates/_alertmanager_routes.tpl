{{- define "lido.alertmanagerRoutes.render" -}}
{{- $root := . }}
{{- range $config := $root.Values.alertmanagerConfigs }}
{{- $filePath := required "alertmanagerConfigs[].file is required" $config.file }}
{{- $name := default (regexReplaceAll "(\\.routes?)?\\.ya?ml$" (base $filePath) "") $config.name }}
{{- $namespace := default $root.Release.Namespace $config.namespace }}
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: {{ $name }}
  namespace: {{ $namespace }}
spec:
{{ $root.Files.Get $filePath | fromYaml | toYaml | nindent 2 }}
---
{{- end }}
{{- end }}
