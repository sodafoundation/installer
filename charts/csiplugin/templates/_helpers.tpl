{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "csipluginProvisioner.name" -}}
{{- default .Chart.Name .Values.csipluginProvisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csipluginProvisioner.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csipluginProvisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csipluginAttacher.name" -}}
{{- default .Chart.Name .Values.csipluginAttacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csipluginAttacher.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csipluginAttacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csipluginNodeplugin.name" -}}
{{- default .Chart.Name .Values.csipluginNodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csipluginNodeplugin.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csipluginNodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csipluginSnapshotter.name" -}}
{{- default .Chart.Name .Values.csipluginSnapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csipluginSnapshotter.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csipluginSnapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
