# Synobuild
The following is for a Synology Diskstation only. Modify accordingly for your own NAS or NFS server setup.
Network Prerequisites are:
- [x] Layer 2 Network Switches
- [x] Network Gateway is `192.168.1.5`
- [x] Network DNS server is `192.168.1.5` (Note: set DNS server: primary DNS `192.168.1.254` which is your static PiHole server IP address ; secondary DNS `1.1.1.1`)
- [x] Network DHCP server is `192.168.1.5`
- [x] A DDNS service is fully configured and enabled (I recommend you use the free Synology DDNS service)

Synology Prerequisites are:
- [x] Synology CPU is Intel based
- [x] Volume is formated to BTRFS (not ext4, which cannot run Synology Virtual Machines)
- [x] Synology Static IP Address is `192.168.1.10`
- [x] Synology Hostname is `cyclone-01`
- [x] Synology Gateway is `192.168.1.5`
- [x] Synology DNS Server is `192.168.1.5`
- [x] Synology DDNS is working with your chosen hostname ID at `hostnameID.synology.me`

>  **Note: A prerequisite to running VMs on your Synology NAS is your volumes must use the BTRFS file system - without BTRFS you CANNOT install VM's. In my experience the best way forward is based upon backing up your data to a external disk (USB) or another internal volume (be careful and know what you are doing), deleting and recreating /volume1 via DSM and restoring your backup data. I recommend using Synology Hyper Backup for backuping your data and settings.**

>  **Its a lengthy topic and the procedures can be found by seaching on the internet. The following tutorials assumes your Volume 1 is in the BTRFS file system format.**

Tasks to be performed are:
- [ ] 1.0 Create the required Synology Shared Folders and NFS Shares
- [ ] 2.0 Create new Synology User groups
- [ ] 3.0 Create a new Synology Users
- [ ] 4.0 Install & Configure Synology Virtual Machine Manager
- [ ] 5.0 Create the Proxmox VM
- [ ] 6.0 Install Proxmox OS
- [ ] 7.0 Configure the Proxmox VM
- [ ] 8.0 Easy Proxmox Installation Option

## 1.0 Create the required Synology Shared Folders and NFS Shares
The following are the minimum set of folder shares required for my configuration and needed for this build and for the scripts to work.

### 1.1 Create Shared Folders
We need the following shared folder tree, in addition to your standard default tree, on the Synology NAS:
```
Synology NAS/
│
└──  volume1/
    ├── audio
    ├── backup
    ├── books
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
     * audio `☑`
     * backup `☑`
     * books `☑`
     * docker `☑`
     * music `☑`
     * openvpn `☑`
     * photo `☑`
     * public `☑`
     * pxe `☑`
     * ssh_key `☑`
     * video `☐` 
     * virtualbox `☑`
     * proxmox `☑`
3. Set up Encryption:
     * Encrypt this shared folder: `☐` 
4. Set up advanced:
   * All disabled:  `☐` 
5. Set up Permissions:
     * Note, at this point do not flag anything, just hit `Cancel` to exit.
     
### 1.2 Create NFS Shares
Create NFS shares for the following folders:

| Folder Name | NFS Share |
| :---  | :---: |
| audio | `☑` |
| books | `☑` |
| docker | `☑` |
| music | `☑` |
| photo | `☑` |
| public | `☑` |
| proxmox  | `☑` |
| video  | `☑` |

To create NFS shares log in to the Synology Desktop and:
1. Log in to the Synology Desktop and go to `Control Panel` > `Shared Folder` > `Select a Folder` > `Edit` > `NFS Permissions` > `Create `
2. Set NFS rule options as follows:
   * Hostname or IP*: `"192.168.1.0/24"`
   * Privilege: `Read/Write`
   * Squash: `Map all users to admin`
   * Security: `auth_sys`
     * Enable asynchronous:  `☑`
     * Allow connections from non-privileged ports:  `☑`
     * Allow users to access mounted subfolders: `☑`
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
| audio | ☐ | `☑` |  ☐
| backup  | `☑` |  ☐ |  ☐
| books | ☐ | `☑` |  ☐
| docker | ☐ | `☑` |  ☐
| music | ☐ | `☑` |  ☐
| openvpn | `☑` |  ☐ |  ☐
| photo | ☐ | `☑` |  ☐
| public | ☐ | `☑` |  ☐
| proxmox | ☐ | `☑` |  ☐
| pxe | ☐ | `☑` |  ☐
| ssh_key | `☑` |  ☐ |  ☐
| video | ☐ | `☑` |  ☐
| virtualbox | ☐ | `☑` |  ☐
4. Set User quota setting:
   * Enable quota:  ☐
5. Assign application permissions:

| Name | Allow | Deny |
| :---  | :---: | :---: |
| DSM | ☐ | `☑` |  
| Drive | ☐ | `☑` | 
| File Station | `☑` | ☐  | 
| FTP | ☐ |` ☑` |  
| Moments | ☐ | `☑` | 
| Text Editor | ☐ | `☑` | 
| Universal Search | ☐ | `☑` | 
| Virtual Machine Manage | `☑` | ☐  | 
| rsync | ☐ | `☑` |  
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
| audio | ☐ | `☑` |  ☐
| backup | ☐ | `☑` |  ☐
| books | ☐ | `☑` |  ☐
| docker | ☐ | `☑` |  ☐
| music | ☐ | `☑` |  ☐
| openvpn | ☐ | `☑` |  ☐
| photo | ☐ | `☑` |  ☐
| public | ☐ | `☑` |  ☐
| proxmox | ☐ | `☑` |  ☐
| pxe | ☐ | `☑` |  ☐
| ssh_key | ☐ | `☑` |  ☐
| video | ☐ | `☑` |  ☐
| virtualbox | ☐ | `☑` |  ☐
4. Set User quota setting:
   * Enable quota:  ☐
5. Assign application permissions:

| Name | Allow | Deny |
| :---  | :---: | :---: |
| DSM | `☑` | ☐  | 
| Drive | `☑` | ☐  | 
| File Station | `☑` | ☐  | 
| FTP | `☑` | ☐  | 
| Moments | `☑` | ☐  | 
| Text Editor | `☑` | ☐  | 
| Universal Search | `☑` | ☐  | 
| Virtual Machine Manager | `☑` | ☐  | 
| rsync | `☑` | ☐  | 
6. Group Speed Limit Setting
    * `default`

## 3.0 Create a new Synology Users
Here you create a user named `storm` which will be used for Proxmox and Virtual Machines your my cluster.

### 3.1 Create user "storm":
To create a new user log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `storm`
   * Description: `Homelab user`
   * Email: `Leave blank`
   * Password: `As Supplied`
   * Conform password: `As Supplied`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  `☑`
3. Set Join groups as follows:
     * homelab:  `☑`
     * users:  `☑`
4. Assign shared folders permissions as follows:
Leave as default as permissions are automatically obtained from the chosen user 'group' permissions.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| audio | ☐ | `☑` |  ☐
| backup  | `☑` |  ☐ |  ☐
| books | ☐ | `☑` |  ☐
| docker | ☐ | `☑` |  ☐
| music | ☐ | `☑` |  ☐
| openvpn | `☑` |  ☐ |  ☐
| photo | ☐ | `☑` |  ☐
| public | ☐ | `☑` |  ☐
| proxmox | ☐ | `☑` |  ☐
| pxe | ☐ | `☑` |  ☐
| ssh_key | `☑` |  ☐ |  ☐
| video | ☐ | `☑` |  ☐
| virtualbox | ☐ | `☑` |  ☐
5. Set User quota setting:
     * `default`
6. Assign application permissions:
Leave as default as application permissions are automatically obtained from the chosen user 'group' permissions.

| Name | Allow | Deny |
| :---  | :---: | :---: |
| DSM | `☑` | ☐  | 
| Drive | `☑`| ☐  | 
| File Station | `☑` | ☐  | 
| FTP | `☑` | ☐  | 
| Moments | `☑` | ☐  | 
| Text Editor | `☑` | ☐  | 
| Universal Search | `☑` | ☐  | 
| Virtual Machine Manager | `☑` | ☐  | 
| rsync | `☑` | ☐  | 
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

To install Synology Virtual Machine Manager login to the Synology WebGUI interface and open `Synology Package Centre` and install `Virtual Machine Manager`

### 4.3 Configure Synology Virtual Machine Manager
Using the Synology WebGUI interface `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Storage` > `Add` and follow the prompts and configure as follows:

| Tab Title | Value |--|Options or Notes|
| :---  | :---: | --| :---  |
| Create a Storage Resource | `NEXT` |
| Create Storage | Select/Highlight `cyclone-01/Volume 1` and Click `NEXT` |
| **Configure General Specifications** 
| Name | `cyclone-01 - VM Storage 1` |
| Full | Leave Default |
| Low on Space | `10%` |
| Notify me each time the free space ... | `☑` |--| *Check*

And hit `Apply`.

## 5.0 Create the Proxmox VM
Just like a hardmetal installation each Synology VM installation of Proxmox requires two hard disks. Basically one is for the Proxmox OS and the other disk is configured as a Proxmox ZFS shared storage disk.

Each Proxmox VM node requires a OS SSD disk, disk 1, which I size at 120 Gb SSD disk.

For Disk 2 (sdx) I recommend a 250 Gb SSD which will be used as a Proxmox ZFS shared storage disk for the cluster.

### 5.1 Add the Proxmox VE ISO image to your Synology
Using the Synology WebGUI interface click on Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Image` > `ISO File` > `Add` > `From Computer` and browse to your downloaded Proxmox ISO (i.e proxmox-ve_5.4-1.iso ) > `Select Storage` > `Choose your host (i.e cyclone-01)`

### 5.2 Create a Proxmox VM 
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Create` > `Choose OS` > `Linux` > `Select Storage` > `cyclone-01` > and assign the following values:

| (1) Tab General | Value |--|Options or Notes|
| :---  | :---: | --| :---  |
| Name | `typhoon-03` |
| CPU's | `1` |
| Memory | `7` | 
| Video Card | `vmvga` |
| Description | (optional) |
| | |
| **(2) Tab Storage** | **Value** |--|**Options or Notes**|
| Virtual Disk 1 | `120 Gb` |--|Settings Options: VirtIO SCSI Controller with Space Reclamation enabled|
| Virtual Disk 1 | `250 Gb` |--|Settings Options: VirtIO SCSI Controller with Space Reclamation enabled|
| | |
| **(3) Tab Network** | **Value** |--|**Options or Notes**|
| Network 1 | Default VM Network |
| | |
| **(4) Tab Others** | **Value** |--|**Options or Notes**|
| ISO file for bootup |i.e proxmox-ve_5.4  |--|*Note: select the proxmox ISO uploaded in Step 2*|
| Additional ISO file | Unmounted |--|*Note: nothing to to select here*|
| Autostart | `Last State` |
| Boot from | `Virtual Disk` |
| BIOS | `Legacy BIOS (Recommended)` |
| Keyboard Layout | `Default (en-us)` |
| Virtual USB Controller | `Disabled` |
| USB Device | `Unmounted` |
| | |
| **(5) Tab Permissions** | **Value** |--|**Options or Notes**|
| administrators | `☑` |--|*Note: select from 'Local groups'*|
| homelab | `☑` | --|*Note: select from 'Local groups'*|
| http | ☐ | 
| users | ☐ | 
| | |
| **(6) Summary** | **Value** |--|**Options or Notes**|
| Storage | `cyclone-01 - VM Storage 1` |
| Name | `cyclone-01 - VM Storage 1` | 
| CPU(s) | `cyclone-01 - VM Storage 1` | 
| Memory | `cyclone-01 - VM Storage 1` | 
| Video Card | `cyclone-01 - VM Storage 1` | 
| Description | `cyclone-01 - VM Storage 1` | 
| Virtual Disk 1 | `cyclone-01 - VM Storage 1` | 
| Virtual Disk 2 | `cyclone-01 - VM Storage 1` | 
| Power on the virtual machine after creation | `☐` | -- | *Note: Uncheck*

And hit `Apply`.

## 6.0 Install Proxmox OS
Now your are going to install Proxmox OS using the installation ISO media. 

### 6.1 Power-on Typhoon-03 VM
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Power On` and wait for the `status` to show `running`.

This is like hitting the power-on button on any hardmetal machine --- but a virtual boot.

### 6.2 Run the Proxmox ISO Installation
Using the Synology WebGUI interface Open Synology `Main Menu` (top left box icon) > `Virtual Machine Manager` > `Virtual Machine` > `Connect` and a new browser tab should open showing the Proxmox installation script. The installation is much the same as a hardmetal installation you would've performed for typhoon-01 or typhoon-02.

To start the install, on the new browser tab, use your keyboard arrow keys with `Install Proxmox VE` selected hit your `ENTER` key to begin the installation script.

Your first user prompt will probably be a window saying "No support for KVM virtualisation detected. Check BIOS settings for Intel VT/AMD-V/SVM" so click `OK` then to the End User Agreement click `I Agree`.

Now configure the installation fields for the node as follows:
   
| Option | Typhoon-03 Value | Options or Notes |
| :---  | :---: | :--- |
| Hardware Type | Synology VM |
| Target Disk | `/dev/sda (120GB, iSCSI Storage)` |*Not the 250GB Disk*
| Target Disk - Option | `ext4` | *Leave Default - ext4 etc*
| Country | Type your Country
| Timezone | Select |
| Keymap |`en-us`|
| Password| Enter your new password | *Same password as you used on your other nodes*
| E-mail |Enter your email | *If you dont want to enter a valid email type mail@example.com*
| Management interface |Leave Default
| Hostname |`typhoon-03.localdomain` |
| IP Address |`192.168.1.103`|
| Netmask |`255.255.255.0`|
| Gateway |`192.168.1.5`|
| DNS Server |`192.168.1.5`|

Finally click `Reboot` and your VM Proxmox node will reboot.

## 7.0  Configure the Proxmox VM
Further configuration is done via the Proxmox web interface. Just point your browser to the IP address given during installation (https://192.168.1.103:8006) and ignore the security warning by clicking `Advanced` then `Accept the Risk and Continue` -- this is the warning I get in Firefox. Default login is "root" (realm PAM) and the root password you defined during the installation process.

### 7.1 Update Proxmox OS VM and enable turnkeylinux templates
Using the web interface `updates` > `refresh` search for all the latest required updates. You will get a few errors which ignore.
Next install the updates using the web interface `updates` > `_upgrade` - a pop up terminal will show the installation steps of all your required updates and it will prompt you to type `Y` so do so.

Next install turnkeylinux container templates by using the web interface CLI `shell` and type
`pveam update`

### 7.2 Create Disk Two - your shared storage
Create Disk 2 using the web interface `Disks` > `ZFS` > `Create: ZFS` and configure each node as follows:

| Option | Node 1 Value | Node 2 Value | Node 3 Value |
| :---  | :---: | :---: | :---: |
| Name |`typhoon-share`|`typhoon-share`|`typhoon-share`
| RAID Level |`Single Disk`|`Single Disk`|`Single Disk`
| Compression |`on`|`on`|`on`
| ashift |`12`|`12`|`12`
| Device |`/dev/sdx`|`/dev/sdx`|`/dev/sdx`

Note: If your choose to use a ZFS Raid for storage redundancy change accordingly per node but your must retain the Name ID **typhoon-share**.

## 8.0 Easy Proxmox Installation Option
If you have gotten this far and completed Steps 4.0 through to 7.2 you can proceed to manually build your Proxmox nodes or simply use a CLI build bash script(s).

So you have two choices to finish configuring your `typhoon-03` Proxmox node:
*  Use a premade script, Script (C) `typhoon-0X-VM-setup-01.sh`, with instructions shown [HERE](https://github.com/ahuacate/proxmox-node#30-easy-installation-option). Or,
*  Finish the build manually by following the instructions shown [HERE](https://github.com/ahuacate/proxmox-node#41--create-nfs-mounts-to-nas)

Its much easier to use the CLI bash script available on Github. To execute the script use the Proxmox web interface `typhoon-02/03/04` > `>_ Shell` and cut & paste the following into the CLI terminal window and press ENTER:
```
wget https://raw.githubusercontent.com/ahuacate/proxmox-node/master/scripts/typhoon-0X-VM-setup-01.sh -P /tmp && chmod +x /tmp/typhoon-0X-VM-setup-01.sh && bash /tmp/typhoon-0X-VM-setup-01.sh; rm -rf /tmp/typhoon-0X-VM-setup-01.sh.sh
```

Finished. Your Synology Proxmox VM node is ready.
