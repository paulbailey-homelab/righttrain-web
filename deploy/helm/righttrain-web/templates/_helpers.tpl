{{- define "righttrain-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "righttrain-web.fullname" -}}
{{- printf "%s" (include "righttrain-web.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "righttrain-web.labels" -}}
app.kubernetes.io/name: {{ include "righttrain-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "righttrain-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "righttrain-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
