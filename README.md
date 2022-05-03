<h1>NAS - Hard-metal Builds</h1>

If you have hard-metal NAS of compatible Linux OS then our Easy Scripts will help you prepare your NAS for Proxmox hosts and our suite of PVE applications.

Easy Scripts are available for:

* Synology DiskStations
* Open Media Vault
* Debian Linux

<h2>Features</h2>

Our Easy Script installer will create, modify and change system settings including:

Our Easy Script installer will fully configure and ready your NAS to support Ahuacate CTs or VMs. Each NAS installer will create, modify and change system settings including:

* Power User & Group Accounts
    * Groups: medialab:65605, homelab:65606, privatelab:65607, chrootjail:65608
    * Users: media:1605, home:1606, private:1607
    * Users media, home and private are for running CT applications
* Chrootjail Group for general User accounts.
* Ready for all Medialab applications such as Sonarr, Radarr, JellyFin, NZBGet and more.
* Full set of base and sub-folders ready for all CT applications
* Folder and user permissions are set including ACLs
* NFS 4.1 exports ready for PVE hosts backend storage mounts
* SMB 3.0 shares with access permissions set ( by User Group accounts )
* Set Local Domain option to set ( i.e .local, .localdomain, .home.arpa, .lan )

<h2>Prerequisites</h2>

**Network Prerequisites**

- [x] Layer 2/3 Network Switches
- [x] Network Gateway (*recommend xxx.xxx.xxx.5*)
- [x] Network DHCP server (*recommend xxx.xxx.xxx.5*)
- [x] Network DNS server (*recommend xxx.xxx.xxx.5*)
- [x] Network Name Server
- [x] Network DNS Search Domain resolves all LAN device hostnames (*static and dhcp IP's*)
- [x] Local Domain name is set on all network devices (*see note below*)
- [x] PVE host hostnames are suffixed with a numeric (*i.e pve-01 or pve01 or pve1*)
- [x] NAS and PVE host have internet access

>Note: The network Local Domain or Search domain must be set. We recommend only top-level domain (spTLD) names for residential and small networks names because they cannot be resolved across the internet. Routers and DNS servers know, in theory, not to forward ARPA requests they do not understand onto the public internet. It is best to choose one of our listed names: local, home.arpa, localdomain or lan only. Do NOT use made-up names.

<h2><b>Easy Scripts</b></h2>

Easy Scripts automate the installation and/or configuration processes. Easy Scripts are hardware type-dependent so choose carefully. Easy Scripts are based on bash scripting. `Cut & Paste` our Easy Script command into a terminal window, press `Enter`, and follow the prompts and terminal instructions. 

Our Easy Scripts have preset configurations. The installer may accept or decline the ES values. If you decline the User will be prompted to input all required configuration settings. PLEASE read our guide if you are unsure.


<h4><b>1) Synology NAS Builder Easy Script</b></h4>
You must first SSH login to your Synology NAS using your Administrator credentials: `ssh admin@IP_address`. If you have changed your Synology default SSH port use `ssh admin@IP_address:port`. After SSH login the User must type the following commands to switch to User root:
```bash
sudo -i # You will prompted for a root password which is the same as User password for 'admin'
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/nas-hardmetal/master/synology_nas_installer.sh)"
```
And simply follow the scripts prompts.

### 3.2.1. Linux NAS Installer/Builder ( hard metal )
You must first SSH login to your NAS `ssh root@IP_address` or if you have changed your default SSH port use `ssh root@IP_address:port`. Then you must run the following commands:
```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-nas/master/linux_nas_installer.sh)"
```

> Use this script to start the PVE NAS Installer. The User will be prompted to select a installation type. Run in a PVE host SSH terminal.

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-nas/master/pve_nas_installer.sh)"
```
> PVE Hosted 'Ubuntu NAS' Administration Toolbox. For creating and deleting user accounts, installing optional add-ons and upgrading your NAS OS. Run in a PVE host SSH terminal.

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-nas/master/pve_nas_toolbox.sh)"
```

<hr>












<h2> OEM NAS Brands - Linux based NAS Servers</h2>

This guide is for setting up any OEM Linux-based NAS ( Synology, Qnap, or whatever Linux flavor, etc ) to support our PVE host nodes, PVE CT/VM applications, and all our installation Easy Scripts.

This is not for users who have installed our PVE based NAS solution. If you require a NAS server try our [PVE NAS](https://github.com/ahuacate/pve-nas) which is fully turnkey and operationally ready. 

> For owners of third-party NAS servers its important you strictly follow this guide. Our PVE CT and VMs all have specific UIDs and GUIDs, Linux file permissions including ACLs and NAS needs.

A section of this guide is dedicated to Synology DiskStations. Synology DiskStation web management interface is restricted and does not permit the assignment of UIDs and GUIDs.

Network Prerequisites are:
- [x] Layer 2/3 Network Switches
- [x] Network Gateway is `XXX.XXX.XXX.5` ( *default is 192.168.1.5* )
- [x] Network DNS server is `XXX.XXX.XXX.5` ( *default is 192.168.1.5* )
- [x] Network DHCP server is `XXX.XXX.XXX.5` ( *default is 192.168.1.5* )

NAS Prerequisites are:
- [x] x86 CPU (Intel or AMD) (only required if running PVE VMs, otherwise ARM works too)
- [x] NAS Static IP Address is `XXX.XXX.XXX.10` ( *default NAS-01 is 192.168.1.10* )
- [x] NAS Hostname is `nas-01`
- [x] NAS Gateway is `XXX.XXX.XXX.5` ( *default is 192.168.1.5* )
- [x] NAS DNS server is `XXX.XXX.XXX.5` ( *default is 192.168.1.5* )

Synology DiskStation Prerequisites are:
- [ ] x86 CPU Intel CPU (only required if running VMs)
- [x] Volume is formatted to BTRFS (not ext4, which doesn't support Synology Virtual Machines)

>  **Note: A prerequisite to running VMs on a Synology DiskStation NAS is your volumes must use the BTRFS file system - without BTRFS you CANNOT install VM's. In my experience, the best way forward is based upon backing up your existing data to an external disk (USB) or another internal volume (be careful and know what you are doing), deleting and recreating /volume1 via DSM, and restoring your backup data. I recommend using Synology Hyper Backup for backing up your data and settings.**
>  **It's a lengthy topic and the procedures can be found by searching on the internet. The following tutorials assume your Volume 1 is in the BTRFS file system format.**

<hr>
<h4>Table of Contents</h4>
<!-- TOC -->

        - [3.2.1. Linux NAS Installer/Builder ( hard metal )](#321-linux-nas-installerbuilder--hard-metal-)
- [1. Introduction](#1-introduction)
- [2. Prerequisites](#2-prerequisites)
    - [2.1. NFS Support](#21-nfs-support)
    - [2.2. SMB/CIFS Support](#22-smbcifs-support)
    - [2.3. ACL Support](#23-acl-support)
- [3. Create PVE Users and Groups](#3-create-pve-users-and-groups)
    - [3.1. Create PVE Groups](#31-create-pve-groups)
    - [3.2. Change the NAS Home folder permissions (optional)](#32-change-the-nas-home-folder-permissions-optional)
    - [3.3. Modify PVE Users Home Folder](#33-modify-pve-users-home-folder)
    - [3.4. Create PVE Users](#34-create-pve-users)
- [4. NAS Folder Shares](#4-nas-folder-shares)
    - [4.1. Folder Permissions](#41-folder-permissions)
    - [4.2. Sub Folder Permissions](#42-sub-folder-permissions)
    - [4.3. Create PVE SMB (SAMBA) Shares](#43-create-pve-smb-samba-shares)
    - [4.4. Create PVE NFS Shares](#44-create-pve-nfs-shares)
- [5. Preparing a Synology NAS](#5-preparing-a-synology-nas)
    - [5.1. Enable Synology Services](#51-enable-synology-services)
        - [5.1.1. SMB Service](#511-smb-service)
        - [5.1.2. NFS Service](#512-nfs-service)
    - [5.2. Create the required Synology Shared Folders](#52-create-the-required-synology-shared-folders)
        - [5.2.1. Create Shared Folders](#521-create-shared-folders)
            - [5.2.1.1. Set up basic information:](#5211-set-up-basic-information)
            - [5.2.1.2. Set up Encryption](#5212-set-up-encryption)
            - [5.2.1.3. Configure advanced settings](#5213-configure-advanced-settings)
    - [5.3. Create Synology User Groups](#53-create-synology-user-groups)
        - [5.3.1. Create "medialab" User Group](#531-create-medialab-user-group)
            - [5.3.1.1. Group information](#5311-group-information)
            - [5.3.1.2. Assign shared folders permissions](#5312-assign-shared-folders-permissions)
            - [5.3.1.3. User quota setting](#5313-user-quota-setting)
            - [5.3.1.4. Assign application permissions](#5314-assign-application-permissions)
        - [5.3.2. Create "homelab" User Group](#532-create-homelab-user-group)
            - [5.3.2.1. Group information](#5321-group-information)
            - [5.3.2.2. Assign shared folders permissions](#5322-assign-shared-folders-permissions)
            - [5.3.2.3. User quota setting](#5323-user-quota-setting)
        - [5.3.3. Create "privatelab" User Group](#533-create-privatelab-user-group)
            - [5.3.3.1. Group information](#5331-group-information)
            - [5.3.3.2. Assign shared folders permissions](#5332-assign-shared-folders-permissions)
            - [5.3.3.3. User quota setting](#5333-user-quota-setting)
        - [5.3.4. Create "chrootjail" User Group](#534-create-chrootjail-user-group)
            - [5.3.4.1. Group information](#5341-group-information)
            - [5.3.4.2. Assign shared folders permissions](#5342-assign-shared-folders-permissions)
            - [5.3.4.3. User quota setting](#5343-user-quota-setting)
    - [5.4. Create new Synology Users](#54-create-new-synology-users)
        - [5.4.1. Create user "media"](#541-create-user-media)
            - [5.4.1.1. User information](#5411-user-information)
            - [5.4.1.2. Join groups](#5412-join-groups)
            - [5.4.1.3. Assign shared folders permissions](#5413-assign-shared-folders-permissions)
            - [5.4.1.4. User quota setting](#5414-user-quota-setting)
            - [5.4.1.5. Assign application permissions](#5415-assign-application-permissions)
            - [5.4.1.6. User Speed Limit Setting](#5416-user-speed-limit-setting)
        - [5.4.2. Create user "home"](#542-create-user-home)
            - [5.4.2.1. User information](#5421-user-information)
            - [5.4.2.2. Join groups](#5422-join-groups)
            - [5.4.2.3. Assign shared folders permissions](#5423-assign-shared-folders-permissions)
            - [5.4.2.4. User quota setting](#5424-user-quota-setting)
            - [5.4.2.5. Assign application permissions](#5425-assign-application-permissions)
            - [5.4.2.6. User Speed Limit Setting](#5426-user-speed-limit-setting)
        - [5.4.3. Create user "private"](#543-create-user-private)
            - [5.4.3.1. User information](#5431-user-information)
            - [5.4.3.2. Join groups](#5432-join-groups)
            - [5.4.3.3. Assign shared folders permissions](#5433-assign-shared-folders-permissions)
            - [5.4.3.4. User quota setting](#5434-user-quota-setting)
            - [5.4.3.5. Assign application permissions](#5435-assign-application-permissions)
            - [5.4.3.6. User Speed Limit Setting](#5436-user-speed-limit-setting)
    - [5.5. Create NFS Permissions](#55-create-nfs-permissions)
    - [5.6. Edit Synology NAS GUID and UID](#56-edit-synology-nas-guid-and-uid)
        - [5.6.1. Prepare your Synology](#561-prepare-your-synology)
        - [5.6.2. Edit Synology NAS GUID (Groups)](#562-edit-synology-nas-guid-groups)
        - [5.6.3. Edit Synology NAS UID (Users)](#563-edit-synology-nas-uid-users)
    - [5.7. Set PVE Folder ACL Permissions](#57-set-pve-folder-acl-permissions)
        - [5.7.1. Set Folder ACL using Synology DSM WebGUI](#571-set-folder-acl-using-synology-dsm-webgui)
- [6. Synology Virtual Machine Manager](#6-synology-virtual-machine-manager)
    - [6.1. Download the Proxmox installer ISO](#61-download-the-proxmox-installer-iso)
    - [6.2. Install Synology Virtual Machine Manager on your NAS](#62-install-synology-virtual-machine-manager-on-your-nas)
    - [6.3. Configure Synology Virtual Machine Manager](#63-configure-synology-virtual-machine-manager)
    - [6.4. Create a Proxmox VM](#64-create-a-proxmox-vm)
        - [6.4.1. Add the Proxmox VE ISO image to your Synology](#641-add-the-proxmox-ve-iso-image-to-your-synology)
        - [6.4.2. Create the Proxmox VM machine](#642-create-the-proxmox-vm-machine)
        - [6.4.3. Install Proxmox OS](#643-install-proxmox-os)
            - [6.4.3.1. Power-on PVE-0X VM](#6431-power-on-pve-0x-vm)
            - [6.4.3.2. Run the Proxmox ISO Installation](#6432-run-the-proxmox-iso-installation)
    - [6.5. Configure the Proxmox VM](#65-configure-the-proxmox-vm)
        - [6.5.1. Update Proxmox OS VM and enable turnkey Linux templates](#651-update-proxmox-os-vm-and-enable-turnkey-linux-templates)
- [7. Patches and Fixes](#7-patches-and-fixes)
    - [7.1. Install Nano](#71-install-nano)
- [2. OMV](#2-omv)
- [3. Hard Metal NAS](#3-hard-metal-nas)
    - [3.1. Hard Metal NAS Prerequisites](#31-hard-metal-nas-prerequisites)
    - [3.2. Easy Script setup](#32-easy-script-setup)
        - [3.2.1. Linux NAS Installer/Builder ( hard metal )](#321-linux-nas-installerbuilder--hard-metal--1)
        - [3.2.2. Synology NAS Installer/Builder ( hard metal )](#322-synology-nas-installerbuilder--hard-metal-)
- [4. Other Linux NAS Types & Basic NAS Building](#4-other-linux-nas-types--basic-nas-building)
    - [4.1. Prerequisites](#41-prerequisites)
    - [4.2. Create Users and Groups](#42-create-users-and-groups)
    - [4.3. Create PVE Groups](#43-create-pve-groups)
    - [4.4. Change the NAS Home folder permissions (optional)](#44-change-the-nas-home-folder-permissions-optional)
    - [4.5. Modify PVE Users Home Folder](#45-modify-pve-users-home-folder)
    - [4.6. Create PVE Users](#46-create-pve-users)
    - [4.7. NAS Folder Shares](#47-nas-folder-shares)
    - [4.8. Folder Permissions](#48-folder-permissions)
    - [4.9. Sub Folder Permissions](#49-sub-folder-permissions)
    - [4.10. Create PVE SMB (SAMBA) Shares](#410-create-pve-smb-samba-shares)
    - [4.11. Create PVE NFS Shares](#411-create-pve-nfs-shares)

<!-- /TOC -->

<hr>

# 1. Introduction

All our PVE CT & VM applications require backend storage pools. A backend storage pool is an NFS or CIFS mount point to your NAS appliance folder shares (nas-01). Backend storage pools are only set up on your primary PVE node ( pve-01 ).

This is a shared storage pool system because all backend storage pools get automatically mounted and distributed to all PVE cluster nodes. Because all PVE nodes share the same storage configuration the backend storage mount points are available on all PVE nodes. Every backend storage pool can be physically different, either an NFS or CIFS mount, or a combination of both NFS and CIFS, and are individually labeled accessing different content.

Once your PVE backend storage is set up a PVE CT application local disk storage is actually disk storage space on your network NAS appliance.

There are four task levels in setting up your NAS.
1. Install NFS and CIFS/SMB on your NAS.
2. Create our default set of Users and Groups each with our UIDs and GUIDs.
2. Create our default set of shared folders.
3. Set folder permissions including ACLs.


# 2. Prerequisites
It's assumed the installer has some Linux skills. There are lots of online guides about how to configure OEM NAS brands and Linux networking.

Most OEM NAS have a Web Management interface for all configuration tasks.

## 2.1. NFS Support
Your NAS NFS server must support NFSv3/v4.

## 2.2. SMB/CIFS Support
Your NAS SMB/CIFS server must support SMB3 protocol (PVE default). SMB1 is NOT supported.

## 2.3. ACL Support
Access control list (ACL) provides an additional, more flexible permission mechanism for your PVE storage pools. Enable ACL.

# 3. Create PVE Users and Groups
All our PVE CT applications require a specific set of UID and GUID to work properly. So make sure your UIDs and GUIDs exactly match our guide.

| Defaults                | Description             | Notes                                                                                                                |
|-------------------------|-------------------------|----------------------------------------------------------------------------------------------------------------------|
| **Default User Groups** |                         |                                                                                                                      |
|                         | medialab - GUID 65605   | For media Apps (Sonarr, Radar, Jellyfin etc)                                                                         |
|                         | homelab - GUID 65606    | For everything to do with your Smart Home (CCTV, Home Assistant)                                                     |
|                         | privatelab - GUID 65607 | Power, trusted, admin Users                                                                                          |
|                         | chrootjail - GUID 65608 | Users are restricted or jailed within their own home folder. But they they have read only access to medialab folders |
| **Default Users**       |                         |                                                                                                                      |
|                         | media - UID 1605        | Member of group medialab                                                                                             |
|                         | home - UID 1606         | Member of group homelab. Supplementary member of group medialab                                                      |
|                         | private - UID 1607      | Member of group privatelab. Supplementary member of group medialab, homelab                                         |


## 3.1. Create PVE Groups
Create the following Groups.

| Group Name | GUID  |
|------------|-------|
| medialab   | 65605 |
| homelab    | 65606 |
| privatelab | 65607 |

## 3.2. Change the NAS Home folder permissions (optional)
Proceed with caution. If you are NOT sure skip this step. This is for Linux File Servers not OEM NAS boxes.

Linux `/etc/adduser.conf` has a `DIR_MODE` setting which sets a Users HOME directory when its first created. The default mode likely 0755.

For added security we change this to 0750 where:
> 0755 = User:`rwx` Group:`r-x` World:`r-x`
0750 = User:`rwx` Group:`r-x` World:`---` (i.e. World: no access)

Depending on your NAS you may be able to change this setting 
```
sed -i "s/DIR_MODE=.*/DIR_MODE=0750/g" /etc/adduser.conf
```

Running the above command will change all-new User HOME folder permissions to `0750` globally on your NAS.

## 3.3. Modify PVE Users Home Folder
Set `/base_folder/homes` permissions for Users media. home and private.

| Owner | Permissions |
|-------|-------------|
| root  | 0750        |


Here is the Linux CLI for the task:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2/homes)"

sudo mkdir -p ${BASE_FOLDER}/homes
sudo chgrp -R root ${BASE_FOLDER}/homes
sudo chmod -R 0750 ${BASE_FOLDER}/homes
```

## 3.4. Create PVE Users
Create our list of PVE users. These are required by various PVE CT applications. Without them, nothing will work.

| Username  | UID | Home Folder | Group Member
|---|---|---|---|---|
|  media |  1605 | /BASE_FOLDER/homes/media | medialab
|  home |  1606 | /BASE_FOLDER/homes/home | homelab
|  private |  1607 | /BASE_FOLDER/homes/private | privatelab

Here is the Linux CLI for the task:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

# Create User media
useradd -m -d ${BASE_FOLDER}/homes/media -u 1605 -g medialab -s /bin/bash media
# Create User home
useradd -m -d ${BASE_FOLDER}/homes/home -u 1606 -g homelab -G medialab -s /bin/bash home
# Create User private
useradd -m -d ${BASE_FOLDER}/homes/private -u 1607 -g privatelab -G medialab,homelab -s /bin/bash private
```
# 4. NAS Folder Shares
You need to create a set of folder shares in a 'storage volume' on your NAS. The new folder shares are mounted by your PVE hosts as NFS or SMB/CIFS mount points for creating your PVE host backend storage ( pve-01 ).

We refer to the NAS 'storage volume' as your NAS 'base folder'.

> For example, on a Synology the default volume is `/volume1`. So on a Synology our "base folder" would be: `/volume1`.

Your NAS may already have some of the required folder structure. If so, then create the sub-directory where applicable.

Create the following folders on your NAS.
```
# 65605=medialab
# 65606=homelab
# 65607=privatelab
# 65608=chrootjail
# FOLDERNAME GROUP PERMISSIONS ACL

Your NAS (nas-01)
│
└──  base volume/
    ├── audio - root 0750 65605:rwx 65607:rwx 65608:rx
    ├── backup - root 1750 65605:rwx 65606:rwx 65607:rwx
    ├── books - root 0755 65605:rwx 65607:rwx 65608:rx
    ├── cloudstorage - root 1750 65606:rwx 65607:rwx
    ├── docker - root 0750 65605:rwx 65606:rwx 65607:rwx
    ├── downloads - root 0755 65605:rwx 65607:rwx
    ├── git - root 0750 65607:rwx
    ├── homes - root 0777
    ├── music - root 0755 65605:rwx 65607:rwx 65608:rx
    ├── openvpn - root 0750 65607:rwx
    ├── photo - root 0750 65605:rwx 65607:rwx 65608:rx
    ├── proxmox - root 0750 65607:rwx 65606:rwx
    ├── public - root 1777 65605:rwx 65606:rwx 65607:rwx 65608:rwx
    ├── sshkey - root 1750 65607:rwx
    └── video - root 0750 65605:rwx 65607:rwx 65608:rx
```

## 4.1. Folder Permissions

Create sub-folders with permissions as shown [here.](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefolderlist)

A CLI example for the task audio:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

sudo chgrp -R root ${BASE_FOLDER}/audio
sudo chmod -R 750 ${BASE_FOLDER}/audio
sudo setfacl -Rm g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx  ${BASE_FOLDER}/audio
```

## 4.2. Sub Folder Permissions

Create sub-folders with permissions as shown [here.](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefoldersubfolderlist)

## 4.3. Create PVE SMB (SAMBA) Shares
Your `/etc/samba/smb.conf` file should include the following PVE shares. This is an example from a Ubuntu NAS.

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also, you must restart your NFS service to invoke the changes.

The sample file is from a Ubuntu 21.04 server.

```
[global]
workgroup = WORKGROUP
server string = nas-04
server role = standalone server
disable netbios = yes
dns proxy = no
interfaces = 127.0.0.0/8 eth0
bind interfaces only = yes
log file = /var/log/samba/log.%m
max log size = 1000
syslog = 0
panic action = /usr/share/samba/panic-action %d
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes
map to guest = bad user
usershare allow guests = yes
inherit permissions = yes
inherit acls = yes
vfs objects = acl_xattr
follow symlinks = yes
hosts allow = 127.0.0.1 192.168.1.0/24 192.168.20.0/24 192.168.30.0/24 192.168.40.0/24 192.168.50.0/24 192.168.60.0/24 192.168.80.0/24
hosts deny = 0.0.0.0/0

[homes]
comment = home directories
browseable = yes
read only = no
create mask = 0775
directory mask = 0775
hide dot files = yes
valid users = %S

[public]
comment = public anonymous access
path = /srv/nas-04/public
writable = yes
browsable =yes
public = yes
read only = no
create mode = 0777
directory mode = 0777
force user = nobody
guest ok = yes
hide dot files = yes

[audio]
  comment = audio folder access
  path = /srv/nas-04/audio
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607


[backup]
  comment = backup folder access
  path = /srv/nas-04/backup
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65606, @65607


[books]
  comment = books folder access
  path = /srv/nas-04/books
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607


[cloudstorage]
  comment = cloudstorage folder access
  path = /srv/nas-04/cloudstorage
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65606, @65607


[docker]
  comment = docker folder access
  path = /srv/nas-04/docker
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65606, @65607


[downloads]
  comment = downloads folder access
  path = /srv/nas-04/downloads
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607


[git]
  comment = git folder access
  path = /srv/nas-04/git
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65607


[music]
  comment = music folder access
  path = /srv/nas-04/music
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607


[openvpn]
  comment = openvpn folder access
  path = /srv/nas-04/openvpn
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65607


[photo]
  comment = photo folder access
  path = /srv/nas-04/photo
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607


[proxmox]
  comment = proxmox folder access
  path = /srv/nas-04/proxmox
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65607, @65606


[sshkey]
  comment = sshkey folder access
  path = /srv/nas-04/sshkey
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65607


[video]
  comment = video folder access
  path = /srv/nas-04/video
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @65605, @65607

```

## 4.4. Create PVE NFS Shares
Modify your NFS exports file `/etc/exports` to include the following.

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also, note each NFS export defines a PVE host IPv4 address for primary and secondary (cluster nodes) machines. Modify if your PVE host is different.

The sample file is from a Ubuntu 21.04 server.

```
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#

# backup export
/srv/nas-04/backup 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# cloudstorage export
/srv/nas-04/cloudstorage 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# docker export
/srv/nas-04/docker 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# downloads export
/srv/nas-04/downloads 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# proxmox export
/srv/nas-04/proxmox 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# public export
/srv/nas-04/public 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# audio export
/srv/nas-04/audio 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# books export
/srv/nas-04/books 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# music export
/srv/nas-04/music 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# photo export
/srv/nas-04/photo 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# video export
/srv/nas-04/video 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)
```


# 5. Preparing a Synology NAS

## 5.1. Enable Synology Services
You need to enable two network services on your Synology DiskStation.

### 5.1.1. SMB Service
Open `Control Panel` > `File Services` > `SMB/AFP/NFS` and enable the following Services.

* Enable SMB service ☑
  * Workgroup: `WORKGROUP`
  * Disallow access to Previous versions ☐
  * Enable transfer log ☐
* Advanced settings
  * WINS server: `blank`
  * Maximum SMB protocol `SMB3`
  * Minimum SMB protocol ` SMB2`
  * Transport encryption mode `auto`
  * Enable Opportunistic Locking ☑
    * Enable SMB2 lease ☐
  * (the rest leave off ☐)

### 5.1.2. NFS Service
* Enable NFS ☑
  * Enable NFSv4.1 support ☑
    NFSv4 domain: `localdomain.com`
* Advanced Settings
* Apply to default Unix permissions ☑
* (the rest leave off ☐)

## 5.2. Create the required Synology Shared Folders
The following are the minimum set of folder shares required for my configuration and needed for this build and for the scripts to work.

### 5.2.1. Create Shared Folders
We need the following shared folder tree, in addition to your standard default tree, on the Synology NAS ( Note: Use the maintained list [here](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefolderlist) and [here](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefoldersubfolderlist) ):
```
Synology NAS/
│
└──  volume1/
    ├── audio
    │    └── audiobooks
    ├── backup
    ├── books
    ├── cloudstorage
    ├── docker
    ├── downloads
    ├── git
    ├── homes
    ├── music 
    ├── openvpn
    ├── photo
    ├── proxmox
    ├── public
    ├── sshkey
    └── video
          ├── cctv
          ├── documentary
          ├── homevideo
          ├── movies
          ├── musicvideo
          ├── pron
          ├── series
          └── transcode
```
To create shared folders log in to the Synology Desktop. Open `Control Panel` > `Shared Folder` > `Create` and Shared Folder Creation Wizard will open.

#### 5.2.1.1. Set up basic information:
* Name: "i.e audio"
* Description: "leave blank if you want"
* Location: Volume 1 (or whatever volume you want to use)
* Hide this shared ☐ 
* Hide sub-folders ☐ 
* Enable Recycle Bin:
     * audio ☑
     * audio/audiobooks ☐
     * backup ☑
     * books ☐
     * cloudstorage ☑
     * docker ☑
     * downloads ☐
     * git ☑
     * homes ☑
     * music ☑
     * openvpn ☑
     * photo ☑
     * proxmox ☑
     * public ☑
     * ssh_key ☑
     * video ☐ 
     * video/cctv ☑
     * video/documentary ☐
     * video/homevideo ☑
     * video/movies ☐
     * video/pron ☐
     * video/series ☐
     * video/transcode ☐

#### 5.2.1.2. Set up Encryption
* Encrypt this shared folder ☐
#### 5.2.1.3. Configure advanced settings
* Enable data checksum ☐ (enable if using BTRFS)
* Enable file compression  ☐ 
* Enable shared folder quota  ☐

## 5.3. Create Synology User Groups
Create the following User groups.

*  **medialab** - For media Apps (Sonarr, Radar, Jellyfin etc)
*  **homelab** -  For everything to do with your Smart Home (CCTV, Home Assistant)
*  **privatelab** - Power, trusted, admin users
*  **chrootjail** - Chrootjail restricted users


### 5.3.1. Create "medialab" User Group
This user group is for home media content and applications only.

Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 5.3.1.1. Group information
* Name: `medialab`
* Description: `Medialab group`

#### 5.3.1.2. Assign shared folders permissions

| Name | No access | Read/Write | Read Only | Custom
| :---  | :---: | :---: | :---: |:---: |
| audio |  | ☑ | 
| backup |  | ☑ |  
| books |  | ☑ |  
| cloudstorage |   |   |  
| docker |  | ☑ |  
| downloads |  | ☑ |  
| git |   |  |  
| homes |   |  |  
| music |  | ☑ |  
| openvpn |  |  |  
| photo |  | ☑ |  
| public |  | ☑ |  
| proxmox |  |  |  
| public |  | ☑ |  
| ssh_key |  |  |  
| video |  | ☑ |  

#### 5.3.1.3. User quota setting
Up to the you.

#### 5.3.1.4. Assign application permissions
None.
    
### 5.3.2. Create "homelab" User Group
This user group is for smart home applications and general non-critical private user data.

Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 5.3.2.1. Group information
* Name: `homelab`
* Description: `Homelab group`

#### 5.3.2.2. Assign shared folders permissions

| Name | No access | Read/Write | Read Only | Custom
| :---  | :---: | :---: | :---: |:---: |
| audio |  | |  
| backup |  | ☑ |  
| books |  |  |  
| cloudstorage |   | ☑  |  
| docker |  | ☑ |  
| downloads |  |  |  
| git |   |  |  
| homes |   |  |  
| music |  |  |  
| openvpn |  |  |  
| photo |  |  |  
| public |  | ☑ |  
| proxmox |  | ☑ |  
| public |  | ☑ |  
| ssh_key |  |  |  
| video |  |  |  

#### 5.3.2.3. User quota setting
Up to the you.


### 5.3.3. Create "privatelab" User Group
This user group is for your private, personal and strictly confidential data.
Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 5.3.3.1. Group information
* Name: `privatelab`
* Description: `Private group`

#### 5.3.3.2. Assign shared folders permissions

| Name | No access | Read/Write | Read Only | Custom
| :---  | :---: | :---: | :---: |:---: |
| audio |  |☑ |  
| backup |  | ☑ |  
| books |  | ☑ |  
| cloudstorage |   | ☑  |  
| docker |  | ☑ |  
| downloads |  | ☑ |  
| git |   | ☑ |  
| homes |   |  |  
| music |  | ☑ |  
| openvpn |  |☑  |  
| photo |  | ☑ |  
| public |  | ☑ |  
| proxmox |  | ☑ |  
| public |  | ☑ |  
| ssh_key |  | ☑ |  
| video |  | ☑ |  

#### 5.3.3.3. User quota setting
Up to the you.


### 5.3.4. Create "chrootjail" User Group
This user group is for chrootjail users. Users are restricted or jailed within their home folders. But they have read-only access to medialab folders.

Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 5.3.4.1. Group information
* Name: `chrootjail`
* Description: `Chrootjail group`

#### 5.3.4.2. Assign shared folders permissions

| Name | No access | Read/Write | Read Only | Custom
| :---  | :---: | :---: | :---: |:---: |
| audio |  |  |☑ |  
| backup |  |  |  |  
| books |  |  | ☑ |  
| cloudstorage |   |  |  |  
| docker |  |  |  |  
| downloads |  |  |  |  
| git |   |  |  |  
| homes |   |  |  
| music |  |  | ☑ |  
| openvpn |  |  |  |  
| photo |  |  | ☑ |  
| public |  |  | ☑ |  
| proxmox |  |  |  |  
| public |  |  | ☑ |  
| ssh_key |  |  |  |  
| video |  |  | ☑ |  

#### 5.3.4.3. User quota setting
Up to the you.

## 5.4. Create new Synology Users
Here we create the following new Synology users:
*  **media** - username `media` is the user for PVE CT's and VM's used to run media applications (i.e jellyfin, sonarr, radarr, lidarr etc);
*  **home** - username `home` is the user for PVE CT's and VM's used to run homelab applications (i.e syncthing, unifi, nextcloud, home assistant/smart home etc);
*  **private** - username `private` is the user for PVE CT's and VM's used to run privatelab applications (i.e mailserver, messaging etc);

### 5.4.1. Create user "media"
Open `Control Panel` > `Userp` > `Create` and User Creation Wizard will open.

#### 5.4.1.1. User information
* Name: `media`
* Description: `Medialab user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is allways valid ☑

#### 5.4.1.2. Join groups
* medialab ☑
* homelab 
* privatelab
* users ☑

#### 5.4.1.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 5.4.1.4. User quota setting
Leave as default.

#### 5.4.1.5. Assign application permissions
Leave as default.

#### 5.4.1.6. User Speed Limit Setting
Leave as default.

### 5.4.2. Create user "home"
Open `Control Panel` > `Userp` > `Create` and User Creation Wizard will open.

#### 5.4.2.1. User information
* Name: `home`
* Description: `Homelab user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is allways valid ☑

#### 5.4.2.2. Join groups
* medialab ☑
* homelab ☑
* privatelab
* users ☑

#### 5.4.2.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 5.4.2.4. User quota setting
Leave as default.

#### 5.4.2.5. Assign application permissions
Leave as default.

#### 5.4.2.6. User Speed Limit Setting
Leave as default.

### 5.4.3. Create user "private"
Open `Control Panel` > `User` > `Create` and User Creation Wizard will open.

#### 5.4.3.1. User information
* Name: `private`
* Description: `Private user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is always valid ☑

#### 5.4.3.2. Join groups
* medialab ☑
* homelab ☑
* privatelab ☑
* users ☑

#### 5.4.3.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 5.4.3.4. User quota setting
Leave as default.

#### 5.4.3.5. Assign application permissions
Leave as default.

#### 5.4.3.6. User Speed Limit Setting
Leave as default.

  
## 5.5. Create NFS Permissions
Open `Control Panel` > `Shared Folder` > `Select a Folder` > `Edit` > `NFS Permissions` > `Create` and a Create NFS rule box will open.

**Main Folders** - Set NFS rule options as follows for: audio, backup, books, cloudstorage, docker, downloads, git, homes, music, openvpn, photo, proxmox, public, sshkey, video

* Hostname or IP*: `192.168.1.101` `192.168.1.102` `192.168.1.103` `192.168.1.104` (creating a new rule per IP)
* Privilege: `Read/Write`
* Squash: `No mapping`
* Security: `sys/auth_sys`
* Enable asynchronous ☑
* Allow connections from non-privileged ports ☐
* Allow users to access mounted subfolders ☐

**Media vlan** - Set NFS rule options as follows for: audio, music, photo, video
* Hostname or IP*: `192.168.50.0/24` (media player vlan)
* Privilege: `Read/Write`
* Squash: `Map all users to admin`
* Security: `sys/auth_sys`
* Enable asynchronous ☑
* Allow connections from non-privileged ports ☑
* Allow users to access mounted subfolders ☑

## 5.6. Edit Synology NAS GUID and UID
Synology DSM WebGUI Control Panel interface doesn't allow assigning a GUID or UID number when creating any new Linux Groups and Users. Each new group is assigned a random UID upwards of 65536.

We need to edit our newly created GUIDs and UIDs user GID's for Groups medialab, homelab and privatelab and the Users media, home and private.

### 5.6.1. Prepare your Synology
To edit Synology User GUIDs and UIDs you must SSH connect to your Synology (cannot be done via WebGUI).

Prerequisites to complete these tasks are:
*  You must have a nano editor installed on your Synology. To install a nano editor see instructions [here](#51-install-nano).
*  Synology SSH is enabled: Open `Control Panel` > `Terminal & SNMP` > `Enable SSH service` state is on.

### 5.6.2. Edit Synology NAS GUID (Groups)
We need to define each GUID to a known number.

| Synology Group | Old GUID | | New GUID |
| :---  | ---: | :---: | :--- |
| **medialab** | 10XX | ==>> | 65605
| **homelab** | 10XX | ==>> | 65606
| **privatelab** | 10XX | ==>> | 65607
| **chrootjail** | 10XX | ==>> | 65608

Using a CLI terminal to your Synology:
```
# Replace IP with yours
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@nas-01:~$` (replacing `nas-01` with your hostname) if successful.

You need to switch the user to `root`. In the terminal type:
```
sudo -i
```
Next type the following to change all the GUID's:
```
# Edit Medialab GID ID
sed -i 's|medialab:x:*:.*|medialab:x:65605:media,home,private|g' /etc/group &&
# Edit Homelab GID ID
sed -i 's|homelab:x:*:.*|homelab:x:65606:home,private|g' /etc/group &&
# Edit Privatelab GID ID
sed -i 's|privatelab:x:*:.*|privatelab:x:65607:private|g' /etc/group &&
# Edit Chrootjail GID ID
sed -i 's|chrootjail:x:*:.*|chrootjail:x:65608:|g' /etc/group &&
# Rebuild the Users
synouser --rebuild all
```

### 5.6.3. Edit Synology NAS UID (Users)
Synology DSM WebGUI Control Panel interface doesn't allow assigning a UID number when creating a new User. Each new User is assigned a random UID upwards of 1027.

You must edit the User UIDs for 'media', 'home' and 'private'. This must be performed after the GUID modifications.

| Synology Username | Old UID | | New UID |
| :---  | ---: | :---: | :--- |
| **media** | 10XX | ==>> | 1605
| **home** | 10XX | ==>> | 1606
| **private** | 10XX | ==>> | 1607

Again using a CLI terminal connected to your Synology:
```
# Replace IP with yours
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@nas-01:~$` (replacing `nas-01` with your hostname) if successful.

You need to switch the user to `root`. In the terminal type:
```
sudo -i
```
And next type the following to change all the UID's:
```
# Edit Media User ID
userid=$(id -u media)
sed -i 's|media:x:.*|media:x:1605:100:Medialab user:/var/services/homes/media:/sbin/nologin|g' /etc/passwd
find / -uid $userid -exec chown storm "{}" \;
unset userid
# Edit Home User ID
userid=$(id -u home)
sed -i 's|home:x:.*|home:x:1606:100:Homelab user:/var/services/homes/home:/sbin/nologin|g' /etc/passwd
find / -uid $userid -exec chown home "{}" \;
unset userid
# Edit Private User ID
userid=$(id -u private)
sed -i 's|private:x:.*|private:x:1607:100:Privatelab user:/var/services/homes/private:/sbin/nologin|g' /etc/passwd
find / -uid $userid -exec chown private "{}" \;
unset userid
# Rebuild the Users
synouser --rebuild all
```

Your Synology is now ready to be your PVE hosts shared storage.


## 5.7. Set PVE Folder ACL Permissions

Synology DSM WebGUI Control Panel interface allows you to enable and set Folder ACL permissions. Each shared folder must have its ACL permissions set as shown in the table below.

Set your new PVE folder ACL permissions as shown ( Note: Use the maintained list [here](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefolderlist) and [here](https://raw.githubusercontent.com/ahuacate/pve-nas/master/scripts/source/pve_nas_basefoldersubfolderlist) ).

| Folder            | Owner    | Permissions | ACL                                                            |
|-------------------|----------|-------------|----------------------------------------------------------------|
| audio             | root     | 750         | g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx                |
| audio/audiobooks  | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx  |
| backup            | root     | 1750        | g:medialab:rwx,g:homelab:rwx,g:privatelab:rwx                  |
| books             | root     | 755         | g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx                |
| cloudstorage      | root     | 1750        | g:homelab:rwx,g:privatelab:rwx                                 |
| docker            | root     | 750         | g:medialab:rwx,g:homelab:rwx,g:privatelab:rwx                  |
| downloads         | root     | 755         | g:medialab:rwx,g:privatelab:rwx                                |
| git               | root     | 750         | g:privatelab:rwx                                               |
| homes             | root     | 755         |                                                                |
| music             | root     | 755         | g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx                |
| openvpn           | root     | 750         | g:privatelab:rwx                                               |
| photo             | root     | 750         | g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rwx               |
| proxmox           | root     | 750         | g:privatelab:rwx,g:homelab:rwx                                 |
| public            | root     | 1777        | g:medialab:rwx,g:homelab:rwx,g:privatelab:rwx,g:chrootjail:rwx |
| sshkey            | root     | 1750        | g:privatelab:rwx                                               |
| video             | root     | 750         | g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx                |
| video/cctv        | medialab | 750         | g:medialab:rx,g:privatelab:rwx,g:homelab:rwx,g:chrootjail:000  |
| video/documentary | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx  |
| video/homevideo   | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rwx |
| video/movies      | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx  |
| video/musicvideo  | medialab | 750         | g:medialab:rwx,g:homelab:000,g:privatelab:rwx,g:chrootjail:rwx |
| video/pron        | medialab | 750         | g:medialab:rwx,g:homelab:000,g:privatelab:rwx,g:chrootjail:rwx |
| video/series      | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx  |
| video/transcode   | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:000 |

### 5.7.1. Set Folder ACL using Synology DSM WebGUI
To set your folder ACLs using Synology DSM WebGUI go to `Control Panel` > `Shared Folder` > `Select your folder to edit` > `Edit` > `Advanced Permissions` > and Enable advanced share permissions.

Click on `Advanced Share Permissions` > `Local groups` and set each folder ACLs according to the above table.

Below is an example for setting your `audio` shared folder with ACL set at: g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx

| Permission||||
|:-------------------|:----------:|:-------------:|:-------------:|
| ***Local groups***
| **Name**           | **No access**     | **Read/Write**         | **Read only**
| administrators |☐|:heavy_check_mark:|☐
| chrootjail |☐|☐|:heavy_check_mark:
| homelab |☐|:heavy_check_mark:|☐
| http |☐|☐|☐
| medialab |☐|:heavy_check_mark:|☐
| privatelab |☐|:heavy_check_mark:|☐
| users |☐|:heavy_check_mark:|☐

And subfolder `audio/audiobooks` is also set using the Synology DSM WebGUI `File Station` > `audio` > `highlight audiobooks` > `Action` > `Properties`: g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx 

| Properties|||
|:-------------------|:----------:|:-------------:|
| ***General***
| Name | `audiobooks`
| Location | /volume1/audio/audiobooks
| Owner | `medialab`
| ***Permission***
|**User or group**|**Type**|**Permission**
|administrators|Allow|Read & Write
|chrootjail|Allow|Read
|medialab|Allow|Read & Write
|privatelab|Allow|Read & Write



Here is the Linux CLI example for the task audio:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

sudo chgrp -R root ${BASE_FOLDER}/audio
sudo chmod -R 750 ${BASE_FOLDER}/audio
sudo setfacl -Rm g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx  ${BASE_FOLDER}/audio
```
<hr>

# 6. Synology Virtual Machine Manager
If your Synology NAS model is capable ( Intel x86 ) you can install a PVE node on your Synology DiskStation using the native Synology Virtual Machine Manager application.


## 6.1. Download the Proxmox installer ISO
Download the latest Proxmox ISO installer to your PC from  www.proxmox.com or [HERE](https://www.proxmox.com/en/downloads/category/iso-images-pve).

## 6.2. Install Synology Virtual Machine Manager on your NAS
A prerequisite to running any VMs on your Synology NAS is you require a BTRFS file system.

In my experience, the best way to create a BTRFS is to back up your data to an external disk (USB) or another internal volume (be careful and know what you are doing). Then delete and recreate `/volume1` via DSM and restore your backup data. I recommend using Synology Hyper Backup to backup your data and settings.

It's a lengthy topic and the procedures can be found by searching on the internet.

To install Synology Virtual Machine Manager login to the Synology WebGUI interface and open `Synology Package Centre` and install `Virtual Machine Manager`

## 6.3. Configure Synology Virtual Machine Manager
Using the Synology WebGUI interface `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Storage` > `Add` and follow the prompts and configure as follows:

| Tab Title                 |                        Value                        |
|:--------------------------|:---------------------------------------------------:|
| Create a Storage Resource |                       `NEXT`                        |
| Create Storage            | Select/Highlight `nas-01/Volume 1` and Click `NEXT` |
| **Configure General Specifications** 
| Name | `nas-01 - VM Storage 1` |
| Full | Leave Default |
| Low on Space | `10%` |
| Notify me each time the free space ... | `☑` |

And hit `Apply`.

## 6.4. Create a Proxmox VM
Just like a hard metal installation, Proxmox VM requires a hard disk. Except in this case it's a virtual disk.

### 6.4.1. Add the Proxmox VE ISO image to your Synology
Using the Synology WebGUI interface click on Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Image` > `ISO File` > `Add` > `From Computer` and browse to your downloaded Proxmox ISO (i.e proxmox-ve_6.3.iso ) > `Select Storage` > `Choose your host (i.e nas-01)`

### 6.4.2. Create the Proxmox VM machine
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Create` > `Choose OS` > `Linux` > `Select Storage` > `nas-01` > and assign the following values:

| (1) Tab General | Value |--|Options or Notes|
| :---  | :---: | --| :---  |
| Name | `pve-0X` | | Cluster node: pve-02 or pve-03
| CPU's | `1` |
| Memory | `7` | | Or whatever you decide
| Video Card | `vmvga` |
| Description | (optional) |
| | |
| **(2) Tab Storage** | **Value** |--|**Options or Notes**|
| Virtual Disk 1 | `250 Gb` |--|Settings Options: VirtIO SCSI Controller with Space Reclamation enabled|
| | |
| **(3) Tab Network** | **Value** |--|**Options or Notes**|
| Network 1 | Default VM Network |
| | |
| **(4) Tab Others** | **Value** |--|**Options or Notes**|
| ISO file for bootup |i.e proxmox-ve_5.4  |--|Note: select the proxmox ISO uploaded in Step 2|
| Additional ISO file | Unmounted |--|Note: nothing to to select here|
| Autostart | `Last State` |
| Boot from | `Virtual Disk` |
| BIOS | `Legacy BIOS (Recommended)` |
| Keyboard Layout | `Default (en-us)` |
| Virtual USB Controller | `Disabled` |
| USB Device | `Unmounted` |
| | |
| **(5) Tab Permissions** | **Value** |--|**Options or Notes**|
| administrators | `☑` |--|Note: select from 'Local groups'|
| homelab | `☑` | --|Note: select from 'Local groups'|
| http | ☐ | 
| users | ☐ | 
| | |
| **(6) Summary** | **Value** |--|**Options or Notes**|
| Storage | `nas-01 - VM Storage 1` |
| Name | `nas-01 - VM Storage 1` | 
| CPU(s) | `nas-01 - VM Storage 1` | 
| Memory | `nas-01 - VM Storage 1` | 
| Video Card | `nas-01 - VM Storage 1` | 
| Description | `nas-01 - VM Storage 1` | 
| Virtual Disk 1 | `nas-01 - VM Storage 1` | 
| Power on the virtual machine after creation | `☐` | -- | Note: Uncheck

And hit `Apply`.

### 6.4.3. Install Proxmox OS
Now your are going to install Proxmox OS using the installation ISO media. 

#### 6.4.3.1. Power-on PVE-0X VM
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Power On` and wait for the `status` to show `running`.

This is like hitting the power-on button on any hard metal machine --- but a virtual boot.

#### 6.4.3.2. Run the Proxmox ISO Installation
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Connect` and a new browser tab should open showing the Proxmox installation script. The installation is much the same as a hard metal installation you would've performed for pve-01 or pve-02.

To start the install, on the new browser tab, use your keyboard arrow keys with `Install Proxmox VE` selected then hit your `ENTER` key to begin the installation script.

Your first user prompt will probably be a window saying "No support for KVM virtualization detected. Check BIOS settings for Intel VT/AMD-V/SVM" so click `OK` then to the End User Agreement click `I Agree`.

Now configure the installation fields for the node as follows:
   
| Option | PVE-0X Value | Options or Notes |
| :---  | :---: | :--- |
| Hardware Type | Synology VM |
| Target Disk | `/dev/sda (250GB, iSCSI Storage)` 
| Target Disk - Option | `zfs` |
| Country | Type your Country
| Timezone | Select |
| Keymap |`en-us`|
| Password| Enter your new password | Same password as you used on your other nodes
| E-mail |Enter your email | Enter a valid admin email - best to do
| Management interface |Leave Default
| Hostname |`pve-0X.localdomain` |
| IP Address |`192.168.1.10X`|
| Netmask |`255.255.255.0`|
| Gateway |`192.168.1.5`|
| DNS Server |`192.168.1.5`|

Finally, click `Reboot` and your VM Proxmox node will reboot.

## 6.5. Configure the Proxmox VM
Configuration is now done via the Proxmox web interface. Just point your browser to the IP address given during installation (https://192.168.1.10X:8006) and ignore the security warning by clicking `Advanced` then `Accept the Risk and Continue` -- this is the warning I get in Firefox. The default login is "root" (realm PAM) and the root password you defined during the installation process.

### 6.5.1. Update Proxmox OS VM and enable turnkey Linux templates
Using the web interface `updates` > `refresh` search for all the latest required updates. You will get a few errors which ignore.
Next, install the updates using the web interface `updates` > `_upgrade` - a pop-up terminal will show the installation steps of all your required updates and it will prompt you to type `Y` so do so.

Next, install turnkey Linux container templates by using the web interface CLI `shell` and type
`pveam update`

Your Synology DiskStation Proxmox VM node is ready.

<hr>

# 7. Patches and Fixes

## 7.1. Install Nano
Install Nano as a SynoCommunity package.

Log in to the Synology Desktop and go to `Package Center` > `Settings` > `Package Sources` > `Add` and complete the fields as follows:

| Option   | Value                                |
|----------|--------------------------------------|
| Name     | `SynoCommunity`                      |
| Location | `http://packages.synocommunity.com/` |

And click `OK`. Then type in the search bar 'nano' and install Nano.






# 2. OMV
Under development. Coming soon.

<hr>

# 3. Hard Metal NAS
A hard metal NAS is a dedicated network file server ( non-proxmox ). I have written Easy Scripts for Users with Synology DiskStations and Linux debian based appliances.

## 3.1. Hard Metal NAS Prerequisites
It's assumed the installer has some Linux skills. There are lots of online guides about how to configure OEM NAS brands and Linux networking.

- **NFS**
Your NAS NFS server must support NFSv3/v4.
- **SMB/CIFS**
Your NAS SMB/CIFS server must support SMB3 protocol (PVE default). SMB1 is NOT supported.
- **ACL**
Access control list (ACL) provides an additional, more flexible permission mechanism for your PVE storage pools. Enable ACL.

## 3.2. Easy Script setup
If you have a Synology DiskStation or Debian based Linux NAS take the easy route and use a Easy Script. With minor user input the script will fully configure your NAS appliance in under 30 seconds.

### 3.2.1. Linux NAS Installer/Builder ( hard metal )
You must first SSH login to your NAS `ssh root@IP_address` or if you have changed your default SSH port use `ssh root@IP_address:port`. Then you must run the following commands:
```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-nas/master/linux_nas_installer.sh)"
```
### 3.2.2. Synology NAS Installer/Builder ( hard metal )
You must first SSH login to your Synology `ssh admin@IP_address` or if you have changed your Synology default SSH port use `ssh admin@IP_address:port`. Then you must run the following commands to login as User root:
```bash
sudo -i # You will prompted for a root password which is the same as User 'admin'
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-nas/master/synology_nas_installer.sh)"
```

<hr>

# 4. Other Linux NAS Types & Basic NAS Building
This guide is for setting up any Linux-based NAS ( QNAP, or whatever Linux flavour, etc ) to support our PVE host nodes, PVE CT/VM applications, and all our CT installation scripts.

It's important you strictly follow this guide. Our PVE CT and VMs all have specific UIDs and GUIDs, Linux file permissions including ACLs and NAS storage needs.

## 4.1. Prerequisites
It's assumed the installer has some Linux skills. There are lots of online guides about how to configure NAS brands and Linux networking.

- **NFS**
Your NAS NFS server must support NFSv3/v4.
- **SMB/CIFS**
Your NAS SMB/CIFS server must support SMB3 protocol (PVE default). SMB1 is NOT supported.
- **ACL**
Access control list (ACL) provides an additional, more flexible permission mechanism for your PVE storage pools. Enable ACL.

## 4.2. Create Users and Groups
All our PVE CT applications require a specific set of UID and GUID to work properly. So make sure your UIDs and GUIDs exactly match our guide.

| Defaults                | Description             | Notes                                                                                                                |
|-------------------------|-------------------------|----------------------------------------------------------------------------------------------------------------------|
| **Default User Groups** |                         |                                                                                                                      |
|                         | medialab - GUID 65605   | For media Apps (Sonarr, Radar, Jellyfin etc)                                                                         |
|                         | homelab - GUID 65606    | For everything to do with your Smart Home (CCTV, Home Assistant)                                                     |
|                         | privatelab - GUID 65607 | Power, trusted, admin Users                                                                                          |
|                         | chrootjail - GUID 65608 | Users are restricted or jailed within their own home folder. But they they have read only access to medialab folders |
| **Default Users**       |                         |                                                                                                                      |
|                         | media - UID 1605        | Member of group medialab                                                                                             |
|                         | home - UID 1606         | Member of group homelab. Supplementary member of group medialab                                                      |
|                         | private - UID 1607      | Member of group privatelab. Supplementary member of group medialab, homelab                                         |


## 4.3. Create PVE Groups
Create the following Groups.

| Group Name | GUID  |
|------------|-------|
| medialab   | 65605 |
| homelab    | 65606 |
| privatelab | 65607 |
| chrootjail | 65608 |

## 4.4. Change the NAS Home folder permissions (optional)
Proceed with caution. If you are NOT sure skip this step.

Linux `/etc/adduser.conf` has a `DIR_MODE` setting which sets a Users HOME directory when its first created. The default mode likely 0755.

For added security we change this to 0750 where:
> 0755 = User:`rwx` Group:`r-x` World:`r-x`
0750 = User:`rwx` Group:`r-x` World:`---` (i.e. World: no access)

Depending on your NAS you may be able to change this setting 
```
sed -i "s/DIR_MODE=.*/DIR_MODE=0750/g" /etc/adduser.conf
```

Running the above command will change all-new User HOME folder permissions to `0750` globally on your NAS.

## 4.5. Modify PVE Users Home Folder
Set `/base_folder/homes` permissions for Users media. home and private.

| Owner | Permissions |
|-------|-------------|
| root  | 0750        |


Here is the Linux CLI for the task:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2/homes)"

sudo mkdir -p ${BASE_FOLDER}/homes
sudo chgrp -R root ${BASE_FOLDER}/homes
sudo chmod -R 0750 ${BASE_FOLDER}/homes
```

## 4.6. Create PVE Users
Create our list of PVE users. These are required by various PVE CT applications. Without them, nothing will work.

| Username  | UID | Home Folder | Group Member
|---|---|---|---|---|
|  media |  1605 | /BASE_FOLDER/homes/media | medialab
|  home |  1606 | /BASE_FOLDER/homes/home | homelab
|  private |  1607 | /BASE_FOLDER/homes/private | privatelab

Here is the Linux CLI for the task:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

# Create User media
useradd -m -d ${BASE_FOLDER}/homes/media -u 1605 -g medialab -s /bin/bash media
# Create User home
useradd -m -d ${BASE_FOLDER}/homes/home -u 1606 -g homelab -G medialab -s /bin/bash home
# Create User private
useradd -m -d ${BASE_FOLDER}/homes/private -u 1607 -g privatelab -G medialab,homelab -s /bin/bash private
```

## 4.7. NAS Folder Shares
You need to create a set of folder shares in a 'storage volume' on your NAS. The new folder shares are mounted by your PVE hosts as NFS or SMB/CIFS mount points for creating your PVE host backend storage ( pve-01 ).

We refer to the NAS 'storage volume' as your NAS 'base folder'.

> For example, on a Synology the default volume is `/volume1`. So on a Synology our "base folder" would be: `/volume1`.

Your NAS may already have some of the required folder structure. If so, then create the sub-directory where applicable.

Create the following folders on your NAS.
```
# 65605=medialab
# 65606=homelab
# 65607=privatelab
# 65608=chrootjail
# FOLDERNAME GROUP PERMISSIONS ACL

Your NAS (nas-01)
│
└──  base volume/
    ├── audio - root 0750 65605:rwx 65607:rwx 65608:rx
    ├── backup - root 1750 65605:rwx 65606:rwx 65607:rwx
    ├── books - root 0755 65605:rwx 65607:rwx 65608:rx
    ├── cloudstorage - root 1750 65606:rwx 65607:rwx
    ├── docker - root 0750 65605:rwx 65606:rwx 65607:rwx
    ├── downloads - root 0755 65605:rwx 65607:rwx
    ├── git - root 0750 65607:rwx
    ├── homes - root 0777
    ├── music - root 0755 65605:rwx 65607:rwx 65608:rx
    ├── openvpn - root 0750 65607:rwx
    ├── photo - root 0750 65605:rwx 65607:rwx 65608:rx
    ├── proxmox - root 0750 65607:rwx 65606:rwx
    ├── public - root 1777 65605:rwx 65606:rwx 65607:rwx 65608:rwx
    ├── sshkey - root 1750 65607:rwx
    └── video - root 0750 65605:rwx 65607:rwx 65608:rx
```

## 4.8. Folder Permissions
Create sub-folders with permissions as shown [here.](https://raw.githubusercontent.com/ahuacate/common/master/nas/src/nas_basefolderlist)

A CLI example for the task audio:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

sudo chgrp -R root ${BASE_FOLDER}/audio
sudo chmod -R 750 ${BASE_FOLDER}/audio
sudo setfacl -Rm g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx  ${BASE_FOLDER}/audio
```

## 4.9. Sub Folder Permissions
Create sub-folders with permissions as shown [here.](https://raw.githubusercontent.com/ahuacate/common/master/nas/src/nas_basefoldersubfolderlist)

```
/srv/nas-01
├── audio
│   ├── audiobooks
│   └── podcasts
├── backup
├── books
│   ├── comics
│   ├── ebooks
│   └── magazines
├── cloudstorage
├── docker
├── downloads
├── git
├── homes
│   ├── chrootjail
│   └── home
├── music
├── openvpn
├── photo
├── proxmox
│   └── backup
├── public
│   └── autoadd
│       ├── direct_import
│       │   └── lazylibrarian
│       ├── torrent
│       │   ├── documentary
│       │   ├── flexget-movies
│       │   ├── flexget-series
│       │   ├── lazy
│       │   ├── movies
│       │   ├── music
│       │   ├── pron
│       │   ├── series
│       │   └── unsorted
│       ├── usenet
│       │   ├── documentary
│       │   ├── flexget-movies
│       │   ├── flexget-series
│       │   ├── lazy
│       │   ├── movies
│       │   ├── music
│       │   ├── pron
│       │   ├── series
│       │   └── unsorted
│       └── vidcoderr
│           ├── in_homevideo
│           ├── in_stream
│           │   ├── documentary
│           │   ├── movies
│           │   ├── musicvideo
│           │   ├── pron
│           │   └── series
│           ├── in_unsorted
│           └── out_unsorted
├── sshkey
└── video
    ├── cctv
    ├── documentary
    ├── homevideo
    ├── movies
    ├── musicvideo
    ├── pron
    ├── series
    ├── stream
    │   ├── documentary
    │   ├── movies
    │   ├── musicvideo
    │   ├── pron
    │   └── series
    └── transcode
```

## 4.10. Create PVE SMB (SAMBA) Shares
Your `/etc/samba/smb.conf` file should include the following PVE shares. This is an example from a Ubuntu NAS.

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also, you must restart your NFS service to invoke the changes.

The sample file is from a Ubuntu 21.04 server.

```
[global]
workgroup = WORKGROUP
server string = nas-05
server role = standalone server
disable netbios = yes
dns proxy = no
interfaces = 127.0.0.0/8 eth0
bind interfaces only = yes
log file = /var/log/samba/log.%m
max log size = 1000
syslog = 0
panic action = /usr/share/samba/panic-action %d
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes
map to guest = bad user
usershare allow guests = yes
inherit permissions = yes
inherit acls = yes
vfs objects = acl_xattr
follow symlinks = yes
hosts allow = 127.0.0.1 192.168.1.0/24 192.168.20.0/24 192.168.30.0/24 192.168.40.0/24 192.168.50.0/24 192.168.60.0/24 192.168.80.0/24
hosts deny = 0.0.0.0/0

[homes]
comment = home directories
browseable = yes
read only = no
create mask = 0775
directory mask = 0775
hide dot files = yes
valid users = %S

[public]
comment = public anonymous access
path = /srv/nas-01/public
writable = yes
browsable =yes
public = yes
read only = no
create mode = 0777
directory mode = 0777
force user = nobody
guest ok = yes
hide dot files = yes

[audio]
  comment = audio folder access
  path = /srv/nas-01/audio
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @privatelab


[backup]
  comment = backup folder access
  path = /srv/nas-01/backup
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @homelab, @privatelab


[books]
  comment = books folder access
  path = /srv/nas-01/books
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @privatelab


[cloudstorage]
  comment = cloudstorage folder access
  path = /srv/nas-01/cloudstorage
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @homelab, @privatelab


[docker]
  comment = docker folder access
  path = /srv/nas-01/docker
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @homelab, @privatelab


[downloads]
  comment = downloads folder access
  path = /srv/nas-01/downloads
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @privatelab


[git]
  comment = git folder access
  path = /srv/nas-01/git
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @privatelab


[music]
  comment = music folder access
  path = /srv/nas-01/music
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @privatelab


[openvpn]
  comment = openvpn folder access
  path = /srv/nas-01/openvpn
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @privatelab


[photo]
  comment = photo folder access
  path = /srv/nas-01/photo
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @medialab, @privatelab


[proxmox]
  comment = proxmox folder access
  path = /srv/nas-01/proxmox
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @privatelab, @homelab


[sshkey]
  comment = sshkey folder access
  path = /srv/nas-01/sshkey
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S, @root, @privatelab


[video]
  comment = video folder access
  path = /srv/nas-01/video
  browsable = yes
  read only = no
  create mask = 0775
  directory mask = 0775
  valid users = %S @root, @medialab, @privatelab
```

## 4.11. Create PVE NFS Shares
Modify your NFS exports file `/etc/exports` to include the following.

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also, note each NFS export is defined a PVE hostname or IPv4 address for all primary and secondary (cluster nodes) machines. Modify if your PVE host is different.

The sample file is from a Ubuntu 21.04 server. In these example we use hostname exports 'pve-01 to 04'.

```
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#

# backup export
/srv/nas-04/backup pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# cloudstorage export
/srv/nas-04/cloudstorage pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# docker export
/srv/nas-04/docker pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# downloads export
/srv/nas-04/downloads pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# proxmox export
/srv/nas-04/proxmox pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# public export
/srv/nas-04/public pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# audio export
/srv/nas-04/audio pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# books export
/srv/nas-04/books pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# music export
/srv/nas-04/music pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# photo export
/srv/nas-04/photo pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# video export
/srv/nas-04/video pve-01(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-02(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-03(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) pve-04(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)
```