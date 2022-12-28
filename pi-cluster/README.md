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
ssh-copy-id pi@192.168.50.11
ssh-copy-id pi@192.168.50.12
ssh-copy-id pi@192.168.50.13
ssh-copy-id pi@192.168.50.14
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

Add the following line to `/etc/rc.local` before the return

```
ip link set wlan0 promisc on
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
Sudo reboot
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

k3sup install --ip 192.168.50.12 --user pi --k3s-channel latest --k3s-extra-args '--disable traefik --disable servicelb' --context pi --merge --local-path .kube/config --ssh-key ~/.ssh/id_ed25519
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
flux bootstrap github --owner=$GITHUB_USER --repository=k8s-cluster --branch=master --path=./pi-cluster --personal
```

## Setup SOPS (Encrypted secrets)

Following the guide here: https://fluxcd.io/docs/guides/mozilla-sops/

To recover load the private key from 1Password back into the cluster.

To encrypt new secrets run:

```
gpg --import ./pi-cluster/.sops.pub.asc
sops --encrypt --in-place <filename>.yaml
```
