# Synobuild
The following is for a Synology Diskstation only. Modify accordingly for your own NAS or NFS server setup.
The tasks to be performed are:
- [ ] Create the required Synology pools, volumes, shared folders and NFS shares
- [ ] Create two new Synology users;
  * first user named: `storm`
  * second user named: `gituser`
- [ ] Configure Synology NAS SSH Key-based authentication for the above users.

## Create the required Syno storage pools, volumes, shared folders and NFS shares
### Create a SSD Storage Pool
If you have a empty Synology disk bay it can be used as a SSD `download share drive` for all virtual machines & nodes, lxc containers, docker clients and cluster nodes. I recommend a single SSD 500Gb because this disk will be used for non critical data such as downloads, cache, transcodes etc. If you dont have a empty Synology disk bay then skip this step.
>> Important:
Before you start, make sure there is no important data on the SSD drive that the storage pool is going to be created on. All existing data will be deleted during the creation process. Log in to the Synology Desktop and go to `"Storage Manager > HDD/SSD"` page and make sure the status of each drive (actually, your newly inserted drive in bay (x)) is `Normal` or `Not Initialized`.

To create a Syno storage pool log in to the Synology Desktop and:
1. Open `"Storage Manager > Storage Pool > Create"`.
2. Choose the storage pool type:
   `"Higher Flexibility"`
3. Configure storage pool properties:
   Storage pool description: `"download"`
   RAID type: `"SHR"`
4. Choose Disks: `"Select your newly installed SSD 0,5 TB"`
5. Perform Disk Check: `"Yes"`
6. Confirm settings: All looks good hit `"Apply"` and be patient as it takes a while to verify & perform a parity check on the new disk.

### Create Volumes

### Shared Folders
The following Synology shared folders are needed:
```
<h2>Synology Folder Tree</h2>
<pre>
Synology NAS with 2x Volumes/
│
├── volume1/
│   ├── docker
│   ├── music
│   ├── openvpn
│   ├── photo
│   ├── pxe
│   ├── ssh_key
│   ├── video
│   ├── virtualbox
│   └── proxmox
│
└──  volume2/
    ├── cache
    ├── download
    └── transcode

Synology NAS with 1x Volume/
│
└──  volume1/
    ├── cache
    ├── docker
    ├── download
    ├── music
    ├── openvpn
    ├── photo
    ├── pxe
    ├── ssh_key
    ├── video
    ├── virtualbox
    ├── proxmox
    └── transcode
</pre>
```
You can create a shared folder in the Synology Desktop:

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
