# k8s-cluster
Config for the Raspberry PI cluster


## WIP - How to install nginx ingress instead of Traefik

1. Add --no-deploy traefik to k3s.service that systemd uses
2. Add k8s repo (on helm 3) helm repo add stable https://kubernetes-charts.storage.googleapis.com/
3. Run helm install nginx stable/nginx-ingress --namespace kube-system --set rbac.create=true,controller.image.repository="quay.io/kubernetes-ingress-controller/nginx-ingress-controller-arm",defaultBackend.image.repository="k8s.gcr.io/defaultbackend-arm"
