{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "csiProvisioner.name" -}}
{{- default .Chart.Name .Values.csiProvisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiProvisioner.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiProvisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiAttacher.name" -}}
{{- default .Chart.Name .Values.csiAttacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiAttacher.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiAttacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiNodeplugin.name" -}}
{{- default .Chart.Name .Values.csiNodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiNodeplugin.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiNodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiSnapshotter.name" -}}
{{- default .Chart.Name .Values.csiSnapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiSnapshotter.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiSnapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
