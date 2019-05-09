# Synobuild
The following is for a Synology Diskstation only. Modify accordingly for your own NAS or NFS server setup.
The tasks to be performed are:
- [ ] Create the required Synology shared folders and NFS shares
- [ ] Create two new Synology users;
  * first user named: `storm`
  * second user named: `gituser`
- [ ] Configure Synology NAS SSH Key-based authentication for the above users.

## Create the required Synology Shared Folders and NFS Shares
### Create Shared Folders
We need the following shared folder tree on the Synology NAS:
```
Synology NAS with 1x Volume/
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
1. Open `"Control Panel > Shared Folder > Create"`.
2. Set up basic information:
   Name: `"i.e backup"`
   Description: `"leave blank"`
   Location: `"Volume 1"`
3. Configure storage pool properties:
   Storage pool description: `"download"`
   RAID type: `"SHR"`
4. Choose Disks: `"Select your newly installed SSD 0,5 TB"`
5. Perform Disk Check: `"Yes"`
6. Confirm settings: All looks good hit `"Apply"` and be patient as it takes a while to verify & perform a parity check on the new disk.



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
