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

## Configure secrets

### Nest-Exporter
```
mkdir secrets
touch secrets/nest-exporter.env
```

Add the following to the file and update with correct values:

```
NestApi__ClientId=
NestApi__ClientSecret=
NestApi__ProjectId=
NestApi__RefreshToken=
```

```
kubectl create secret generic nest-exporter --from-env-file=./secrets/nest-exporter.env
```

### OpenWeather-Exporter
```
touch secrets/openweather-exporter.env
```

Add the following to the file and update with correct values:

```
OW_APIKEY=
```

```
kubectl create secret generic openweather-exporter --from-env-file=./secrets/openweather-exporter.env
```

## Install Flux
```
helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f flux/namespace.yaml
helm install flux fluxcd/flux --namespace flux --values flux/flux-values.yaml
helm install helm-operator fluxcd/helm-operator --namespace flux --values flux/helm-operator-values.yaml
```

Add the generated flux key as a deploy key in GitHub on the repo.

