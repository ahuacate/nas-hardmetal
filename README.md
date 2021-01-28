<h2> OEM NAS Setup</h2>

This guide is about setting up your OEM Linux NAS ready for all our Easy Scripts and CT builds. 

A OEM NAS could be a Synology, QNap, FreeNAS, OMV or whatever open source Linux NAS build you use. The Linux basics should be easily interpreted to suit your NAS OS.

More emphasis has been given to the Synology DiskStation only because I had one on my network. Personally I recommend

A 
The following is for a Synology DiskStation only. Modify accordingly for your own NAS or NFS server setup.
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

## 1.00 Create the required Synology Shared Folders and NFS Shares
The following are the minimum set of folder shares required for my configuration and needed for this build and for the scripts to work.

### 1.01 Create Shared Folders
We need the following shared folder tree, in addition to your standard default tree, on the Synology NAS:
```
Synology NAS/
│
└──  volume1/
    ├── audio
    ├── backup
    ├── books
    ├── cloudstorage
    ├── docker
    ├── download
    ├── hass
    ├── music 
    ├── openvpn
    ├── photo
    ├── proxmox
    ├── public
    ├── pxe
    ├── ssh_key
    ├── video
    └── virtualbox
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
     * audio `☐`
     * backup `☑`
     * books `☐`
     * cloudstorage `☑`
     * docker `☑`
     * download `☐`
     * hass `☑`
     * music `☑`
     * openvpn `☑`
     * photo `☑`
     * proxmox `☑`
     * public `☑`
     * pxe `☑`
     * ssh_key `☑`
     * video `☐` 
     * virtualbox `☑`
3. Set up Encryption:
     * Encrypt this shared folder: `☐` 
4. Set up advanced:
   * All disabled:  `☐` 
5. Set up Permissions:
     * Note, at this point do not flag anything, just hit `Cancel` to exit.
     
### 1.02 Create NFS Shares
Create NFS shares for the following folders:

| Folder Name | NFS Share |
| :---  | :---: |
| audio | `☑` |
| books | `☑` |
| cloudstorage | `☑` |
| docker | `☑` |
| download | `☑` |
| hass | `☑` |
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
3. Repeat steps 1 to 2 for all of the above eleven folders.

## 2.00 Create new Synology User groups
For ease of management we create specific users and groups for Proxmox LXC's and VM's. The content and application groups are:

*  **medialab** - Everything to do with TV series and Movies;
*  **homelab** - Everything to do with your smart home;
*  **privatelab** - All your private data.

### 2.01 Create "medialab" user group
This is a user group for home media content and applications only.

To create a new group log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information fields as follows:
   * Name: `"medialab"`
   * Description: `"Medialab group"`
3. Assign shared folders permissions as follows:
Note: Any oersonal or private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| audio | ☐ | `☑` |  ☐
| backup | `☑` |  ☐ |  ☐
| books | ☐ | `☑` |  ☐
| cloudstorage | `☑` |  ☐ |  ☐
| docker | ☐ | `☑` |  ☐
| download | ☐ | `☑` |  ☐
| hass | `☑` | ☐ |  ☐
| music | ☐ | `☑` |  ☐
| openvpn | `☑` |  ☐ |  ☐
| photo | ☐ |  ☐  | `☑`
| public | ☐ | `☑` |  ☐
| proxmox | ☐ | `☑` |  ☐
| pxe | `☑` |  ☐ |  ☐
| ssh_key | `☑` |  ☐ |  ☐
| video | ☐ | `☑` |  ☐
| virtualbox | `☑` |  ☐ |  ☐
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
    
### 2.02 Create "homelab" user group
This is a user group for smart home applications and general non-critical private user data.

To create a new group log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information fields as follows:
   * Name: `"homelab"`
   * Description: `"Homelab group"`
3. Assign shared folders permissions as follows:
Note: Any personal or private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| audio | ☐ | `☑` |  ☐
| backup | ☐ | `☑` |  ☐
| books | ☐ | `☑` |  ☐
| cloudstorage | ☐ | `☑` |  ☐
| docker | ☐ | `☑` |  ☐
| download | ☐ | `☑` |  ☐
| hass | ☐ | `☑` |  ☐
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

### 2.03 Create "privatelab" user group
This is a user group for your private, personal and strictly confidential data.

To create a new group log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information as follows:
   * Name: `"privatelab"`
   * Description: `"Privatelab group"`
3. Assign shared folders permissions as follows:
Note: Any personal or private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| audio | ☐ | `☑` |  ☐
| backup | ☐ | `☑` |  ☐
| cloudstorage | ☐ | `☑` |  ☐
| books | ☐ | `☑` |  ☐
| docker | ☐ | `☑` |  ☐
| download | ☐ | `☑` |  ☐
| hass | ☐ | `☑` |  ☐
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

### 2.04 Edit Synology NAS user GID's
Synology DSM WebGUI Control Panel interface does'nt allow assigning a GID number when creating any new groups. Each new group is assigned a random UID upwards of 65536.

We need to edit the user GID's for groups medialab, homelab and privatelab so they are known GID's. This must be done after you have completed Steps 2.01 --> 2.03.

| Synology Group | Old GID | | New GID |
| :---  | ---: | :---: | :--- |
| **medialab** | 10XX | ==>> | 65605
| **homelab** | 10XX | ==>> | 65606
| **privatelab** | 10XX | ==>> | 65607

To edit Synology user GID's you must SSH connect to the synology (cannot be done via WebGUI). Prerequisites for the next steps are:
*  You must have a nano editor installed if you want to manually edit the UID's. To install a nano editor see instructions [HERE](https://github.com/ahuacate/synobuild/blob/master/README.md#0001-install-nano).;
*  Synology SSH is enabled: `Control Panel` > `Terminal & SNMP` > `Enable SSH service` state is on .

Using a CLI terminal connect to your connect to your Synology:
```
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@cyclone-01:~$` if successful.

Synology DSM is Linux so we need switch user `root`. In the CLI terminal type the following to switch to `root@cyclone-01:~#` :
```
sudo -i
```
And next type the following to change all the UID's:
```
# Edit Medialab GID ID
sed -i 's|medialab:x:*:.*|medialab:x:65605:media,storm,typhoon|g' /etc/group &&
# Edit Homelab GID ID
sed -i 's|homelab:x:*:.*|homelab:x:65606:storm,typhoon|g' /etc/group &&
# Edit Privatelab GID ID
sed -i 's|privatelab:x:*:.*|privatelab:x:65607:typhoon|g' /etc/group &&
# Rebuild the Users
synouser --rebuild all
```

## 3.00 Create new Synology Users
Here we create the following new Synology users:
*  **media** - username `media` is the user for Proxmox LXC's and VM's used to run media applications (i.e jellyfin, sonarr, radarr, lidarr etc);
*  **storm** - username `storm` is the user for Proxmox LXC's and VM's used to run homelab applications (i.e syncthing, unifi, nextcloud, home assistant/smart home etc);
*  **typhoon** - username `typhoon` is the user for Proxmox LXC's and VM's used to run privatelab applications (i.e mailserver, messaging etc);

### 3.01 Create user "media"
To create a new user log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `media`
   * Description: `Medialab user`
   * Email: `Leave blank`
   * Password: `As Supplied`
   * Confirm password: `As Supplied`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  `☑`
3. Set Join groups as follows:
     * medialab:  `☑`
     * users:  `☑`
4. Assign shared folders permissions as follows:
     * Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.
5. Set User quota setting:
     * `default`
6. Assign application permissions:
     * Leave as default because all application permissions are automatically obtained from the medialab user 'group' permissions.
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`
     
### 3.02 Create user "storm"
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
     * Leave as default because all permissions are automatically obtained from the homelab user 'group' permissions.
5. Set User quota setting:
     * `default`
6. Assign application permissions:
     * Leave as default because all application permissions are automatically obtained from the homelab user 'group' 
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`
     
### 3.03 Create user "typhoon"
To create a new user log in to the Synology WebGUI interface and:
1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `typhoon`
   * Description: `Privatelab user`
   * Email: `Leave blank`
   * Password: `As Supplied`
   * Conform password: `As Supplied`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  `☑`
3. Set Join groups as follows:
     * privatelab:  `☑`
     * users:  `☑`
4. Assign shared folders permissions as follows:
     * Leave as default because all permissions are automatically obtained from the privatelab user 'group' permissions.
5. Set User quota setting:
     * `default`
6. Assign application permissions:
     * Leave as default because all application permissions are automatically obtained from the privatelab user 'group' 
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`
     
### 3.04 Edit Synology NAS user UID's
Synology DSM WebGUI Control Panel interface does'nt allow assigning a UID number when creating any new users. Each new user is assigned a random UID upwards of 1027.

It seems Synology We need to edit the user UID's for users media, storm and typhoon so they are known. This must be done after you have completed Steps 3.01 --> 3.03.

| Synology Username | Old UID | | New UID |
| :---  | ---: | :---: | :--- |
| **media** | 10XX | ==>> | 1605
| **storm** | 10XX | ==>> | 1606
| **typhoon** | 10XX | ==>> | 1607

To edit Synology user UID's you must SSH connect to the synology (cannot be done via WebGUI). Prerequisites for the next steps are:
*  You must have a nano editor installed if you want to manually edit the UID's. To install a nano editor see instructions [HERE](https://github.com/ahuacate/synobuild/blob/master/README.md#0001-install-nano).;
*  Synology SSH is enabled: `Control Panel` > `Terminal & SNMP` > `Enable SSH service` state is on .

Using a CLI terminal connect to your connect to your Synology:
```
ssh admin@192.168.1.10
```
Login as 'admin' and enter your Synology admin password at the prompt. The CLI terminal will show `admin@cyclone-01:~$` if successful.

Synology DSM is Linux so we need switch user `root`. In the CLI terminal type the following to switch to `root@cyclone-01:~#` :
```
sudo -i
```
And next type the following to change all the UID's:
```
# Edit Media User ID
userid=$(id -u media) &&
sed -i 's|media:x:.*|media:x:1605:100:Medialab user:/var/services/homes/media:/sbin/nologin|g' /etc/passwd &&
find / -uid $userid -exec chown storm "{}" \; &&
unset userid &&
# Edit Storm User ID
userid=$(id -u storm) &&
sed -i 's|storm:x:.*|storm:x:1606:100:Homelab user:/var/services/homes/storm:/sbin/nologin|g' /etc/passwd &&
find / -uid $userid -exec chown storm "{}" \; &&
unset userid &&
# Edit Typhoon User ID
userid=$(id -u typhoon) &&
sed -i 's|typhoon:x:.*|typhoon:x:1607:100:Privatelab user:/var/services/homes/typhoon:/sbin/nologin|g' /etc/passwd &&
find / -uid $userid -exec chown typhoon "{}" \; &&
unset userid &&
# Rebuild the Users
synouser --rebuild all
```

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

---

## 00.00 Patches and Fixes

### 00.01 Install Nano
Install Nano as a SynoCommunity package.

Log in to the Synology Desktop and go to `Package Center` > `Settings` > `Package Sources` > `Add` and complete the fields as follows:

| Option | Value
| :---  | :---: 
| Name | `SynoCommunity`
| Location | `http://packages.synocommunity.com/`

And click `OK`. Then type in the serach bar 'nano' and install Nano.
