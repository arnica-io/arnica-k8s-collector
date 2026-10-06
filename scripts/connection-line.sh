#!/usr/bin/env bash
# Prints the line to paste into Arnica: server URL + CA + token of the
# arnica-collector ServiceAccount, base64-encoded as one string.
# Usage: connection-line.sh [namespace] [token-secret-name]
# The server URL comes from your current kubectl context, so run this with the
# context Arnica should reach (not a localhost / port-forward context).
set -euo pipefail

ns="${1:-arnica-collector}"
secret="${2:-arnica-collector-token}"

i=0
until [ -n "$(kubectl -n "$ns" get secret "$secret" -o jsonpath='{.data.token}' 2>/dev/null)" ]; do
  if [ "$i" -ge 60 ]; then
    printf '%s\n' "The $secret Secret still has no token after a minute; run this again. 'kubectl -n $ns describe secret $secret' shows why." >&2
    exit 1
  fi
  i=$((i+1))
  sleep 1
done

server=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')
ca=$(kubectl -n "$ns" get secret "$secret" -o jsonpath='{.data.ca\.crt}')
token=$(kubectl -n "$ns" get secret "$secret" -o go-template='{{.data.token | base64decode}}')
line=$(printf '{"server":"%s","caData":"%s","token":"%s"}' "$server" "$ca" "$token" | base64 | tr -d '\n')

printf '\n%s\n%s\n' "Paste this line into Arnica:" "arnica-cluster-v1.$line"
