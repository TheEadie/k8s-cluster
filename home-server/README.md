# Home Cluster (home.eadie.net)

## Install K3s

### Uninstall any previous installation

```
ssh eadie@192.168.50.10
/usr/local/bin/k3s-uninstall.sh
```

### Install

```
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup install --ip 192.168.50.10 --user eadie --k3s-channel latest --k3s-extra-args '--no-deploy traefik --no-deploy servicelb' --context hal --merge --local-path .kube/config
```

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

