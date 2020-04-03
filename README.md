# k8s-cluster
Config for the Raspberry PI cluster

## Prep the Pi

### Setup IMG

1. Download Raspbian from: https://www.raspberrypi.org/downloads/raspbian/
2. Download sd card writer: https://www.balena.io/etcher/
3. Unzip raspbian zip file
4. Use balena etcher to write the img to a sd card
5. Add an empty `ssh` file to the boot folder of the sd card
6. Add `wpa_supplicant.conf` to the boot folder of the sd card

```
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="NETWORK-NAME"
    psk="NETWORK-PASSWORD"
}
```

7. Take the card out and fire up the Pi

### Enable SSH

```
ssh-copy-id pi@192.168.1.101
ssh-copy-id pi@192.168.1.102
```

### Config the Pi - Once per node

Log in with the password `raspberry` and then type in `sudo raspi-config`.

Update the following:

- Set the GPU memory split to 16mb
- Set the hostname to nodex
- Change the password for the pi user

Enable containers:
Edit `/boot/cmdline.txt` and add the following to the end of the line:
```
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

Fix networking:
```
sudo apt remove iptables -y && sudo apt install nftables
```

Update:
```
sudo apt-get update && sudo apt-get upgrade -y
Sudo reboot
```

## Install K3s

### Uninstall any previous installation

```
ssh pi@192.168.1.101
/usr/local/bin/k3s-uninstall.sh

ssh pi@192.168.1.102
/usr/local/bin/k3s-agent-uninstall.sh
```

### Install

```
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup install --ip 192.168.1.101 --user pi --k3s-extra-args '--no-deploy traefik' --context pi
k3sup join --ip 192.168.1.102 --server-ip 192.168.1.101 --user pi

mv kubeconfig ~/.kube/config
```

## Install Nginx

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm install nginx stable/nginx-ingress --namespace kube-system --set rbac.create=true,controller.image.repository="quay.io/kubernetes-ingress-controller/nginx-ingress-controller-arm",defaultBackend.image.repository="k8s.gcr.io/defaultbackend-arm" 

```

## Install sample mysite

```
kubectl create configmap mysite-html --from-file mysite/index.html
kubectl apply -f mysite/mysite.yaml
```