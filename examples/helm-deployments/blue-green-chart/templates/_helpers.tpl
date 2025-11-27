{{/*
Expand the name of the chart.
*/}}
{{- define "blue-green-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "blue-green-app.fullname" -}}
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
{{- define "blue-green-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "blue-green-app.labels" -}}
helm.sh/chart: {{ include "blue-green-app.chart" . }}
{{ include "blue-green-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
deployment.strategy: blue-green
{{- end }}

{{/*
Selector labels
*/}}
{{- define "blue-green-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "blue-green-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Blue environment labels
*/}}
{{- define "blue-green-app.blueLabels" -}}
{{ include "blue-green-app.selectorLabels" . }}
deployment.environment: blue
{{- end }}

{{/*
Green environment labels
*/}}
{{- define "blue-green-app.greenLabels" -}}
{{ include "blue-green-app.selectorLabels" . }}
deployment.environment: green
{{- end }}

