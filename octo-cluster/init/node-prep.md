# Node Prep

## Connect the server to the network
- Connect the server to the network using an ethernet cable
- Assign a static IP address to the server in the DHCP server or router settings

## Bios changes
- Start the server and enter the bios by pressing F2

### Disable Sound
- Go to System Configuration -> Audio -> Disable Audio
- Go to System Configuration -> Audio -> Disable Microphone
- Go to System Configuration -> Audio -> Disable Internal Speaker

### Disable Secure Boot
- Go to Secure Boot -> Disable

### Disable SupportAssist Auto-Recovery
- Go to SupportAssist System Resolution -> SupportAssist OS Recovery -> Disable
- Go to SupportAssist System Resolution -> BIOS Connect -> Disable

### Set the storage controller to AHCI
- Go to System Configuration -> SATA Operation (or Storage) -> change **RAID On** to **AHCI**

- Apply and Exit

## Install Talos
- Insert the Talos USB drive into the server
- Hit F12 to enter the one time boot menu and select the USB drive to boot from
- The node boots into Talos **maintenance mode** with a DHCP address and no
  config applied yet.

Once all nodes are in maintenance mode, continue with
[talos-install.md](talos-install.md) to configure the cluster and Longhorn.