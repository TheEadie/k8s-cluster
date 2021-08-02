# Azure Cluster (david.eadie.dev)

## Create the cluster

```
az aks create -n azure-k8s -g K8sCluster -l uksouth --node-count 1 --node-vm-size Standard_B2s --load-balancer-sku basic --node-osdisk-size 32

az aks get-credentials --resource-group K8sCluster --name azure-k8s
```

## Install Flux v2
```
curl -s https://fluxcd.io/install.sh | sudo bash 
```

Generate a PAT token for GitHub

```
export GITHUB_TOKEN=<token>
export GITHUB_USER=TheEadie
flux bootstrap github --owner=$GITHUB_USER --repository=k8s-cluster --branch=master --path=./azure --personal
```

## Setup SOPS (Encrypted secrets)

Following the guide here: https://fluxcd.io/docs/guides/mozilla-sops/

To recover load the private key from 1Password back into the cluster.

To encrypt new secrets run:

```
gpg --import ./pi-cluster/.sops.pub.asc
sops --encrypt --in-place <filename>.yaml
```
