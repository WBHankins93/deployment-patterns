{{/*
Expand the name of the chart.
*/}}
{{- define "canary-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "canary-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "canary-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "canary-app.labels" -}}
helm.sh/chart: {{ include "canary-app.chart" . }}
{{ include "canary-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
deployment.strategy: canary
{{- end }}

{{/*
Selector labels
*/}}
{{- define "canary-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "canary-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Baseline labels
*/}}
{{- define "canary-app.baselineLabels" -}}
{{ include "canary-app.selectorLabels" . }}
deployment.variant: baseline
{{- end }}

{{/*
Canary labels
*/}}
{{- define "canary-app.canaryLabels" -}}
{{ include "canary-app.selectorLabels" . }}
deployment.variant: canary
{{- end }}

