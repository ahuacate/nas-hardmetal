# Synobuild
The following is for a Synology Diskstation only. Modify accordingly for your own NAS or NFS server setup.
Network Prerequisites are:
- [x] Network Gateway is `192.168.1.5`
- [x] Network DNS server is `192.168.1.5` (Note: set DNS server: primary DNS `192.168.1.254` which is your static PiHole server IP address ; secondary DNS `1.1.1.1`)
- [x] Network DHCP server is `192.168.1.5`

Synology Prerequisites are:
- [x] Synology CPU is Intel based
- [x] Volume is formated to BTRFS (not ext4, which cannot run Synology Virtual Machines)
- [x] Synology Static IP Address is `192.168.1.10`
- [x] Synology Hostname is `cyclone-01`
- [x] Synology Gateway is `192.168.1.5`
- [x] Synology DNS Server is `192.168.1.5`
- [x] Synology DDNS is working with your chosen hostname ID at `hostnameID.synology.me`
**Note: A prerequisite to running VMs on your Synology NAS is your volumes are in the BTRFS file system. If they are not then you CANNOT install VM's. In my experience the best way forward is base upon backing up data on an external disk (USB) or another internal volume (be careful and know what you are doing), deleting and recreating /volume1 via DSM and restoring your backup data. I recommend using Synology Hyper Backup to backup your data and settings.**

**Its a lengthy topic and the procedures can be found by seaching on the internet. So the following assumes your Volume 1 was created with the BTRFS file system.**

Tasks to be performed are:
- [ ] Create the required Synology shared folders and NFS shares
- [ ] Install the following Synology applications:
  * `Drive` - a Synology remote access tool
  * `Moments` - Synology photo manager
  * `Virtual Machine Manager` - a Synology virtualisation tool
  * `VPN Server` - Synology VPN access server
- [ ] Create a new user groups:
  * `homelab` user group
  * `privatelab` user group
- [ ] Create a new Synology user;
  * user named: `storm`
- [ ] Configure Synology NAS SSH Key-based authentication for the above users.
- [ ] Install & Configure Synology Virtual Machine Manager

## 1.0 Create the required Synology Shared Folders and NFS Shares
The following are the minimum set of folder shares required for my configuration and needed for this build and for the scripts to work.

### 1.1 Create Shared Folders
We need the following shared folder tree, in addition to your standard default tree, on the Synology NAS:
```
Synology NAS/
│
└──  volume1/
    ├── backup
    ├── docker
    ├── music 
    ├── openvpn
    ├── photo 
    ├── public
    ├── pxe
    ├── ssh_key
    ├── video
    ├── virtualbox
    └── proxmox
```
To create shared folders log in to the Synology Desktop and:
1. Open `Control Panel` > `Shared Folder` > `Create`.
2. Set up basic information:
   * Name: `"i.e backup"`
   * Description: `"leave blank if you want"`
   * Location: `Volume 1`
   * Hide this shared ...: ☐ 
   * Hide sub-folders ...: ☐ 
   * Enable Recycle Bin:
     * backup ☑
     * docker ☑
     * music ☑
     * openvpn ☑
     * photo ☑
     * public ☑
     * pxe ☑
     * ssh_key ☑
     * video ☐ 
     * virtualbox ☑
     * proxmox ☑
3. Set up Encryption:
     * Encrypt this shared folder: ☐ 
4. Set up advanced:
   * All disabled:  ☐ 
5. Set up Permissions:
     * Note, at this point do not flag anything, just hit `Cancel` to exit.
     
### 1.2 Create NFS Shares
Create NFS shares for the following folders:

| Folder Name | NFS Share |
| :---  | :---: |
| `docker` | ☑ |
| `music` | ☑ |
| `photo` | ☑ |
| `public` | ☑ |
| `proxmox`  | ☑ |
| `video`  | ☑ |

To create NFS shares log in to the Synology Desktop and:
1. Log in to the Synology Desktop and go to `Control Panel` > `Shared Folder` > `Select a Folder` > `Edit` > `NFS Permissions` > `Create `
2. Set NFS rule options as follows:
   * Hostname or IP*: `"192.168.1.0/24"`
   * Privilege: `Read/Write`
   * Squash: `Map all users to admin`
   * Security: `auth_sys`
     * Enable asynchronous:  ☑
     * Allow connections from non-privileged ports:  ☑
     * Allow users to access mounted subfolders:  ☑
3. Repeat steps 1 to 2 for all of the above six folders.

## 2.0 Create new Synology User groups
For ease of management I have created a specific user and group explicitly for Proxmox and Virtual Machines in my cluster. 

### 2.1 Create "homelab" user group
This is a user group for your smart home and home media management software. This user group and users are not for personal or private data.

To create a new group log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information fields as follows:
   * Name: `"homelab"`
   * Description: `"Homelab group"`
3. Assign shared folders permissions as follows:
Note: Any oersonal or private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup`  | ☑ |  ☐ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `music` | ☐ | ☑ |  ☐
| `openvpn` | ☑ |  ☐ |  ☐
| `photo` | ☐ | ☑ |  ☐
| `public` | ☐ | ☑ |  ☐
| `proxmox` | ☐ | ☑ |  ☐
| `pxe` | ☐ | ☑ |  ☐
| `ssh_key` | ☑ |  ☐ |  ☐
| `video` | ☐ | ☑ |  ☐
| `virtualbox` | ☐ | ☑ |  ☐
4. Set User quota setting:
   * Enable quota:  ☐
5. Assign application permissions:

| Name | Allow | Deny |
| :---  | :---: | :---: |
| `DSM` | ☐ | ☑ |  
| `Drive` | ☐ | ☑ | 
| `File Station` | ☑ | ☐  | 
| `FTP` | ☐ | ☑ |  
| `Moments` | ☐ | ☑ | 
| `Text Editor` | ☐ | ☑ | 
| `Universal Search` | ☐ | ☑ | 
| `Virtual Machine Manager` | ☑ | ☐  | 
| `rsync` | ☐ | ☑ |  
6. Group Speed Limit Setting
    * `default`

### 2.2 Create "privatelab" user group
This is a user group for your private and personal data.

To create a new group log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information as follows:
   * Name: `"privatelab"`
   * Description: `"Privatelab group"`
3. Assign shared folders permissions as follows:
Note: Any oersonal or private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup` | ☐ | ☑ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `music` | ☐ | ☑ |  ☐
| `openvpn` | ☐ | ☑ |  ☐
| `photo` | ☐ | ☑ |  ☐
| `public` | ☐ | ☑ |  ☐
| `proxmox` | ☐ | ☑ |  ☐
| `pxe` | ☐ | ☑ |  ☐
| `ssh_key` | ☐ | ☑ |  ☐
| `video` | ☐ | ☑ |  ☐
| `virtualbox` | ☐ | ☑ |  ☐
4. Set User quota setting:
   * Enable quota:  ☐
5. Assign application permissions:

| Name | Allow | Deny |
| :---  | :---: | :---: |
| `DSM` | ☑ | ☐  | 
| `Drive` | ☑ | ☐  | 
| `File Station` | ☑ | ☐  | 
| `FTP` | ☑ | ☐  | 
| `Moments` | ☑ | ☐  | 
| `Text Editor` | ☑ | ☐  | 
| `Universal Search` | ☑ | ☐  | 
| `Virtual Machine Manager` | ☑ | ☐  | 
| `rsync` | ☑ | ☐  | 
6. Group Speed Limit Setting
    * `default`

## 3.0 Create a new Synology Users
Here you create a user named `storm` which will be used for Proxmox and Virtual Machines your my cluster.

### 3.1 Create user "storm":
To create a new user log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `"storm"`
   * Description: `"Homelab user"`
   * Email: `Leave blank`
   * Password: `"As Supplied"`
   * Conform password: `"As Supplied"`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  ☑
3. Set Join groups as follows:
     * homelab:  ☑
     * users:  ☑
4. Assign shared folders permissions as follows:
Leave as default as permissions are automatically obtained from the chosen user 'group' permissions.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup`  | ☑ |  ☐ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `music` | ☐ | ☑ |  ☐
| `openvpn` | ☑ |  ☐ |  ☐
| `photo` | ☐ | ☑ |  ☐
| `public` | ☐ | ☑ |  ☐
| `proxmox` | ☐ | ☑ |  ☐
| `pxe` | ☐ | ☑ |  ☐
| `ssh_key` | ☑ |  ☐ |  ☐
| `video` | ☐ | ☑ |  ☐
| `virtualbox` | ☐ | ☑ |  ☐
5. Set User quota setting:
     * `default`
6. Assign application permissions:
Leave as default as application permissions are automatically obtained from the chosen user 'group' permissions.

| Name | Allow | Deny |
| :---  | :---: | :---: |
| `DSM` | ☑ | ☐  | 
| `Drive` | ☑ | ☐  | 
| `File Station` | ☑ | ☐  | 
| `FTP` | ☑ | ☐  | 
| `Moments` | ☑ | ☐  | 
| `Text Editor` | ☑ | ☐  | 
| `Universal Search` | ☑ | ☐  | 
| `Virtual Machine Manager` | ☑ | ☐  | 
| `rsync` | ☑ | ☐  | 
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`

## 4.0 Install & Configure Synology Virtual Machine Manager
If your Synology NAS model is capable you can install a Proxmox node on your Synology Diskstation using the native Synology Virtual Machine Manager application.

I recommend your Synology Diskstation has a Intel CPU type of a Atom, Pentium, Celeron or Xeon of at least 2 Cores (really a Quad Core is recommended) and 16Gb of Ram (minimum 8Gb). 

### 4.1 Download the Proxmox installer ISO
Download the latest Proxmox ISO installer to your PC from  www.proxmox.com or [HERE](https://www.proxmox.com/en/downloads/category/iso-images-pve).

### 4.2 Install Synology Virtual Machine Manager on your NAS
A prerequisite to running VMs on your Synology NAS is your volumes are in the BTRFS file system. If they are not then you CANNOT install VM's. In my experience the best way forward is base upon backing up data on an external disk (USB) or another internal volume (be careful and know what you are doing), deleting and recreating /volume1 via DSM and restoring backup data. I recommend using Synology Hyper Backup to backup your data and settings.

Its a lengthy topic and the procedures can be found by seaching on the internet. So the following assumes your Volume 1 was created with the BTRFS file system.

To install Synology Virtual Machine Manager login to the Synology WebGUI interface and:
1. Open `Synology Package Centre` and install `Virtual Machine Manager`

### 4.3 Configure Synology Virtual Machine Manager
Using the Synology WebGUI interface:
1. Click on Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Image` > `ISO File` > `Add` > `From Computer` and browse to your downloaded Proxmox ISO (i.e proxmox-ve_5.4-1.iso ) > `Select Storage` > `Choose your host (i.e cyclone-01)`
3. Open Synology `Virtual Machine Manager` > `Virtual Machine` > `Create` > `Choose OS` > `Linux` > `Select Storage` > `cyclone-01` > and assign the following values

| (1) Tab General | Value |--|Options or Notes|
| :---  | :---: | --| :---  |
| `Name` | typhoon-03 |
| `CPU's` | 1 |
| `Memory` | 7 | 
| `Video Card` | vmvga |
| `Description` | (optional) |
| | |
| **(2) Tab Storage** | **Value** |--|**Options or Notes**|
| `Virtual Disk 1` | 120 Gb |--|Options: VirtIO SCSI Controller with Space Reclamation enabled|
| `Virtual Disk 1` | 250 Gb |--|Options: VirtIO SCSI Controller with Space Reclamation enabled|
| | |
| **(3) Tab Network** | **Value** |--|**Options or Notes**|
| `Network 1` | Default VM Network |
| | |
| **(4) Tab Others** | **Value** |--|**Options or Notes**|
| `ISO file for bootup` |i.e proxmox-ve_5.4  |--|Note: select the proxmox ISO uploaded in Step 2|
| `Additional ISO file` | Unmounted |--|Note: nothing to to select here|
| `Autostart` | Last State |
| `Boot from` | Virtual Disk |
| `BIOS` | Legacy BIOS (Recommended) |
| `Keyboard Layout` | Default (en-us) |
| `Virtual USB Controller` | Disabled |
| `USB Device` | Unmounted |
| | |
| **(5) Tab Permissions** | **Value** |--|**Options or Notes**|
| `administrators` | ☑ |--|Note: select from 'Local groups'|
| `homelab` | ☑ | --|Note: select from 'Local groups'|
| `http` | ☐ | 
| `users` | ☐ | 

4. Final step is to install Proxmox:
   * Open Synology `Virtual Machine Manager` > `Virtual Machine` > `Power On` and wait for the `status` to show `running`.
   * Open Synology `Virtual Machine Manager` > `Virtual Machine` > `Connect` and a new browser tab should open showing the Proxmox installation script. Now follow our Github instructions for installing Proxmox using node ID `typhoon-03` from [HERE](https://github.com/ahuacate/proxmox-node).
