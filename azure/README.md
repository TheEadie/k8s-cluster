# Azure Cluster (david.eadie.dev)

## Create the cluster

```
az aks create -n myCluster \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --load-balancer-sku basic \
    --node-osdisk-size 32
```

TODO - Get the Kubeconfig

## Setup Helm
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

## Install Flux
```
helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f flux/namespace.yaml
helm install flux fluxcd/flux --namespace flux --values flux/flux-values.yaml
helm install helm-operator fluxcd/helm-operator --namespace flux --values flux/helm-operator-values.yaml
```

