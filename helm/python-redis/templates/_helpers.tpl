{{/*
Return the chart name and version as a label-safe string.
*/}}
{{- define "python-redis.chart" -}}
{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the FastAPI resource name.
*/}}
{{- define "python-redis.appName" -}}
{{ printf "%s-python-api" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the Redis resource name.
*/}}
{{- define "python-redis.redisName" -}}
{{ printf "%s-redis" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the Redis ConfigMap name.
*/}}
{{- define "python-redis.configMapName" -}}
{{ printf "%s-redis-cm" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the Redis Secret name.
*/}}
{{- define "python-redis.secretName" -}}
{{ printf "%s-redis-secret" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the Redis PVC name.
*/}}
{{- define "python-redis.pvcName" -}}
{{ printf "%s-redis-pvc" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the Ingress name.
*/}}
{{- define "python-redis.ingressName" -}}
{{ printf "%s-fastapi-ingress" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels used on chart resources.
*/}}
{{- define "python-redis.commonLabels" -}}
helm.sh/chart: {{ include "python-redis.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for FastAPI.
*/}}
{{- define "python-redis.appSelectorLabels" -}}
app.kubernetes.io/name: python-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for Redis.
*/}}
{{- define "python-redis.redisSelectorLabels" -}}
app.kubernetes.io/name: redis
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}