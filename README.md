# Synobuild
The following post is specifically for a Synology Diskstation. I want to SSH into it using key-based authentication, but that seemed not supported by default. In this post I explain how I made it work.
The steps are:
* create required volum
* create two new synology users;
  * user one named: `storm`
  * user two named: `gituser`
* Configure Synology NAS SSH Key-based authentication for the above users.

## Setting up Key Based Authentication
Normally, setting this up is not a lot of work:
* Make sure your SSH daemon has Public Key Authentication enabled
* Make sure you have an SSH key on your client machine
* Make sure the public key is in ~/.ssh/authorized_keys
### Enable SSH Server
Log in to the Synology Desktop and go to **"Control Panel > Terminal & SNMP"**
Check **Enable SSH Service** and choose a non-default port. If you use the default port of 22 you'll get a security warning later.
### Enable Public Key Authentication

Log in to your NAS using ssh:

    ssh -p <port> your-nas-user@your-nas-hostname

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
