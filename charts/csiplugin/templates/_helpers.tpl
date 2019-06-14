{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "csiplugin-provisioner.name" -}}
{{- default .Chart.Name .Values.csiplugin-provisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiplugin-provisioner.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiplugin-provisioner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiplugin-attacher.name" -}}
{{- default .Chart.Name .Values.csiplugin-attacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiplugin-attacher.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiplugin-attacher.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiplugin-nodeplugin.name" -}}
{{- default .Chart.Name .Values.csiplugin-nodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiplugin-nodeplugin.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiplugin-nodeplugin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "csiplugin-snapshotter.name" -}}
{{- default .Chart.Name .Values.csiplugin-snapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "csiplugin-snapshotter.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.csiplugin-snapshotter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
