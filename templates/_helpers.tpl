{{- define "arnica-k8s-collector.tokenSecretName" -}}
{{- printf "%s-token" .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "arnica-k8s-collector.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- /*
ClusterRole and ClusterRoleBinding are cluster-scoped, so installs in two
namespaces would collide on a shared name. Suffix the namespace, except in the
namespace that matches the name, which keeps the name existing installs have.
*/ -}}
{{- define "arnica-k8s-collector.clusterName" -}}
{{- if eq .Release.Namespace .Values.name }}{{ .Values.name }}{{ else }}{{ printf "%s-%s" .Values.name .Release.Namespace }}{{ end }}
{{- end }}
