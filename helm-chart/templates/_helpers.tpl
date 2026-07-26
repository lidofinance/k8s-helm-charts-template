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

{{- /*
User-supplied extra labels. Call with (dict "root" $ "extra" <optional per-object map>).
Per-object keys win over the global .Values.labels map; a null or empty per-object
value removes the key, so one object can opt out of a globally set label.
Kept out of every selector: selectors are immutable (Deployment) or must keep
matching objects rendered by older chart versions (ServiceMonitor).
Chart-managed label keys and label keys/values that Kubernetes would reject
fail the render instead of failing at admission time.
*/ -}}
{{- define "lido.userLabels" -}}
{{- $merged := dict -}}
{{- range $k, $v := (.root.Values.labels | default dict) }}{{- $_ := set $merged $k $v }}{{- end -}}
{{- range $k, $v := (.extra | default dict) }}{{- $_ := set $merged $k $v }}{{- end -}}
{{- $reserved := list "app.kubernetes.io/name" "app.kubernetes.io/component" "app.kubernetes.io/version" "app.kubernetes.io/instance" "app.kubernetes.io/managed-by" "helm.sh/chart" "team" "app" "env" "resource" -}}
{{- $lines := list -}}
{{- range $k, $v := $merged -}}
{{- if has $k $reserved }}{{ fail (printf "labels: key %q is chart-managed and cannot be overridden" $k) }}{{ end -}}
{{- if not (regexMatch `^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?[a-zA-Z0-9]([-a-zA-Z0-9_.]{0,61}[a-zA-Z0-9])?$` $k) }}{{ fail (printf "labels: %q is not a valid label key" $k) }}{{ end -}}
{{- if not (kindIs "invalid" $v) -}}
{{- $s := $v | toString -}}
{{- if ne $s "" -}}
{{- if not (regexMatch `^[a-zA-Z0-9]([-a-zA-Z0-9_.]{0,61}[a-zA-Z0-9])?$` $s) }}{{ fail (printf "labels: value %q of key %q is not a valid label value" $s $k) }}{{ end -}}
{{- $lines = append $lines (printf "%s: %s" ($k | quote) ($s | quote)) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- join "\n" $lines -}}
{{- end -}}

