{{- define "lido.blackbox.validate" -}}
{{- $check := .check -}}
{{- $name := required "checks[].name is required" $check.name -}}
{{- if not (regexMatch "^(http|dns|tcp|icmp)_[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$" $name) -}}
{{- fail (printf "check name %q must be <proto>_<host>, proto one of http|dns|tcp|icmp, host made of letters, digits, dots and hyphens (it becomes the object name)" $name) -}}
{{- end -}}
{{- $module := required (printf "checks[].module is required (check %q)" $name) $check.module -}}
{{- $proto := regexSplit "[._]" $module -1 | first -}}
{{- if not (has $proto (list "http" "dns" "tcp" "icmp")) -}}
{{- fail (printf "module %q in check %q has unsupported protocol prefix; valid: http, dns, tcp, icmp" $module $name) -}}
{{- end -}}
{{- $_ := required (printf "checks[].target is required (check %q)" $name) $check.target -}}
{{- $sensitivity := $check.sensitivity | default "medium" -}}
{{- if not (has $sensitivity (list "none" "low" "medium" "high")) -}}
{{- fail (printf "invalid sensitivity %q in check %q; valid: none, low, medium, high" $sensitivity $name) -}}
{{- end -}}
{{- $severity := $check.severity | default "normal" -}}
{{- if not (has $severity (list "warning" "minor" "normal" "major" "critical")) -}}
{{- fail (printf "invalid severity %q in check %q; valid: warning, minor, normal, major, critical" $severity $name) -}}
{{- end -}}
{{- with $check.interval -}}
{{- if not (regexMatch "^[0-9]+s$" .) -}}
{{- fail (printf "interval %q in check %q must be seconds, e.g. 30s" . $name) -}}
{{- end -}}
{{- if gt (. | trimSuffix "s" | int) 60 -}}
{{- fail (printf "interval %q in check %q must be at most 60s" . $name) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $check "timeout" -}}
{{- fail (printf "timeout is forbidden in check %q (scrape timeout is platform-managed)" $name) -}}
{{- end -}}
{{- if hasKey $check "scrape_timeout" -}}
{{- fail (printf "scrape_timeout is forbidden in check %q (scrape timeout is platform-managed)" $name) -}}
{{- end -}}
{{- range $key, $_ := $check.extraLabels -}}
{{- if or (hasPrefix "__" $key) (has $key (list "team" "job" "target" "module" "sensitivity" "severity" "env")) -}}
{{- fail (printf "extraLabels key %q in check %q is reserved" $key $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Render a ScrapeConfig per .Values.checks entry. */}}
{{- define "lido.blackbox.render" -}}
{{- $root := . -}}
{{- $seen := dict -}}
{{/* Library values don't merge into the parent scope, so default the mount path here. */}}
{{- $sensorsPath := $root.Values.sensorsPath | default "/etc/prometheus/configmaps/blackbox-sensors" -}}
{{- range $check := $root.Values.checks }}
{{- include "lido.blackbox.validate" (dict "check" $check) }}
{{- $objName := $check.name | replace "_" "-" | lower }}
{{- if hasKey $seen $objName }}
{{- fail (printf "check name %q collides with another after normalization (%q)" $check.name $objName) }}
{{- end }}
{{- $_ := set $seen $objName true }}
{{- $proto := regexSplit "_" $check.name -1 | first }}
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: {{ $objName }}
  namespace: {{ $root.Release.Namespace }}
spec:
  metricsPath: /probe
  scheme: HTTP
{{- with $check.interval }}
  scrapeInterval: {{ . | quote }}
{{- end }}
  params:
    module:
      - {{ $check.module | quote }}
    target:
      - {{ $check.target | quote }}
  fileSDConfigs:
    - files:
        - {{ printf "%s/%s-*.yml" $sensorsPath $proto | quote }}
  relabelings:
    # Preserve the check name as the job label; the operator would otherwise
    # set job to scrapeConfig/<namespace>/<name>.
    - targetLabel: job
      replacement: {{ $check.name | quote }}
    - sourceLabels:
        - __param_target
      targetLabel: target
    - sourceLabels:
        - __param_module
      targetLabel: module
    - targetLabel: sensitivity
      replacement: {{ $check.sensitivity | default "medium" | quote }}
    - targetLabel: severity
      replacement: {{ $check.severity | default "normal" | quote }}
{{- with $root.Values.env }}
    - targetLabel: env
      replacement: {{ . | quote }}
{{- end }}
{{- range $key, $value := $check.extraLabels }}
    - targetLabel: {{ $key }}
      replacement: {{ $value | quote }}
{{- end }}
---
{{- end }}
{{- end -}}
