{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "osdsapiserver.name" -}}
{{- default .Chart.Name .Values.osdsapiserver.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdsapiserver.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdsapiserver.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "osdslet.name" -}}
{{- default .Chart.Name .Values.osdslet.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdslet.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdslet.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "osdsdock.name" -}}
{{- default .Chart.Name .Values.osdsdock.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdsdock.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdsdock.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "osdsdb.name" -}}
{{- default .Chart.Name .Values.osdsdb.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdsdb.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdsdb.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "osdsdashboard.name" -}}
{{- default .Chart.Name .Values.osdsdashboard.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdsdashboard.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdsdashboard.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "osdsauthchecker.name" -}}
{{- default .Chart.Name .Values.osdsauthchecker.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdsauthchecker.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.osdsauthchecker.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
