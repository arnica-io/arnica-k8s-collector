{{- define "arnica-k8s-reader.tokenSecretName" -}}
{{- printf "%s-token" .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "arnica-k8s-reader.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
