<h2> OEM NAS + Linux Filer Server Setup</h2>

This guide is for setting up a OEM NAS or a Linux based File Server as network storage (NAS) for our PVE hosts and PVE CT applications. If you are using our PVE NAS solution, where storage is on a PVE host machine, then this guide is not relevant to you.

If you require a NAS solution try our [PVE NAS](https://github.com/ahuacate/pve-zfs-nas) which has a Easy Script for building a fully functional and pre-configured NAS hosted by Proxmox. 

A OEM NAS is a manufactured NAS appliance by Synology, QNap, FreeNAS, OMV or whatever flavour of NAS you have. Many are Linux based. Our guides include Linux commands to assist you. 

> It's important you follow this guide because all our PVE CT applications, whether it be Sonarr or Home Assistant applications, require NAS storage based on UIDs and GUIDs and Linux file permissions including ACLs.

A section of this guide is dedicated to Synology DiskStations. With the Synology DiskStation OS you CANNOT assign UIDs and GUIDs using the WebGui. I have written a guide how to use CLI to modify and set the UIDs and GUIDs. If you use a Synology DiskStation NAS with our PVE hosts builds then your MUST follow our guide.

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
- [x] x86 CPU Intel CPU (only required if running VMs)
- [x] Volume is formatted to BTRFS (not ext4, which doesn't support Synology Virtual Machines)

>  **Note: A prerequisite to running any VMs on a Synology DiskStation NAS is your volumes must use the BTRFS file system - without BTRFS you CANNOT install VM's. In my experience the best way forward is based upon backing up your data to a external disk (USB) or another internal volume (be careful and know what you are doing), deleting and recreating /volume1 via DSM and restoring your backup data. I recommend using Synology Hyper Backup for backing up your data and settings.**
>  **Its a lengthy topic and the procedures can be found by searching on the internet. The following tutorials assumes your Volume 1 is in the BTRFS file system format.**

<h4>Easy Script</h4>

Our single Easy Script can ONLY be used on Ubuntu systems. It may work on other Linux OS - best check the Bash script first. Your user input is required. The script will create, edit and/or change system files on your machine. When an optional default setting is provided you can accept our default (recommended) by pressing ENTER on your keyboard. Or overwrite our default value by typing in your own value and then pressing ENTER to accept and to continue to the next step.

Easy Scripts are based on bash scripting. Simply `Cut & Paste` our Easy Script command into your terminal window, press `Enter` and follow the prompts and terminal instructions. 

**Installation**
After executing the Easy Script the installer is prompted to configure their Ubuntu machine. Script tasks include:

- Create a default set of PVE folders
- Create PVE Linux Users and Groups (UID & GUID)
- Setup PVE folder permissions
- Setup SMB shares
- Setup NFS shares

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/nas-oem-setup/master/scripts/nas_oem_setup_nas_linux_setup.sh)
```
<h4>Table of Contents</h4>
<!-- TOC -->

- [1. Introduction](#1-introduction)
- [2. Preparing a OEM NAS or Linux Server](#2-preparing-a-oem-nas-or-linux-server)
    - [2.1. NFS Prerequisites](#21-nfs-prerequisites)
    - [2.2. CIFS/SMB Prerequisites](#22-cifssmb-prerequisites)
    - [2.3. ACL Prerequisites](#23-acl-prerequisites)
    - [2.4. PVE Folder Structure](#24-pve-folder-structure)
    - [2.5. Create our PVE Users and Groups](#25-create-our-pve-users-and-groups)
        - [2.5.1. PVE Linux Groups](#251-pve-linux-groups)
            - [2.5.1.1. Create PVE Groups](#2511-create-pve-groups)
        - [2.5.2. PVE Linux Users](#252-pve-linux-users)
            - [2.5.2.1. Change the NAS Home folder permissions (optional)](#2521-change-the-nas-home-folder-permissions-optional)
            - [2.5.2.2. Modify PVE Users Home Folder](#2522-modify-pve-users-home-folder)
            - [2.5.2.3. Create PVE Users](#2523-create-pve-users)
        - [2.5.3. Set PVE Folder Permissions](#253-set-pve-folder-permissions)
    - [2.6. Create PVE SMB (SAMBA) Shares](#26-create-pve-smb-samba-shares)
    - [2.7. Create PVE SMB (SAMBA) Shares](#27-create-pve-smb-samba-shares)
- [3. Preparing a Synology NAS](#3-preparing-a-synology-nas)
    - [3.1. Enable Synology Services](#31-enable-synology-services)
        - [3.1.1. SMB Service](#311-smb-service)
        - [3.1.2. NFS Service](#312-nfs-service)
    - [3.2. Create the required Synology Shared Folders](#32-create-the-required-synology-shared-folders)
        - [3.2.1. Create Shared Folders](#321-create-shared-folders)
            - [3.2.1.1. Set up basic information:](#3211-set-up-basic-information)
            - [3.2.1.2. Set up Encryption](#3212-set-up-encryption)
            - [3.2.1.3. Configure advanced settings](#3213-configure-advanced-settings)
    - [3.3. Create Synology User Groups](#33-create-synology-user-groups)
        - [3.3.1. Create "medialab" User Group](#331-create-medialab-user-group)
            - [3.3.1.1. Group information](#3311-group-information)
            - [3.3.1.2. Assign shared folders permissions](#3312-assign-shared-folders-permissions)
            - [3.3.1.3. User quota setting](#3313-user-quota-setting)
            - [3.3.1.4. Assign application permissions](#3314-assign-application-permissions)
        - [3.3.2. Create "homelab" User Group](#332-create-homelab-user-group)
            - [3.3.2.1. Group information](#3321-group-information)
            - [3.3.2.2. Assign shared folders permissions](#3322-assign-shared-folders-permissions)
            - [3.3.2.3. User quota setting](#3323-user-quota-setting)
        - [3.3.3. Create "privatelab" User Group](#333-create-privatelab-user-group)
            - [3.3.3.1. Group information](#3331-group-information)
            - [3.3.3.2. Assign shared folders permissions](#3332-assign-shared-folders-permissions)
            - [3.3.3.3. User quota setting](#3333-user-quota-setting)
    - [3.4. Create new Synology Users](#34-create-new-synology-users)
        - [3.4.1. Create user "media"](#341-create-user-media)
            - [3.4.1.1. User information](#3411-user-information)
            - [3.4.1.2. Join groups](#3412-join-groups)
            - [3.4.1.3. Assign shared folders permissions](#3413-assign-shared-folders-permissions)
            - [3.4.1.4. User quota setting](#3414-user-quota-setting)
            - [3.4.1.5. Assign application permissions](#3415-assign-application-permissions)
            - [3.4.1.6. User Speed Limit Setting](#3416-user-speed-limit-setting)
        - [3.4.2. Create user "home"](#342-create-user-home)
            - [3.4.2.1. User information](#3421-user-information)
            - [3.4.2.2. Join groups](#3422-join-groups)
            - [3.4.2.3. Assign shared folders permissions](#3423-assign-shared-folders-permissions)
            - [3.4.2.4. User quota setting](#3424-user-quota-setting)
            - [3.4.2.5. Assign application permissions](#3425-assign-application-permissions)
            - [3.4.2.6. User Speed Limit Setting](#3426-user-speed-limit-setting)
        - [3.4.3. Create user "private"](#343-create-user-private)
            - [3.4.3.1. User information](#3431-user-information)
            - [3.4.3.2. Join groups](#3432-join-groups)
            - [3.4.3.3. Assign shared folders permissions](#3433-assign-shared-folders-permissions)
            - [3.4.3.4. User quota setting](#3434-user-quota-setting)
            - [3.4.3.5. Assign application permissions](#3435-assign-application-permissions)
            - [3.4.3.6. User Speed Limit Setting](#3436-user-speed-limit-setting)
    - [3.5. Create NFS Permissions](#35-create-nfs-permissions)
    - [3.6. Edit Synology NAS GUID and UID](#36-edit-synology-nas-guid-and-uid)
        - [3.6.1. Prepare your Synology](#361-prepare-your-synology)
        - [3.6.2. Edit Synology NAS GUID (Groups)](#362-edit-synology-nas-guid-groups)
        - [3.6.3. Edit Synology NAS UID (Users)](#363-edit-synology-nas-uid-users)
- [4. Synology Virtual Machine Manager](#4-synology-virtual-machine-manager)
    - [4.1. Download the Proxmox installer ISO](#41-download-the-proxmox-installer-iso)
    - [4.2. Install Synology Virtual Machine Manager on your NAS](#42-install-synology-virtual-machine-manager-on-your-nas)
    - [4.3. Configure Synology Virtual Machine Manager](#43-configure-synology-virtual-machine-manager)
    - [4.4. Create a Proxmox VM](#44-create-a-proxmox-vm)
        - [4.4.1. Add the Proxmox VE ISO image to your Synology](#441-add-the-proxmox-ve-iso-image-to-your-synology)
        - [4.4.2. Create the Proxmox VM machine](#442-create-the-proxmox-vm-machine)
        - [4.4.3. Install Proxmox OS](#443-install-proxmox-os)
            - [4.4.3.1. Power-on PVE-0X VM](#4431-power-on-pve-0x-vm)
            - [4.4.3.2. Run the Proxmox ISO Installation](#4432-run-the-proxmox-iso-installation)
    - [4.5. Configure the Proxmox VM](#45-configure-the-proxmox-vm)
        - [4.5.1. Update Proxmox OS VM and enable turnkeylinux templates](#451-update-proxmox-os-vm-and-enable-turnkeylinux-templates)
- [5. Patches and Fixes](#5-patches-and-fixes)
    - [5.1. Install Nano](#51-install-nano)

<!-- /TOC -->

<hr>

# 1. Introduction

All our PVE CT applications require backend storage pools. A backend storage pools is a NFS or CIFS mount point to your NAS appliance folder shares (nas-01). Backend storage pools are ONLY setup on your primary PVE node (pve-01).

This is a shared storage pool system because all backend storage pools get automatically mounted and distributed to all PVE cluster nodes. Because all PVE nodes share the same storage configuration the backend storage mount points are available on all PVE nodes. Every backend storage pool can be physically different, either a NFS or CIFS mount, or a combination of both NFS and CIFS, and are individually labelled accessing different content.

Once your PVE backend storage is setup a PVE CT application local disk storage is actually disk storage space on your network NAS appliance.

There are basically four task levels in setting up your NAS.
1. Install NFS and CIFS/SMB on your NAS
2. Create our default set of Users and Groups each with our UIDs and GUIDs
2. Create our default set of shared folders
3. Set folder permissions


# 2. Preparing a OEM NAS or Linux Server
This is a basic guide and assumes the installer has some Linux skills. There are lots of online guides about how to configure a OEM NAS and Linux networking.

If you have a Ubuntu Filer Server then best use our Easy Script.

Most OEM NAS have a Web Management interface for all configuration tasks.

## 2.1. NFS Prerequisites
Your NAS NFS server must support NFSv3/v4.

## 2.2. CIFS/SMB Prerequisites
Your NAS CIFS/SMB server must support SMB3 protocol (PVE default). SMB1 is NOT supported.

## 2.3. ACL Prerequisites
Access control list (ACL) provides an additional, more flexible permission mechanism for your PVE storage pools. It is designed to assist with UNIX file permissions. ACL allows you to give permissions for any user or group to any disc resource. Best install ACL.

## 2.4. PVE Folder Structure
You need to create a set of PVE folders in a storage volume on your NAS. You should choose the volume with the most Gb of storage space. On a NAS this is usually a Raid volume consisting of more than disk. It depends on your NAS.

The new folders are your PVE hosts NFS and CIFS mount points for creating your PVE host backend storage (pve-01).

We refer to this storage volume as your NAS "base folder".

> For example, on a Synology the default volume is `/volume1`. So on a Synology we would create our "base folder" here: `/volume1`.

Your NAS may already have some of the folder structure. Then create the sub-directory where applicable.

Create the following folders on your NAS.
```
Your NAS (nas-01)
│
└──  base volume/
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
          ├── tv
          └── transcode
```

## 2.5. Create our PVE Users and Groups
Create the following exactly as shown. All our PVE CT applications require a specific set of UID and GUID to work properly. So make sure your UIDs and GUIDs exactly match our guide.

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
|                         | private - UID 1607      | Member of group private lab. Supplementary member of group medialab, homelab                                         |

### 2.5.1. PVE Linux Groups
The critical part is the GUID of each Linux Group. They are high in number value only because of the peculiar Synology DiskStation OS UID and GUID numbering convention (low GUIDs cannot be created on a Synology). Our GUID should work with any other Linux OEM NAS or Linux File Server.

#### 2.5.1.1. Create PVE Groups
Create the following Linux Groups.

| Group Name | GUID  |
|------------|-------|
| medialab   | 65605 |
| homelab    | 65606 |
| privatelab | 65607 |
| chrootjail | 65608 |


### 2.5.2. PVE Linux Users
Again the critical part is the UID for each Linux User. It must be set as shown.

#### 2.5.2.1. Change the NAS Home folder permissions (optional)
Proceed with caution. If you are NOT sure skip this step. This is for Linux File Servers not OEM NAS boxes.

Linux `/etc/adduser.conf` has a `DIR_MODE` setting which sets a Users HOME directory when its first created. The default mode likely 0755.

For added security we change this to 0750 where:
> 0755 = User:`rwx` Group:`r-x` World:`r-x`
0750 = User:`rwx` Group:`r-x` World:`---` (i.e. World: no access)

Depending on your NAS you may be able to change this setting 
```
sed -i "s/DIR_MODE=.*/DIR_MODE=0750/g" /etc/adduser.conf
```

Running the above command will change only all new Users HOME folder permissions to `0750` globally on your NAS.

#### 2.5.2.2. Modify PVE Users Home Folder
Set `/base_folder/homes` permissions.

| Owner | Permissions |
|-------|-------------|
| root  | 0750        |


Here is the Linux CLI for the task:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2/homes)"

sudo mkdir -p $BASE_FOLDER/homes
sudo chgrp -R root $BASE_FOLDER/homes
sudo chmod -R 0750 $BASE_FOLDER/homes
```

#### 2.5.2.3. Create PVE Users
Create our list of PVE users. These are required by various PVE CT applications. Without them nothing will work.

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
useradd -m -d $BASE_FOLDER/homes/media -u 1605 -g medialab -s /bin/bash media
# Create User home
useradd -m -d $BASE_FOLDER/homes/home -u 1606 -g homelab -G medialab -s /bin/bash home
# Create User private
useradd -m -d $BASE_FOLDER/homes/private -u 1607 -g privatelab -G medialab,homelab -s /bin/bash private
```

### 2.5.3. Set PVE Folder Permissions

Set your new PVE folder permissions as shown.

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
| video/tv          | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:rx  |
| video/transcode   | medialab | 750         | g:medialab:rwx,g:privatelab:rwx,g:homelab:000,g:chrootjail:000 |



Here is the Linux CLI example for the task audio:
```
# Set VAR
BASE_FOLDER="insert full path (i.e /dir1/dir2)"

sudo chgrp -R root $BASE_FOLDER/audio
sudo chmod -R 750 $BASE_FOLDER/audio
sudo setfacl -Rm g:medialab:rwx,g:privatelab:rwx,g:chrootjail:rx  $BASE_FOLDER/audio
```

## 2.6. Create PVE SMB (SAMBA) Shares
Your `/etc/samba/smb.conf` file should include the following PVE shares. 

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also you must restart your NFS service to invoke the changes.

```
[global]
workgroup = WORKGROUP
server string = nas-01
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
path = /BASE_FOLDER/public
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
path = /BASE_FOLDER/audio
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

[backup]
comment = backup folder access
path = /BASE_FOLDER/backup
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @homelab, @privatelab

[books]
comment = books folder access
path = /BASE_FOLDER/books
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

[cloudstorage]
comment = cloudstorage folder access
path = /BASE_FOLDER/cloudstorage
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @homelab, @privatelab

[docker]
comment = docker folder access
path = /BASE_FOLDER/docker
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @homelab, @privatelab

[downloads]
comment = downloads folder access
path = /BASE_FOLDER/downloads
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

[git]
comment = git folder access
path = /BASE_FOLDER/git
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @privatelab

[music]
comment = music folder access
path = /BASE_FOLDER/music
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

[openvpn]
comment = openvpn folder access
path = /BASE_FOLDER/openvpn
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @privatelab

[photo]
comment = photo folder access
path = /BASE_FOLDER/photo
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

[proxmox]
comment = proxmox folder access
path = /BASE_FOLDER/proxmox
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @privatelab, @homelab

[sshkey]
comment = sshkey folder access
path = /BASE_FOLDER/sshkey
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @privatelab

[video]
comment = video folder access
path = /BASE_FOLDER/video
browsable =yes
read only = no
create mask = 0775
directory mask = 0775
valid users = %S, @root, @medialab, @privatelab

```

## 2.7. Create PVE SMB (SAMBA) Shares
Modify your NFS exports file `/etc/exports` to include the following.

Remember to replace `BASE_FOLDER` with your full path (i.e /dir1/dir2). Also note each NFS export defines a PVE host IPv4 addresses for primary and secondary (cluster nodes) machines. Modify if your PVE host are different.

The sample file is from a Ubuntu 20.10 server.

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
/BASE_FOLDER/backup 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# cloudstorage export
/BASE_FOLDER/cloudstorage 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# docker export
/BASE_FOLDER/docker 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# downloads export
/BASE_FOLDER/downloads 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# proxmox export
/BASE_FOLDER/proxmox 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# public export
/BASE_FOLDER/public 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# audio export
/BASE_FOLDER/audio 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# books export
/BASE_FOLDER/books 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# music export
/BASE_FOLDER/music 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# photo export
/BASE_FOLDER/photo 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)

# video export
/BASE_FOLDER/video 192.168.1.101(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.102(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.103(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.1.104(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100) 192.168.50.0/24(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)
```


# 3. Preparing a Synology NAS

## 3.1. Enable Synology Services
You need to enable two network services on your Synology DiskStation.

### 3.1.1. SMB Service
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
  * Enable Oppurtunistic Locking ☑
    * Enable SMB2 lease ☐
  * (the rest leave off ☐)

### 3.1.2. NFS Service
* Enable NFS ☑
  * Enable NFSv4.1 support ☑
    NFSv4 domain: `localdomain.com`
* Advanced Settings
* Apply default Unix permissions ☑
* (the rest leave off ☐)

## 3.2. Create the required Synology Shared Folders
The following are the minimum set of folder shares required for my configuration and needed for this build and for the scripts to work.

### 3.2.1. Create Shared Folders
We need the following shared folder tree, in addition to your standard default tree, on the Synology NAS:
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
          ├── tv
          └── transcode
```
To create shared folders log in to the Synology Desktop. Open `Control Panel` > `Shared Folder` > `Create` and Shared Folder Creation Wizard will open.

#### 3.2.1.1. Set up basic information:
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
     * video/tv ☐
     * video/transcode ☐

#### 3.2.1.2. Set up Encryption
* Encrypt this shared folder ☐
#### 3.2.1.3. Configure advanced settings
* Enable data checksum ☐ (enable if using BTRFS)
* Enable file compression  ☐ 
* Enable shared folder quota  ☐

## 3.3. Create Synology User Groups
Create the following User groups.

*  **medialab** - For media Apps (Sonarr, Radar, Jellyfin etc)
*  **homelab** -  For everything to do with your Smart Home (CCTV, Home Assistant)
*  **privatelab** - Power, trusted, admin Users


### 3.3.1. Create "medialab" User Group
This user group is for home media content and applications only.

Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 3.3.1.1. Group information
* Name: `medialab`
* Description: `Medialab group`

#### 3.3.1.2. Assign shared folders permissions

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

#### 3.3.1.3. User quota setting
Up to the you.

#### 3.3.1.4. Assign application permissions
None.
    
### 3.3.2. Create "homelab" User Group
This user group is for smart home applications and general non-critical private user data.

Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 3.3.2.1. Group information
* Name: `homelab`
* Description: `Homelab group`

#### 3.3.2.2. Assign shared folders permissions

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

#### 3.3.2.3. User quota setting
Up to the you.


### 3.3.3. Create "privatelab" User Group
This user group is for your private, personal and strictly confidential data.
Open `Control Panel` > `Group` > `Create` and Group Creation Wizard will open.

#### 3.3.3.1. Group information
* Name: `privatelab`
* Description: `Private group`

#### 3.3.3.2. Assign shared folders permissions

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

#### 3.3.3.3. User quota setting
Up to the you.

## 3.4. Create new Synology Users
Here we create the following new Synology users:
*  **media** - username `media` is the user for PVE CT's and VM's used to run media applications (i.e jellyfin, sonarr, radarr, lidarr etc);
*  **home** - username `home` is the user for PVE CT's and VM's used to run homelab applications (i.e syncthing, unifi, nextcloud, home assistant/smart home etc);
*  **private** - username `private` is the user for PVE CT's and VM's used to run privatelab applications (i.e mailserver, messaging etc);

### 3.4.1. Create user "media"
Open `Control Panel` > `Userp` > `Create` and User Creation Wizard will open.

#### 3.4.1.1. User information
* Name: `media`
* Description: `Medialab user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is allways valid ☑

#### 3.4.1.2. Join groups
* medialab ☑
* homelab 
* privatelab
* users ☑

#### 3.4.1.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 3.4.1.4. User quota setting
Leave as default.

#### 3.4.1.5. Assign application permissions
Leave as default.

#### 3.4.1.6. User Speed Limit Setting
Leave as default.

### 3.4.2. Create user "home"
Open `Control Panel` > `Userp` > `Create` and User Creation Wizard will open.

#### 3.4.2.1. User information
* Name: `home`
* Description: `Homelab user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is allways valid ☑

#### 3.4.2.2. Join groups
* medialab ☑
* homelab ☑
* privatelab
* users ☑

#### 3.4.2.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 3.4.2.4. User quota setting
Leave as default.

#### 3.4.2.5. Assign application permissions
Leave as default.

#### 3.4.2.6. User Speed Limit Setting
Leave as default.

### 3.4.3. Create user "private"
Open `Control Panel` > `User` > `Create` and User Creation Wizard will open.

#### 3.4.3.1. User information
* Name: `private`
* Description: `Private user`
* Email: `Leave blank` (or insert your admin email)
* Password: `insert`
* Confirm password: `insert`
* Send notification mail to the newly created user ☐ 
* Display user password in notification mail ☐ 
* Disallow the user to change account password ☑
* Password is allways valid ☑

#### 3.4.3.2. Join groups
* medialab ☑
* homelab ☑
* privatelab ☑
* users ☑

#### 3.4.3.3. Assign shared folders permissions
Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.

#### 3.4.3.4. User quota setting
Leave as default.

#### 3.4.3.5. Assign application permissions
Leave as default.

#### 3.4.3.6. User Speed Limit Setting
Leave as default.

  
## 3.5. Create NFS Permissions
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

## 3.6. Edit Synology NAS GUID and UID
Synology DSM WebGUI Control Panel interface does'nt allow assigning a GUID or UID number when creating any new Linux Groups and Users. Each new group is assigned a random UID upwards of 65536.

We need to edit our newly created GUIDs and UIDs user GID's for Groups medialab, homelab and privatelab and the Users media, home and private.

### 3.6.1. Prepare your Synology
To edit Synology User GUIDs and UIDs you must SSH connect to your Synology (cannot be done via WebGUI).

Prerequisites to complete these tasks are:
*  You must have a nano editor installed on your Synology. To install a nano editor see instructions [here](#51-install-nano).
*  Synology SSH is enabled: Open `Control Panel` > `Terminal & SNMP` > `Enable SSH service` state is on.

### 3.6.2. Edit Synology NAS GUID (Groups)
We need to define each GUID to a known number.

| Synology Group | Old GUID | | New GUID |
| :---  | ---: | :---: | :--- |
| **medialab** | 10XX | ==>> | 65605
| **homelab** | 10XX | ==>> | 65606
| **privatelab** | 10XX | ==>> | 65607

Using a CLI terminal connect to your Synology:
```
# Replace IP with yours
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@nas-01:~$` (replacing `nas-01` with your hostname) if successful.

Synology DSM is Linux so we need switch user `root`. In the CLI terminal type the following to switch to `root@nas-01:~#` :
```
sudo -i
```
And next type the following to change all the GUID's:
```
# Edit Medialab GID ID
sed -i 's|medialab:x:*:.*|medialab:x:65605:media,home,private|g' /etc/group &&
# Edit Homelab GID ID
sed -i 's|homelab:x:*:.*|homelab:x:65606:home,private|g' /etc/group &&
# Edit Privatelab GID ID
sed -i 's|privatelab:x:*:.*|privatelab:x:65607:private|g' /etc/group &&

# Rebuild the Users
synouser --rebuild all
```

### 3.6.3. Edit Synology NAS UID (Users)
Synology DSM WebGUI Control Panel interface does'nt allow assigning a UID number when creating any new User. Each new User is assigned a random UID upwards of 1027.

We need to edit the user UID's for users media, home and private so they are known. This must be done after you have completed GUID modifications.

| Synology Username | Old UID | | New UID |
| :---  | ---: | :---: | :--- |
| **media** | 10XX | ==>> | 1605
| **home** | 10XX | ==>> | 1606
| **private** | 10XX | ==>> | 1607

Using a CLI terminal connect to your Synology:
```
# Replace IP with yours
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@nas-01:~$` (replacing `nas-01` with your hostname) if successful.

Synology DSM is Linux so we need switch user `root`. In the CLI terminal type the following to switch to `root@nas-01:~#` :
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

<hr>

# 4. Synology Virtual Machine Manager
If your Synology NAS model is capable you can install a PVE node on your Synology DiskStation using the native Synology Virtual Machine Manager application.

I recommend your Synology Diskstation has a Intel CPU type of a Atom, Pentium, Celeron or Xeon of at least 2 Cores (really a Quad Core is recommended) and 16Gb of Ram (minimum 8Gb).

## 4.1. Download the Proxmox installer ISO
Download the latest Proxmox ISO installer to your PC from  www.proxmox.com or [HERE](https://www.proxmox.com/en/downloads/category/iso-images-pve).

## 4.2. Install Synology Virtual Machine Manager on your NAS
A prerequisite to running any VMs on your Synology NAS is you require a BTRFS file system. If they are not then you CANNOT install VM's.

In my experience the best way to create a BTRFS is to back up your data to a external disk (USB) or another internal volume (be careful and know what you are doing). Then delete and recreate `/volume1` via DSM and restore your backup data. I recommend using Synology Hyper Backup to backup your data and settings.

Its a lengthy topic and the procedures can be found by seaching on the internet.

To install Synology Virtual Machine Manager login to the Synology WebGUI interface and open `Synology Package Centre` and install `Virtual Machine Manager`

## 4.3. Configure Synology Virtual Machine Manager
Using the Synology WebGUI interface `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Storage` > `Add` and follow the prompts and configure as follows:

| Tab Title | Value |
| :---  | :---: |
| Create a Storage Resource | `NEXT` |
| Create Storage | Select/Highlight `nas-01/Volume 1` and Click `NEXT` |
| **Configure General Specifications** 
| Name | `nas-01 - VM Storage 1` |
| Full | Leave Default |
| Low on Space | `10%` |
| Notify me each time the free space ... | `☑` |

And hit `Apply`.

## 4.4. Create a Proxmox VM
Just like a hardmetal installation Proxmox VM requires a harddisk. Except in this case its a virtual disk.

### 4.4.1. Add the Proxmox VE ISO image to your Synology
Using the Synology WebGUI interface click on Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Image` > `ISO File` > `Add` > `From Computer` and browse to your downloaded Proxmox ISO (i.e proxmox-ve_6.3.iso ) > `Select Storage` > `Choose your host (i.e nas-01)`

### 4.4.2. Create the Proxmox VM machine
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

### 4.4.3. Install Proxmox OS
Now your are going to install Proxmox OS using the installation ISO media. 

#### 4.4.3.1. Power-on PVE-0X VM
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Power On` and wait for the `status` to show `running`.

This is like hitting the power-on button on any hardmetal machine --- but a virtual boot.

#### 4.4.3.2. Run the Proxmox ISO Installation
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Connect` and a new browser tab should open showing the Proxmox installation script. The installation is much the same as a hardmetal installation you would've performed for pve-01 or pve-02.

To start the install, on the new browser tab, use your keyboard arrow keys with `Install Proxmox VE` selected hit your `ENTER` key to begin the installation script.

Your first user prompt will probably be a window saying "No support for KVM virtualisation detected. Check BIOS settings for Intel VT/AMD-V/SVM" so click `OK` then to the End User Agreement click `I Agree`.

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

Finally click `Reboot` and your VM Proxmox node will reboot.

## 4.5. Configure the Proxmox VM
Configuration is now done via the Proxmox web interface. Just point your browser to the IP address given during installation (https://192.168.1.10X:8006) and ignore the security warning by clicking `Advanced` then `Accept the Risk and Continue` -- this is the warning I get in Firefox. Default login is "root" (realm PAM) and the root password you defined during the installation process.

### 4.5.1. Update Proxmox OS VM and enable turnkeylinux templates
Using the web interface `updates` > `refresh` search for all the latest required updates. You will get a few errors which ignore.
Next install the updates using the web interface `updates` > `_upgrade` - a pop up terminal will show the installation steps of all your required updates and it will prompt you to type `Y` so do so.

Next install turnkeylinux container templates by using the web interface CLI `shell` and type
`pveam update`

Finished. Your Synology DiskStation Proxmox VM node is ready.

<hr>

# 5. Patches and Fixes

## 5.1. Install Nano
Install Nano as a SynoCommunity package.

Log in to the Synology Desktop and go to `Package Center` > `Settings` > `Package Sources` > `Add` and complete the fields as follows:

| Option   | Value                                |
|----------|--------------------------------------|
| Name     | `SynoCommunity`                      |
| Location | `http://packages.synocommunity.com/` |

And click `OK`. Then type in the serach bar 'nano' and install Nano.
