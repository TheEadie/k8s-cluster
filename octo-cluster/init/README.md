# octo-cluster — init

Bootstrap docs and Talos config templates for the octo-cluster: a 3-node
**stacked HA** Talos Linux cluster (each node is control plane + worker) with
**Longhorn** storage on a single shared disk per node.

## Order of operations

1. [node-prep.md](node-prep.md) — BIOS settings and booting the Talos USB.
2. [talos-install.md](talos-install.md) — generate configs, apply, bootstrap,
   install Longhorn.

## Files

| Path                     | Purpose                                                        |
| ------------------------ | -------------------------------------------------------------- |
| `schematic.yaml`         | Image Factory input: the Longhorn system extensions            |
| `patches/install.yaml`   | Install disk + factory installer image (carries the extensions)|
| `patches/cluster.yaml`   | `allowSchedulingOnControlPlanes` (workloads run on CP nodes)   |
| `patches/longhorn.yaml`  | kubelet `extraMounts` bind for `/var/lib/longhorn` (`rshared`) |
| `patches/vip.yaml`       | Floating control-plane VIP for the API endpoint                |
| `longhorn/namespace.yaml`| `longhorn-system` namespace labelled Pod Security `privileged` |

## Do not commit secrets

`talosctl gen config` writes a `_out/` directory containing PKI material and
`talosconfig`. Add it to `.gitignore` before committing anything from here:

```
octo-cluster/init/_out/
octo-cluster/init/kubeconfig
```
