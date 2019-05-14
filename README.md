# Synobuild
The following is for a Synology Diskstation only. Modify accordingly for your own NAS or NFS server setup.
Prerequisites are:
- [x] Synology Static IP Address is `192.168.1.10`
- [x] Synology Hostname is `cyclone-01`
- [x] Synology Gateway is `192.168.1.5`
- [x] Synology DNS Server is `192.168.1.5`

Tasks to be performed are:
- [ ] Create the required Synology shared folders and NFS shares
- [ ] Create two new Synology users;
  * first user named: `storm`
  * second user named: `gituser`
- [ ] Configure Synology NAS SSH Key-based authentication for the above users.

## Create the required Synology Shared Folders and NFS Shares
### Create Shared Folders
We need the following shared folder tree on the Synology NAS:
```
Synology NAS/
│
└──  volume1/
    ├── backup
    ├── docker
    ├── download
    ├── music 
    ├── openvpn
    ├── photo 
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
     * download ☐ 
     * music ☑
     * openvpn ☑
     * photo ☑
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
     
## Set up NFS Permissions
Create NFS shares for all of the above folders. 
1. Log in to the Synology Desktop and go to `Control Panel` > `Shared Folder` > `Select a Folder` > `Edit` > `NFS Permissions` > `Create `
2. Set NFS rule options as follows:
   * Hostname or IP*: `"192.168.1.0/24"`
   * Privilege: `Read/Write`
   * Squash: `Map all users to admin`
   * Security: `auth_sys`
     * Enable asynchronous:  ☑
     * Allow connections from non-privileged ports:  ☑
     * Allow users to access mounted subfolders:  ☑
3. Repeat steps 1 to 2 for all of the above folders BUT NOT `ssh_key` folder.

## Create new Synology User group
To create a new group log in to the Synology Desktop and:
1. Open `Control Panel` > `Group` > `Create`
2. Set User Information as follows:
   * Name: `"homelab"`
   * Description: `"Homelab Server group"`
3. Assign shared folders permissions as follows:
Note: Any private data you may have stored in a shared folder simply assign `No Access` to the `homelab` group.
| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup` | ☐ | ☑ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `homes` | ☐ | ☐ | ☐
| `download` | ☐ | ☑ |  ☐
| `music` | ☐ | ☑ |  ☐
| `openvpn` | ☐ | ☑ |  ☐
| `photo` | ☐ | ☑ |  ☐
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
| `File Station` | ☐ | ☑ | 
| `FTP` | ☑ | ☐  | 
| `Moments` | ☐ | ☑ | 
| `Text Editor` | ☐ | ☑ | 
| `Universal Search` | ☐ | ☑ | 
| `rsync` | ☐ | ☑ |  
6. Group Speed Limit Setting
    * `default`

## Create two new Synology Users
### Create user "storm":
To create a new user log in to the Synology Desktop and:
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
Basically leave as default as permissions are automatically obtained from the user 'group' permissions.
| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup` | ☐ | ☑ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `download` | ☐ | ☑ |  ☐
| `music` | ☐ | ☑ |  ☐
| `openvpn` | ☑ |  ☐ |  ☐
| `photo` | ☐ | ☑ |  ☐
| `pxe` | ☐ | ☑ |  ☐
| `ssh_key` | ☑ |  ☐ |  ☐
| `video` | ☐ | ☑ |  ☐
| `virtualbox` | ☐ | ☑ |  ☐
| `proxmox` | ☐ | ☑ |  ☐
5. Set User quota setting:
     * `default`
6. Assign application permissions:
| Name | Allow | Deny |
| :---  | :---: | :---: |
| `DSM` | ☐ | ☑ |  
| `Drive` | ☐ | ☑ | 
| `File Station` | ☐ | ☑ | 
| `FTP` | ☑ |  ☐ | 
| `Moments` | ☐ | ☑ | 
| `Text Editor` | ☐ | ☑ | 
| `Universal Search` | ☐ | ☑ | 
| `rsync` | ☐ | ☑ | 
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`

### Create user "gituser":
To create a new user log in to the Synology Desktop and:
1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `"gituser"`
   * Description: `"Homelab user"`
   * Email: `Leave blank`
   * Password: `"As Supplied"`
   * Conform password: `"As Supllied"`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  ☑
3. Set Join groups as follows:
     * homelab:  ☑
     * users:  ☑
4. Assign shared folders permissions as follows:

| Name | No access | Read/Write | Read Only |
| :---  | :---: | :---: | :---: |
| `backup` | ☑ |  ☐ |  ☐
| `docker` | ☐ | ☑ |  ☐
| `download` | ☑ |  ☐ |  ☐
| `music` | ☑ |  ☐ |  ☐
| `openvpn` | ☑ |  ☐ |  ☐
| `photo` | ☑ |  ☐ |  ☐
| `pxe` | ☐ | ☑ |  ☐
| `ssh_key` | ☑ |  ☐ |  ☐
| `video` | ☑ |  ☐ |  ☐
| `virtualbox` | ☐ | ☑ |  ☐
| `proxmox` | ☐ | ☑ |  ☐
5. Set User quota setting:
     * `default`
6. Assign application permissions:
     * `default`
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`

## Setting up Key Based Authentication
 I want to SSH into the synology diskstation using key-based authentication, but that seemed not supported by default. So to enable SSH key-based authentication we need to make a few tweaks. But first make sure you have your public SSH keys, commonly has a filename `id_rsa.pub`, on your PC (notebook, workstation or whatever).
 
### Enable SSH Server
Log in to the Synology Desktop and go to **`"Control Panel > Terminal & SNMP"`**
Check **`Enable SSH Service`** and choose a non-default port . If you use the default port of 22 you'll get a security warning later.

### Enable Public Key Authentication

Log in to your NAS using ssh:

    ssh -p <port> storm@192.168.1.10

Open the SSH server configuration file for editing:

sudo vim /etc/ssh/sshd_config

Find the following lines and uncomment them (remove the #):

#RSAAuthentication yes
#PubkeyAuthentication yes

It's possible to restart the service using the following command:

sudo synoservicectl --reload sshd

Generate an SSH key

If you have not done this already, you should probably check how to do this with whatever ssh client you are using.

I'm using the Cygwin terminal on Windows, and I can generate a key pair using this command:

ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

Follow the instructions here, they are for GitHub but they apply to everything that needs an ssh key: Generating a new SSH key

The result, by default, is some files in the folder ~/.shh. Among which your private (id_rsa) and public key (id_rsa.pub).
Add public key to Authorized Keys

Ssh into the NAS again.

On the NAS, you must create a file ~/.ssh/authorized_keys:

mkdir ~/.ssh
touch ~/.ssh/authorized_keys

In that file, you must add the contents of your local ~/.ssh/id_rsa.pub. SSH then uses this public key to verify that your client machine is in posession of the private key. Then it lets you in.

On my client I did the following to first copy over my public key:

scp -P <port> ~/.ssh/id_rsa.pub my-nas-user@my-nas-hostname:/var/services/homes/my-nas-user

And then on the NAS SSH session:

cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
rm ~/id_rsa.pub
