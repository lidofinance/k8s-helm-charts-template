{{- define "common.labels" -}}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "specific.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: {{ coalesce .Values.component .Values.name }}
team: {{ .Values.team }}
app: {{ .Values.name }}
env: {{ .Values.env }}
{{ include "common.labels" . }}
{{- end -}}

{{/*
Render a volumes list, defaulting a sizeLimit onto any emptyDir that omits one.
The cluster Kyverno policy require-emptydir-sizelimit (Enforce) rejects emptyDir
volumes without a sizeLimit, so this guarantees rendered manifests comply.
Usage: include "chart.renderVolumes" (dict "volumes" .Values.volumes "default" .Values.defaultEmptyDirSizeLimit)
*/}}
{{- define "chart.renderVolumes" -}}
{{- $default := .default -}}
{{- $volumes := .volumes -}}
{{- range $volumes -}}
{{- if hasKey . "emptyDir" -}}
{{- $ed := .emptyDir | default dict -}}
{{- if not $ed.sizeLimit -}}
{{- $_ := set $ed "sizeLimit" $default -}}
{{- $_ := set . "emptyDir" $ed -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $volumes -}}
{{- end -}}

