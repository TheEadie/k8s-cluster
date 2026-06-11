# k8s-cluster

## Flux variable substitution in manifests

All manifests under `octo-cluster/` are processed by the `apps` Flux Kustomization, which has `postBuild.substituteFrom` pointing at the `cluster-settings` ConfigMap and `cluster-secrets` Secret.

**Flux replaces every `${VAR}` pattern in the entire manifest** — not just known Flux variables. Any undefined variable is silently replaced with an empty string before the resource reaches Kubernetes.

This means bash scripts embedded in Pod/Deployment manifests (e.g. in `command`, `args`, or ConfigMap data) must not use `${VAR}` syntax for shell variables unless that variable is intentionally a Flux substitution target (like `${CLAUDE_GITHUB_TOKEN}`).

### Rules for bash scripts in manifests

- Use `$VAR` (no braces) for shell variables — Flux only substitutes `${VAR}`.
- When braces are needed for disambiguation (e.g. `${VAR}_suffix`), use adjacent-string concatenation instead: `"$VAR""_suffix"`.
- Alternatively, assign to an intermediate variable first: `FULL="$VAR""_suffix"`.

### Example

```bash
# BAD — Flux replaces ${GH_VERSION} with "" before the pod starts
curl ".../v${GH_VERSION}/gh_${GH_VERSION}_linux_arm64.tar.gz"

# GOOD — $GH_VERSION is left alone by Flux; concatenation handles the _ disambiguation
GH_ARCH=$(dpkg --print-architecture)
curl ".../v$GH_VERSION/gh_$GH_VERSION""_linux_$GH_ARCH.tar.gz"
```
