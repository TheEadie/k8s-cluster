# k8s-cluster

Config for the Raspberry PI cluster

## Prep the Pi

### Setup IMG

1. Download Raspberry Pi Imager from: https://www.raspberrypi.com/software/
2. Install Raspbian OS lite (64bit)
3. Take the card out and fire up the Pi

### Enable SSH

```
ssh-copy-id pi@192.168.50.11
ssh-copy-id pi@192.168.50.12
ssh-copy-id pi@192.168.50.13
ssh-copy-id pi@192.168.50.14
```

### Config the Pi - Once per node

Enable containers:
Edit `/boot/firmware/cmdline.txt` and add the following to the end of the line:

```
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

Disable Swap:

```
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove
sudo apt purge dphys-swapfile
```

Update:

```
sudo apt-get update && sudo apt-get upgrade -y
sudo reboot
```

## Install K3s

### Uninstall any previous installation

```
ssh pi@192.168.50.11
/usr/local/bin/k3s-uninstall.sh

ssh pi@192.168.50.12
/usr/local/bin/k3s-agent-uninstall.sh
```

### Install

```
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup install --ip 192.168.50.12 --user pi --k3s-channel latest --k3s-extra-args '--disable traefik --disable servicelb' --context pi-new --merge --local-path .kube/config --ssh-key ~/.ssh/id_ed25519
k3sup join --ip 192.168.50.11 --server-ip 192.168.50.12 --user pi --k3s-channel latest --ssh-key ~/.ssh/id_ed25519
k3sup join --ip 192.168.50.13 --server-ip 192.168.50.12 --user pi --k3s-channel latest --ssh-key ~/.ssh/id_ed25519
k3sup join --ip 192.168.50.14 --server-ip 192.168.50.12 --user pi --k3s-channel latest --ssh-key ~/.ssh/id_ed25519
```

## Install Flux v2

```
curl -s https://fluxcd.io/install.sh | sudo bash
```

Generate a PAT token for GitHub

```
export GITHUB_TOKEN=<token>
export GITHUB_USER=TheEadie
flux bootstrap github --owner=$GITHUB_USER --repository=k8s-cluster --branch=master --path=./pi-cluster/cluster/base --personal
```

## Setup SOPS (Encrypted secrets)

Install SOPS and GPG:
```
brew install gnupg sops
```

Copy the private key from the password manager to a file on the local machine.

```
gpg --import <path-to-private-key>
```

Find the fingerprint of the key:

```
gpg --list-secret-keys
export KEY_FP=<fingerprint>
```

Import the private key into the cluster:

```
gpg --export-secret-keys --armor "${KEY_FP}" |
kubectl create secret generic sops-gpg \
--namespace=flux-system \
--from-file=sops.asc=/dev/stdin
```

Revert the commit to remove the decryption from the manifests that was auto-generated by the `bootstrap` above.

Note: this all based on the guide here: https://fluxcd.io/docs/guides/mozilla-sops/


To encrypt new secrets run:

```
gpg --import ./pi-cluster/.sops.pub.asc
sops --encrypt --in-place <filename>.yaml
```
