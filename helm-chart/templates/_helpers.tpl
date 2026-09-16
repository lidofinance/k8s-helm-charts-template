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
The cluster Kyverno policy require-emptydir-sizelimit (Audit) flags emptyDir
volumes without a sizeLimit, so this keeps rendered manifests off that report.
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

{{/*
Render app containers and initContainers from the chart's shared container shape.
Regular containers require readiness and liveness probes; initContainers do not.
*/}}
{{- define "chart.renderContainers" -}}
{{- $root := .root -}}
{{- $containers := .containers -}}
{{- $requireProbes := .requireProbes -}}
{{- range $i, $c := $containers }}
{{- $imageName := coalesce ($c.image.name | default $root.Values.image.name) }}
{{- $imageTag := default $root.Values.image.tag $c.image.tag }}
{{- $containerName := default $root.Values.name $c.name }}
{{- if and $requireProbes (not $c.readinessProbe) }}{{- fail (printf "container %q: readinessProbe is required" $containerName) -}}{{- end }}
{{- if and $requireProbes (not $c.livenessProbe) }}{{- fail (printf "container %q: livenessProbe is required" $containerName) -}}{{- end }}
- name: {{ $containerName }}
  image: {{ if regexMatch "^sha256:[a-fA-F0-9]{64}$" ($imageTag | toString) }}{{ printf "%s@%s" $imageName ($imageTag | toString) | quote }}{{ else }}{{ printf "%s:%s" $imageName ($imageTag | toString) | quote }}{{ end }}
  imagePullPolicy: {{ default "Always" $c.imagePullPolicy }}
  securityContext:
    runAsNonRoot: true
    privileged: false
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
    seccompProfile:
      type: RuntimeDefault
    appArmorProfile:
      type: RuntimeDefault
    readOnlyRootFilesystem: {{ default $root.Values.securityContext.readOnlyRootFilesystem (and $c.securityContext $c.securityContext.readOnlyRootFilesystem) }}
    {{- with $c.securityContext }}
    {{- with .runAsUser }}
    runAsUser: {{ . }}
    {{- end }}
    {{- with .runAsGroup }}
    runAsGroup: {{ . }}
    {{- end }}
    {{- end }}
  {{- with $c.ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- else }}
  resources:
    {{- $root.Values.resources | toYaml | nindent 4 }}
  {{- end }}
  {{- if $c.env }}
  env:
    {{- if kindIs "slice" $c.env }}
    {{- toYaml $c.env | nindent 4 }}
    {{- else }}
    {{- range $key, $value := $c.env }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
    {{- end }}
  {{- else if $c.envMap }}
  env:
    {{- range $key, $value := $c.envMap }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- with $c.command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.args }}
  args:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $c.volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "chart.workloadKind" -}}
{{- if .Values.statefulset.enabled -}}StatefulSet{{- else -}}Deployment{{- end -}}
{{- end -}}

{{- define "chart.workloadResourceLabel" -}}
{{- if .Values.statefulset.enabled -}}statefulset{{- else -}}deployment{{- end -}}
{{- end -}}
