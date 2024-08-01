{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "app.fullname" -}}
{{- $name := .Values.nameOverride | default .Chart.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified resource name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "resource.fullname" -}}
{{- $release_name := index . "release_name" -}}
{{- $base_name := index . "base_name" -}}
{{- printf "%s-%s" $release_name $base_name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "service.fullname" -}}
{{- $appFullName := include "app.fullname" . }}
{{- .Values.service.nameOverride | default $appFullName -}}
{{- end -}}

{{/*
Create a default fully qualified chart name.
*/}}
{{- define "chart.fullname" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{/*
Generate standard labels
*/}}
{{- define "standard_labels" }}
  labels:
    app: {{ template "app.name" . }}
    chart: {{ template "chart.fullname" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
{{- end }}

{{/*
Generate standard metadata
*/}}
{{- define "standard_metadata" }}
metadata:
  name: {{ template "app.fullname" . }}
  {{- template "standard_labels" . }}
  {{- template "standard_annotations" . }}
{{- end }}

{{/*
Generate standard deployment metadata
*/}}
{{- define "standard_deployment_metadata" }}
metadata:
  name: {{ template "app.fullname" . }}
  {{- template "standard_labels" . }}
  annotations:
    {{- with .Values.deployment.reloader }}
    {{- if .enabled }}
    reloader.stakater.com/auto: 'true'
    {{- end }}
    {{- end -}}
    {{- with .Values.deployment.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end }}

{{/*
Generate standard service metadata
*/}}
{{- define "standard_service_metadata" }}
metadata:
  name: {{ template "service.fullname" . }}
  {{- template "standard_labels" . }}
  {{- template "standard_service_annotations" . }}
{{- end }}

{{/*
Generate standard service selector
*/}}
{{- define "standard_service_selector" }}
  selector:
    app: {{ template "app.name" . }}
    release: {{ .Release.Name }}
{{- end }}

{{/*
Generate standard service spec
*/}}
{{- define "standard_service_spec" }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  ports:
    - port: {{ .Values.service.externalPort | default 8080 }}
      targetPort: {{ .Values.service.internalPort | default 8080 }}
      protocol: TCP
      name: {{ .Values.service.externalPort | default 8080 }}-tcp
    # for the jboss admin console
    - port: 9990
      targetPort: 9990
      protocol: TCP
      name: 9990-tcp
{{- template "standard_service_selector" . }}
{{- end }}

{{/*
Generate standard annotation block
*/}}
{{- define "standard_annotations" }}
  annotations:
    {{- if .Values.annotations }}
    {{- range $key, $value := .Values.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- end }}
{{- end }}

{{/*
Generate standard annotation block for a deployment
*/}}
{{- define "standard_service_annotations" }}
  annotations:
    {{- if .Values.service.annotations }}
    {{- range $key, $value := .Values.service.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- end }}
{{- end }}

{{/*
Generate standard metadata for deployment template
*/}}
{{- define "standard_deployment_template_metadata" }}
    metadata:
      labels:
        app: {{ template "app.name" . }}
        release: {{ .Release.Name }}
      annotations:
        {{- with .Values.deployment.prometheus }}
        {{- if .enabled }}
        prometheus.io/path: {{ .path }}
        prometheus.io/port: {{ .port | quote }}
        prometheus.io/scrape: 'true'
        {{- end }}
        {{- end }}
        {{- if eq .Values.deployment.image.pullPolicy "Always" }}
        rollingDeployTrigger: {{ randAlphaNum 5 | quote }}
        {{- end }}
      {{- with .Values.deployment.podAnnotations }}
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}

{{/*
Generate standard metadata for deployment spec selector
This should match the deployment template labels
*/}}
{{- define "standard_deployment_spec_selector" }}
  selector:
    matchLabels:
      app: {{ template "app.name" . }}
      release: {{ .Release.Name }}
{{- end }}

{{/*
Generate standard items for deployment pod template spec
*/}}
{{- define "standard_deployment_spec_template_spec_items" }}
      {{- with .Values.deployment.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}

{{/*
Generate standard deployment resources
*/}}
{{- define "standard_deployment_resources" }}
   {{- with .Values.deployment.resources -}}
          resources:
          {{- if or (.limits.cpu) (.limits.memory) }}
            limits:
          {{- if .limits.cpu }}
              cpu: {{ .limits.cpu }}
          {{- end -}}
          {{- if .limits.memory }}
              memory: {{ .limits.memory }}
          {{- end -}}
          {{- end }}
          {{- if or (.requests.cpu) (.requests.memory) }}
            requests:
          {{- if .requests.cpu }}
              cpu: {{ .requests.cpu }}
          {{- end -}}
          {{- if .requests.memory }}
              memory: {{ .requests.memory }}
          {{- end -}}
          {{- end }}
    {{- end }}
{{- end }}

{{/*
Generate standard route metadata
*/}}
{{- define "standard_route_metadata" }}
metadata:
  name: {{ template "app.fullname" . }}
  {{- template "standard_labels" . }}
  {{- template "standard_route_annotations" . }}
{{- end }}

{{/*
Generate standard annotation block for a route
*/}}
{{- define "standard_route_annotations" }}
  annotations:
    {{- with $.Values.route.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end }}

{{/*
Generate standard route spec
*/}}
{{- define "standard_route_spec" }}
spec:
  {{ if .Values.route.host }}
  host: {{ .Values.route.host }}
  {{ else }}
  host: "{{ template "app.name" . }}-{{ .Release.Namespace }}.{{ .Values.route.suffix }}"
  {{ end }}
  to:
    kind: Service
    name: {{ template "app.fullname" . }}
  port:
    targetPort: {{ .Values.service.externalPort }}
  {{- if .Values.route.tls }}
  tls:
{{ toYaml .Values.route.tls | indent 4 }}
  {{- end -}}
{{- end }}
