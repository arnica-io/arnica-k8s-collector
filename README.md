# Arnica Kubernetes Collector

## What is this?

A small Helm chart that gives Arnica **read-only** access to your Kubernetes cluster, so Arnica can inventory what runs there: workloads, networking, RBAC, and GitOps objects (Argo CD, Flux).

The chart creates four objects:

| Object | Scope | Purpose |
| --- | --- | --- |
| ServiceAccount `arnica-reader` | release namespace | The identity Arnica uses |
| Secret `arnica-reader-token` | release namespace | Long-lived token for that ServiceAccount |
| ClusterRole `arnica-reader` | cluster | `get`, `list`, `watch` on the resources below |
| ClusterRoleBinding `arnica-reader` | cluster | Binds the role to the ServiceAccount |

After install you run one command that prints a single line. You paste that line into Arnica. Nothing is sent anywhere automatically.

## What Arnica can and cannot read

Verbs are only `get`, `list`, `watch`. **No write access of any kind. No access to Secrets.**

| API group | Resources |
| --- | --- |
| core | namespaces, nodes, pods, services, serviceaccounts, configmaps, persistentvolumeclaims, persistentvolumes |
| `apps` | deployments, statefulsets, daemonsets, replicasets |
| `batch` | jobs, cronjobs |
| `networking.k8s.io` | ingresses, networkpolicies |
| `gateway.networking.k8s.io` | httproutes |
| `rbac.authorization.k8s.io` | roles, clusterroles, rolebindings, clusterrolebindings |
| `autoscaling` | horizontalpodautoscalers |
| `argoproj.io` | applications |
| `kustomize.toolkit.fluxcd.io` | kustomizations |
| `helm.toolkit.fluxcd.io` | helmreleases |
| `source.toolkit.fluxcd.io` | gitrepositories |

Rules for API groups you don't have installed (for example Flux or Gateway API) do nothing.

## Prerequisites

* `kubectl` access with permission to create a namespace, ClusterRole and ClusterRoleBinding (cluster-admin or similar)
* **Helm 3.8 or newer** (needed for OCI registry support)
* Kubernetes 1.24+
* Your kubectl context must point at an API server address **that Arnica can reach**. The connection line uses that address. A `localhost` or port-forward address will not work.

No container images are pulled. The chart only creates RBAC objects and a Secret.

## Quick start

**1. Install the chart:**

```bash
helm install arnica-reader oci://ghcr.io/arnica-io/arnica-k8s-collector -n arnica-reader --create-namespace
```

**2. Print the connection line.** The install output (`NOTES`) contains a ready-to-paste block that does this. Or run:

```bash
curl -fsSL https://raw.githubusercontent.com/arnica-io/arnica-k8s-collector/main/scripts/connection-line.sh | bash -s -- arnica-reader arnica-reader-token
```

The script waits up to a minute for Kubernetes to fill in the token, then prints:

```
Paste this line into Arnica:
arnica-cluster-v1.eyJzZXJ2ZXIiOi...
```

**3. Paste the `arnica-cluster-v1.…` line into Arnica.**

The line is base64 of `{"server": ..., "caData": ..., "token": ...}`: your API server URL, its CA certificate, and the ServiceAccount token. Treat it like a password and share it only with Arnica.

To show the install instructions again later: `helm get notes arnica-reader -n arnica-reader`.

## Configuration

All settings are optional. Override them with `--set key=value` or `-f values.yaml`.

| Value | Default | Description |
| --- | --- | --- |
| `name` | `arnica-reader` | Name of the ServiceAccount, ClusterRole and ClusterRoleBinding. The token Secret is `<name>-token`. |
| `extraRules` | `[]` | Extra ClusterRole rules, appended to the default set. |

Example: also let Arnica read cert-manager certificates:

```yaml
# my-values.yaml
extraRules:
  - apiGroups: [cert-manager.io]
    resources: [certificates]
    verbs: [get, list, watch]
```

```bash
helm upgrade --install arnica-reader oci://ghcr.io/arnica-io/arnica-k8s-collector \
  -n arnica-reader --create-namespace -f my-values.yaml
```

## Rotate the token

Delete the Secret and let Helm recreate it. Kubernetes issues a new token and the old one stops working right away:

```bash
kubectl -n arnica-reader delete secret arnica-reader-token
helm upgrade arnica-reader oci://ghcr.io/arnica-io/arnica-k8s-collector -n arnica-reader --reuse-values
```

Then run step 2 again and paste the new line into Arnica.

## Revoke access / uninstall

```bash
helm uninstall arnica-reader -n arnica-reader
kubectl delete namespace arnica-reader
```

This removes the ServiceAccount, its token, the ClusterRole and the ClusterRoleBinding. Arnica's access ends right away.

## Releasing (maintainers)

Bump `version` in `Chart.yaml` in your PR. When it merges to `main`, the `release` workflow pushes the chart to `oci://ghcr.io/arnica-io/arnica-k8s-collector` and creates a `v<version>` tag and GitHub release. CI fails a PR that changes the chart without bumping the version.
