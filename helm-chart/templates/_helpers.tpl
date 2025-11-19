{{- define "common.labels" -}}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "specific.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: {{ coalesce .Values.component .Values.name }}
{{ include "common.labels" . }}
{{- end -}}

