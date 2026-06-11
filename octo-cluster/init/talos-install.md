# Talos install — octo-cluster

Bring up a 3-node **stacked HA** Talos cluster (every node is both control plane
and worker) with **Longhorn** distributed storage on a **single shared disk** per
node.

Prerequisite: BIOS + USB boot done — see [node-prep.md](node-prep.md). After
booting from the Talos USB, each node sits in **maintenance mode** with a DHCP
address and no config applied yet.

## Conventions / fill these in

| Placeholder        | Meaning                                              | Example          |
| ------------------ | ---------------------------------------------------- | ---------------- |
| `<NODE1..3_IP>`    | maintenance-mode IP of each node                     | `192.168.x.11-13`|
| `<VIP>`            | floating control-plane API IP (unused, outside DHCP) | `192.168.x.10`   |
| `<INSTALL_DISK>`   | disk Talos installs to (shared with Longhorn)        | `/dev/sda`       |
| `<TALOS_VERSION>`  | Talos release — match `talosctl version`             | `v1.12.0`        |
| `<SCHEMATIC_ID>`   | factory schematic id (step 2)                        | `dc7b152...`     |

All commands run from `octo-cluster/init/`.

## 1. Install talosctl

```sh
brew install siderolabs/tap/talosctl
talosctl version --client          # note the version → <TALOS_VERSION>
```

## 2. Build the installer image (system extensions)

Longhorn needs the `iscsi-tools` and `util-linux-tools` extensions. We bake them
into the *installer image* via the Talos Image Factory — defined in
[schematic.yaml](schematic.yaml):

```sh
curl -sX POST --data-binary @schematic.yaml https://factory.talos.dev/schematics
# => {"id":"<SCHEMATIC_ID>"}
```

Put `<SCHEMATIC_ID>` and `<TALOS_VERSION>` into
[patches/install.yaml](patches/install.yaml), and `<INSTALL_DISK>` too (find it
with `talosctl -n <NODE1_IP> get disks --insecure`).

## 3. Generate machine configs

First fill in the remaining placeholder: edit [patches/vip.yaml](patches/vip.yaml)
and replace `<VIP>` with the spare control-plane IP you chose (unused, outside
the DHCP pool, not a node IP). Use that **same** IP as the endpoint below.

```sh
talosctl gen config octo-cluster https://<VIP>:6443 \
  --output-dir _out \
  --config-patch @patches/cluster.yaml \
  --config-patch @patches/install.yaml \
  --config-patch @patches/longhorn.yaml \
  --config-patch @patches/vip.yaml
```

Sanity-check no placeholders survived before applying:

```sh
grep -rn '<.*>' _out/controlplane.yaml || echo "OK: no placeholders left"
```

This writes `_out/controlplane.yaml`, `_out/worker.yaml`, and `_out/talosconfig`.
Because all 3 nodes are stacked control planes, only `controlplane.yaml` is used.
Re-running `gen config` needs `--force` to overwrite `_out` (regenerates secrets —
fine before bootstrap, but apply the new config to *all* nodes consistently).

> `_out/` holds secrets (PKI, talosconfig) — keep it out of git. See the
> `.gitignore` note in [README.md](README.md).

## 4. Apply config to each node

Nodes are in maintenance mode, so use `--insecure` (no PKI trust yet):

```sh
talosctl apply-config --insecure -n <NODE1_IP> -f _out/controlplane.yaml
talosctl apply-config --insecure -n <NODE2_IP> -f _out/controlplane.yaml
talosctl apply-config --insecure -n <NODE3_IP> -f _out/controlplane.yaml
```

Each node installs to `<INSTALL_DISK>` using the factory image (pulling the
extensions) and reboots into the configured system.

## 5. Bootstrap etcd (once, on ONE node only)

> **Endpoint must be a node IP here, not the VIP.** The VIP is a floating
> address Talos brings up via etcd leader election — no node holds it until
> etcd is bootstrapped and the control plane is healthy. Pointing the endpoint
> at the VIP now fails with `no route to host`, because bootstrap is what makes
> the VIP exist. Use a node's real IP until the cluster is up; switch to the VIP
> in step 6.

```sh
export TALOSCONFIG=$PWD/_out/talosconfig
talosctl config endpoint <NODE1_IP>   # node IP, NOT the VIP — see note above
talosctl config node <NODE1_IP>

talosctl bootstrap -n <NODE1_IP>      # run exactly once, on a single node
```

Wait for the API to come up, then fetch kubeconfig (still via the node IP — the
VIP isn't live until the control plane is healthy):

```sh
talosctl kubeconfig -n <NODE1_IP>
kubectl get nodes -o wide             # 3 Ready nodes
```

Once the control plane is healthy the VIP goes live. Switch the endpoint to it
for day-2 operations (skip this if you didn't configure a VIP):

```sh
talosctl config endpoint <VIP>        # VIP now routable
```

## 6. Verify extensions landed

```sh
talosctl -n <NODE1_IP> get extensions
# expect: siderolabs/iscsi-tools and siderolabs/util-linux-tools
talosctl -n <NODE1_IP> services       # ext-iscsid should be Running
```

If the extensions are missing, step 2/4 didn't use the factory image — check
`machine.install.image` in `patches/install.yaml` and re-apply.

## 7. Install Longhorn

Install Longhorn, then apply the privileged namespace labels. The order matters:
Longhorn's manifest includes its own bare `Namespace` with no labels — applying it
first and our `namespace.yaml` second means `kubectl apply`'s 3-way merge strips
the privileged labels (they were in the previous `last-applied-configuration` but
absent from Longhorn's manifest).

```sh
# Pin LONGHORN_VERSION to a release (e.g. v1.10.0). Check https://github.com/longhorn/longhorn/releases
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/<LONGHORN_VERSION>/deploy/longhorn.yaml

# Apply AFTER longhorn.yaml so the privileged labels aren't stripped by the 3-way merge
kubectl apply -f longhorn/namespace.yaml
```

Watch it come up:

```sh
kubectl -n longhorn-system get pods -w
kubectl get storageclass            # `longhorn` should be the default
```

## 8. Smoke test

```sh
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: longhorn-test }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: longhorn
  resources: { requests: { storage: 1Gi } }
EOF

kubectl get pvc longhorn-test        # should reach Bound
kubectl delete pvc longhorn-test
```

A `Bound` PVC confirms iSCSI, the extensions, and the kubelet bind-mount are all
working.

## Day-2 notes

- **Upgrades:** `talosctl upgrade -n <NODE_IP> --image factory.talos.dev/installer/<SCHEMATIC_ID>:<NEW_VERSION> --preserve`.
  `--preserve` keeps the EPHEMERAL partition (where `/var/lib/longhorn` lives).
  Drain Longhorn / one node at a time.
