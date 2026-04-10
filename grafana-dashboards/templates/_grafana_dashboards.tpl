{{- define "lido.grafanaDashboards.render" -}}
{{- $root := . }}
{{- $defaultFolder := default "Custom" $root.Values.defaultFolder }}
{{- range $configmap := $root.Values.configmapsFromFiles }}
{{- $filePath := required "configmapsFromFiles[].filePath is required" $configmap.filePath }}
{{- $fileName := base $filePath }}
{{- $name := default (printf "grafana-dashboard-%s" (regexReplaceAll "\\.json$" $fileName "")) $configmap.name }}
{{- $namespace := default $root.Release.Namespace $configmap.namespace }}
{{- $labels := dict "grafana_dashboard" "1" }}
{{- with $configmap.labels }}
{{- $labels = mergeOverwrite $labels . }}
{{- end }}
{{- $annotations := dict "grafana_folder" $defaultFolder }}
{{- with $configmap.annotations }}
{{- $annotations = mergeOverwrite $annotations . }}
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $name }}
  namespace: {{ $namespace }}
  labels:
    {{- range $k, $v := $labels }}
    {{ $k }}: {{ $v | quote }}
    {{- end }}
  annotations:
    {{- range $k, $v := $annotations }}
    {{ $k }}: {{ $v | quote }}
    {{- end }}
data:
  {{ default $fileName $configmap.fileKey }}: |
{{ $root.Files.Get $filePath | nindent 4 }}
---
{{- end }}
{{- end }}
