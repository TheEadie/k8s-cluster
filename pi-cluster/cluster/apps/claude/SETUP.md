# Claude Code Container Setup

## Prerequisites

- Claude Pro/Max account for channels authentication
- Discord bot created in the [Discord Developer Portal](https://discord.com/developers/applications)
  - "Message Content Intent" enabled under Privileged Gateway Intents
  - Bot invited to your server with permissions: View Channels, Send Messages, Send Messages in Threads, Read Message History, Attach Files, Add Reactions

## 1. Create NFS Directories

On your NFS server:

```bash
mkdir -p /export/Kubernetes/config/claude /export/Kubernetes/workspace/claude
chown root:root /export/Kubernetes/config/claude /export/Kubernetes/workspace/claude
chmod 755 /export/Kubernetes/config/claude /export/Kubernetes/workspace/claude
```

Ensure the exports allow root writes (`no_root_squash`). If you already have a parent `/export/Kubernetes` export with this option, subdirectories will inherit it.

## 2. Add Secrets

Add `CLAUDE_GITHUB_TOKEN` to your cluster-secrets (SOPS-encrypted). This is optional — only needed if you want git push/pull from the container. If not needed, remove the `GITHUB_TOKEN` env var from `deployment.yaml`.

## 3. Deploy

Commit and push to master. Flux will reconcile within 10 minutes, or force it:

```bash
./reconcile.sh
```

## 4. Authenticate Claude Code

The pod will start, install Claude Code and the Discord plugin, then fail to connect until authenticated. Exec in to log in:

```bash
kubectl exec -it -n claude deploy/claude -- claude auth login
```

Follow the browser-based OAuth flow to authenticate your Claude account.

## 5. Pair Discord

1. DM your Discord bot — it will reply with a pairing code
2. Pair it in the container:

```bash
kubectl exec -it -n claude deploy/claude -- claude /discord:access pair <code>
```

3. Lock down access to allowlisted users only:

```bash
kubectl exec -it -n claude deploy/claude -- claude /discord:access policy allowlist
```

## 6. Restart the Pod

After auth and pairing, restart the pod so it boots cleanly with credentials:

```bash
kubectl rollout restart -n claude deploy/claude
```

Credentials persist in the `/claude-data` PVC (`$HOME/.claude`), so subsequent restarts will auto-connect.

## Usage

DM the Discord bot or mention it in a channel to send work requests to Claude Code. It operates in the `/workspace` directory with full tool permissions.
