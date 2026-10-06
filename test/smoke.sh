#!/usr/bin/env bash
# Installs the chart into the current kubectl context, runs the connection-line
# script, then logs in with ONLY the decoded line and checks the access is
# read-only: can list pods cluster-wide, cannot read secrets or write.
set -euo pipefail

ns=arnica-reader
cd "$(dirname "$0")/.."

helm upgrade --install reader . -n "$ns" --create-namespace --wait
out=$(scripts/connection-line.sh "$ns" arnica-reader-token)
printf '%s\n' "$out" | grep -q '^arnica-cluster-v1\.'

json=$(printf '%s' "${out##*arnica-cluster-v1.}" | base64 -d)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf '%s' "$json" | jq -r .caData | base64 -d > "$tmp/ca.crt"

# Fresh kubeconfig so the admin client cert from the current context is not sent too.
kc="$tmp/kubeconfig"
kubectl --kubeconfig "$kc" config set-cluster c --server "$(printf '%s' "$json" | jq -r .server)" --certificate-authority "$tmp/ca.crt" >/dev/null
kubectl --kubeconfig "$kc" config set-credentials u --token "$(printf '%s' "$json" | jq -r .token)" >/dev/null
kubectl --kubeconfig "$kc" config set-context c --cluster c --user u >/dev/null
kubectl --kubeconfig "$kc" config use-context c >/dev/null

as_reader() { kubectl --kubeconfig "$kc" "$@"; }

as_reader get pods -A >/dev/null
as_reader get clusterroles >/dev/null
for check in "get secrets -A" "create configmaps -n $ns" "delete pods -A"; do
  # shellcheck disable=SC2086
  if as_reader auth can-i $check >/dev/null 2>&1; then
    echo "FAIL: reader is allowed to '$check'" >&2
    exit 1
  fi
done

echo "PASS: connection line works and access is read-only"
