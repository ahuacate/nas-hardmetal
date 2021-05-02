#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR
trap cleanup EXIT
function error_exit() {
  trap - ERR
  local DEFAULT='Unknown failure occured.'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[ERROR] \e[93m$EXIT@$LINE"
  msg "$FLAG $REASON"
  [ ! -z ${CTID-} ] && cleanup_failed
  exit $EXIT
}
function warn() {
  local REASON="\e[97m$1\e[39m"
  local FLAG="\e[93m[WARNING]\e[39m"
  msg "$FLAG $REASON"
}
function info() {
  local REASON="$1"
  local FLAG="\e[36m[INFO]\e[39m"
  msg "$FLAG $REASON"
}
function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}
function pushd () {
  command pushd "$@" &> /dev/null
}
function popd () {
  command popd "$@" &> /dev/null
}
function cleanup() {
  popd
  rm -rf $TEMP_DIR
  unset TEMP_DIR
}
function box_out() {
  set +u
  local s=("$@") b w
  for l in "${s[@]}"; do
	((w<${#l})) && { b="$l"; w="${#l}"; }
  done
  tput setaf 3
  echo " -${b//?/-}-
| ${b//?/ } |"
  for l in "${s[@]}"; do
	printf '| %s%*s%s |\n' "$(tput setaf 7)" "-$w" "$l" "$(tput setaf 3)"
  done
  echo "| ${b//?/ } |
 -${b//?/-}-"
  tput sgr 0
  set -u
}

# Colour
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
WHITE=$'\033[1;37m'
NC=$'\033[0m'

# Resize Terminal
printf '\033[8;40;120t'


# Set Temp Folder
if [ -z "${TEMP_DIR+x}" ]; then
  TEMP_DIR=$(mktemp -d)
  pushd $TEMP_DIR >/dev/null
else
  if [ $(pwd -P) != $TEMP_DIR ]; then
    cd $TEMP_DIR >/dev/null
  fi
fi

# Command to run script
#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/nas-oem-setup/master/scripts/nas_oem_setup_nas_linux_setup.sh)"

# Checking for Internet connectivity
msg "Checking for internet connectivity..."
if nc -zw1 google.com 443; then
    info "Internet connectivity status: ${GREEN}Active${NC}"
    echo
else
    warn "Internet connectivity status: ${RED}Down${NC}\n          Cannot proceed without a internet connection.\n          Fix your machines internet connection and try again..."
    echo
    cleanup
    exit 0
fi

# Script Variables
SECTION_HEAD="LINUX (Ubuntu) FILE SERVER"

# Download external scripts (ignore zfs stuff - using existing default file which is common for linux)
wget -qL https://raw.githubusercontent.com/ahuacate/pve-zfs-nas/master/scripts/pve_zfs_nas_base_folder_setup

#########################################################################################
# This script is for preparing a Linux (Ubuntu) File Server (NAS)                       #
#                                                                 						          #
# Tested on Ubuntu Version : 20.10                                                      #
#########################################################################################

#### Introduction ####
section "$SECTION_HEAD - Introduction"

box_out '#### PLEASE READ CAREFULLY ####' '' 'This script is for Linux File Servers (NAS). Written for Ubuntu 20.10.' 'User input is required. The script will create, edit and/or change system files' 'on your Linux server.' 'When an optional default setting is provided you can accept our' 'default (Recommended) by pressing ENTER on your keyboard. Or overwrite our' 'default value by typing in your own value and then pressing ENTER to' 'accept and to continue to the next step.' '' 'In the next steps you will asked to create and setup:' '  --  Create Linux Groups (medialab, homelab and privatelab).' '  --  Create Linux Users (media, home and private)' '  --  Create a set of default folders on your server.' '  --  Create NFS and CIFS exports for your PVE hosts.' 

echo
read -p "Proceed with running this script on $HOSTNAME [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  info "Proceeding."
  echo
else
  info "You have chosen to skip this script. Aborting."
  cleanup
  exit 0
fi


#### Performing Prerequisites ####
section "$SECTION_HEAD - Performing Prerequisites"

# Setting some Network Variables
msg "Setting the $SECTION_HEAD variables..."
msg "We need to identify the IPv4 address of each and every PVE host machine\non your LAN. Our default PVE hosts IPv4 address's are:\n  --  192.168.1.101\n  --  192.168.1.102\n  --  192.168.1.103\n  --  192.168.1.104"
while true; do
  if [ ! -f pve_ip_list_var01 ]; then
    touch pve_ip_list_var01
  fi
  read -p "Enter a PVE host IPv4 address: " -e -i 192.168.1.101 PVE_IP
  if [ $(expr "$PVE_IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; echo $?) == 0 ] && [ $(ping -s 1 -c 2 "$(echo "$PVE_IP")" > /dev/null; echo $?) = 0 ] && [ $(cat pve_ip_list_var01 | grep "$PVE_IP/24" >/dev/null; echo $?) = 1 ]; then
    info "PVE host IPv4 address is set: ${YELLOW}$PVE_IP${NC}."
    echo $PVE_IP/24 >> pve_ip_list_var01
    echo
    read -p "Do you have another PVE host on your LAN [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      msg "Now add your next PVE host IPv4 address."
      echo
    else
      info "You have chosen not add another PVE host."
      echo
      break
    fi
  elif [ $(expr "$PVE_IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; echo $?) != 0 ]; then
    warn "There are problems with your input:\n1.  Your IP address is incorrectly formatted. It must be in the IPv4 format\n    (i.e xxx.xxx.xxx.xxx )."
    echo
    if [ $(cat pve_ip_list_var01 | wc -l) -ge 1 ]; then
      read -p "Do you want to try again [y/n]? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Try again..."
        echo
      else
        info "You have chosen not to try adding another PVE host."
      echo
      break
      fi
    else
      msg "Try again..."
      echo
    fi
  elif [ $(expr "$PVE_IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; echo $?) == 0 ] && [ $(cat pve_ip_list_var01 | grep "$PVE_IP/24" >/dev/null; echo $?) = 1 ] && [ $(ping -s 1 -c 2 "$(echo "$PVE_IP")" > /dev/null; echo $?) != 0 ]; then
    warn "There are problems with your input:\n1. The IP address meets the IPv4 standard, BUT\n2. The IP address $(echo "$PVE_IP") is not reachable by ping."
    echo
    msg "It may be PVE host ${WHITE}$PVE_IP${NC} is currently down or you want to prepare your\nnetwork for the future. If so, check IP ${WHITE}$PVE_IP${NC} is valid and add it."
    echo
    read -p "Do you want to add ${WHITE}$PVE_IP${NC} anyway [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo $PVE_IP/24 >> pve_ip_list_var01
      info "PVE host IPv4 address is set: ${YELLOW}$PVE_IP${NC}."
      echo
    fi
    if [ $(cat pve_ip_list_var01 | wc -l) -ge 1 ]; then
      read -p "Do you have another PVE host on your LAN [y/n]? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Try again..."
        echo
      else
        info "You have chosen not to try adding another PVE host."
      echo
      break
      fi
    else
      msg "Try again..."
      echo
    fi
  elif [ $(expr "$PVE_IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; echo $?) == 0 ] && [ $(ping -s 1 -c 2 "$(echo "$PVE_IP")" > /dev/null; echo $?) = 0 ] && [ $(cat pve_ip_list_var01 | grep "$PVE_IP/24" >/dev/null; echo $?) = 0 ]; then
    warn "There are problems with your input:\n1. The IP address meets the IPv4 standard,\n2. The IP address $(echo "$PVE_IP") is reachable by ping, BUT\n2. The IP address $(echo "$PVE_IP") has already been added."
    echo
    if [ $(cat pve_ip_list_var01 | wc -l) -ge 1 ]; then
      read -p "Do you want to try again [y/n]? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Try again..."
        echo
      else
        info "You have chosen not to try adding another PVE host."
      echo
      break
      fi
    else
      msg "Try again..."
      echo
    fi
  fi
done
echo
# Check PVE host list for duplicate entries
cat pve_ip_list_var01 | awk '! a[$0]++' > pve_ip_list

# Checking Hosts networking protocols
# Samba
if [ $(dpkg -s samba-common-bin >/dev/null 2>&1; echo $?) = 0 ]; then
  msg "Checking samba-common-bin status..."
  info "samba-common-bin status: ${GREEN}installed.${NC}"
  echo
else
  msg "Installing samba-common-bin..."
  sudo apt-get install -y samba-common-bin
  if [ $(dpkg -s samba-common-bin >/dev/null 2>&1; echo $?) = 0 ]; then
    info "samba-common-bin status: ${GREEN}installed.${NC}"
  fi
  echo
fi
if [ $(dpkg -s samba >/dev/null 2>&1; echo $?) = 0 ]; then
  msg "Checking samba status..."
  info "samba status: ${GREEN}installed.${NC}"
  echo
else
  msg "Installing samba..."
  sudo apt-get install -y samba
  if [ $(dpkg -s samba >/dev/null 2>&1; echo $?) = 0 ]; then
    info "samba status: ${GREEN}installed.${NC}"
  fi
  echo
fi
# ACL
if [ $(dpkg -s acl >/dev/null 2>&1; echo $?) = 0 ]; then
  msg "Checking ACL status..."
  info "ACL status: ${GREEN}installed.${NC}"
  echo
else
  msg "Installing ACL..."
  sudo apt-get install -y acl
  if [ $(dpkg -s acl >/dev/null 2>&1; echo $?) = 0 ]; then
    info "ACL status: ${GREEN}installed.${NC}"
  fi
  echo
fi
# NFS
if [ $(dpkg -s nfs-kernel-server >/dev/null 2>&1; echo $?) = 0 ]; then
  msg "Checking NFS status..."
  info "NFS status: ${GREEN}installed.${NC}"
  echo
else
  msg "Installing NFS..."
  sudo apt-get install -y nfs-kernel-server
  if [ $(dpkg -s nfs-kernel-server >/dev/null 2>&1; echo $?) = 0 ]; then
    info "NFS status: ${GREEN}installed.${NC}"
  fi
  echo
fi

# Set your NAS base folder for creating PVE share points
box_out '#### PLEASE READ CAREFULLY - BASE FOLDER ####' '' 'In this step we need to determine a storage point on your server to be used as' 'a base folder (base folder start tree) to create all the default PVE storage' 'folders in. The base folder should be the largest capacity volume on your' 'NAS. This action will NOT affect your existing data.' '' 'For example, on my Linux server the default base volume is "/tank/nas". So in' 'this example our base folder would be: "/tank/nas".'
echo
msg "When entering your base folder include the full folder path: /dir1/dir2"
while true; do
  msg "Setting your $SECTION_HEAD base folder..."
  read -p "Enter your base folder structure ( i.e /dir1/dir2 ) ?: " -e BASE_FOLDER_VAR
  if [ -d "$BASE_FOLDER_VAR" ]; then
    info "Success. $BASE_FOLDER_VAR exists. Its a GO."
    echo
    break
  else
    warn "Your base folder $BASE_FOLDER_VAR does not exist.\nTry again..."
    echo
  fi
done


#### Creating File Server Users and Groups ####
section "$SECTION_HEAD - Creating Users and Groups."

# Change Home folder permissions
DIR_MODE_FILE="/etc/adduser.conf"
if [ -f "$DIR_MODE_FILE" ]; then
  msg "Setting default adduser home folder permissions (DIR_MODE)..."
  sed -i "s/DIR_MODE=.*/DIR_MODE=0750/g" /etc/adduser.conf
  info "Default adduser permissions set: ${YELLOW}0750${NC}"
  echo
fi

# Create users and groups
msg "Creating CT default user groups..."
# Create Groups
getent group medialab >/dev/null
if [ $? -ne 0 ]; then
	sudo groupadd -g 65605 medialab
  info "Default user group created: ${YELLOW}medialab${NC}"
fi
getent group homelab >/dev/null
if [ $? -ne 0 ]; then
	sudo groupadd -g 65606 homelab
  info "Default user group created: ${YELLOW}homelab${NC}"
fi
getent group privatelab >/dev/null
if [ $? -ne 0 ]; then
	sudo groupadd -g 65607 privatelab
  info "Default user group created: ${YELLOW}privatelab${NC}"
fi
getent group chrootjail >/dev/null
if [ $? -ne 0 ]; then
	sudo groupadd -g 65608 chrootjail
  info "Default user group created: ${YELLOW}chrootjail${NC}"
fi
echo

# Create Base User Accounts
msg "Creating CT default users..."
sudo mkdir -p $BASE_FOLDER_VAR/homes >/dev/null
sudo chgrp -R root $BASE_FOLDER_VAR/homes >/dev/null
sudo chmod -R 0750 $BASE_FOLDER_VAR/homes >/dev/null
id -u media &>/dev/null
if [ $? = 1 ]; then
	useradd -m -d $BASE_FOLDER_VAR/homes/media -u 1605 -g medialab -s /bin/bash media >/dev/null
  info "Default user created: ${YELLOW}media${NC} of group medialab"
fi
id -u home &>/dev/null
if [ $? = 1 ]; then
	useradd -m -d $BASE_FOLDER_VAR/homes/home -u 1606 -g homelab -G medialab -s /bin/bash home >/dev/null
  info "Default user created: ${YELLOW}home${NC} of groups medialab, homelab"
fi
id -u private &>/dev/null
if [ $? = 1 ]; then
	useradd -m -d $BASE_FOLDER_VAR/homes/private -u 1607 -g privatelab -G medialab,homelab -s /bin/bash private >/dev/null
  info "Default user created: ${YELLOW}private${NC} of groups medialab, homelab and privatelab"
fi
echo


#### Setting Folder Permissions ####
section "$SECTION_HEAD - Creating and Setting Folder Permissions."

# Create NAS Share points
echo
box_out '#### PLEASE READ CAREFULLY - SHARED FOLDERS ####' '' 'Shared folders are the basic directories where you can store files and folders on your NAS.' 'Below is a list of our default shared folders that are created by this script:'  '' '  --  /BASE_FOLDER/"audio"' '  --  /BASE_FOLDER/"audio/audiobooks"' '  --  /BASE_FOLDER/"backup"' '  --  /BASE_FOLDER/"books"' '  --  /BASE_FOLDER/"cloudstorage"' '  --  /BASE_FOLDER/"docker"' '  --  /BASE_FOLDER/"downloads"' '  --  /BASE_FOLDER/"git"' '  --  /BASE_FOLDER/"homes"' '  --  /BASE_FOLDER/"music"' '  --  /BASE_FOLDER/"openvpn"' '  --  /BASE_FOLDER/"photo"' '  --  /BASE_FOLDER/"proxmox"' '  --  /BASE_FOLDER/"public"' '  --  /BASE_FOLDER/"sshkey"' '  --  /BASE_FOLDER/"video"' '  --  /BASE_FOLDER/"video/cctv"' '  --  /BASE_FOLDER/"video/documentary"' '  --  /BASE_FOLDER/"video/homevideo"' '  --  /BASE_FOLDER/"video/movies"' '  --  /BASE_FOLDER/"video/musicvideo"' '  --  /BASE_FOLDER/"video/pron"' '  --  /BASE_FOLDER/"video/series"' '  --  /BASE_FOLDER/"video/transcode"' '' 'You can also create custom shared folders in the coming steps.'
echo
echo
touch pve_zfs_nas_base_folder_setup-xtra
while true; do
  read -p "Do you want to create custom shared folders on your NAS [y/n]?: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    while true; do
      echo
      read -p "Enter a new shared folder name : " xtra_sharename
      read -p "Confirm new shared folder name (type again): " xtra_sharename2
      xtra_sharename=${xtra_sharename,,}
      xtra_sharename=${xtra_sharename2,,}
      echo
      if [ "$xtra_sharename" = "$xtra_sharename2" ];then
        info "Shared folder name is set: ${YELLOW}$xtra_sharename${NC}."
        XTRA_SHARES=0 >/dev/null
        break
      elif [ "$xtra_sharename" != "$xtra_sharename2" ]; then
        warn "Your inputs do NOT match. Try again..."
      fi
    done
    msg "Select your new shared folders group permission rights."
    XTRA_SHARE01="Standard User - For restricted jailed users (GID: chrootjail)." >/dev/null
    XTRA_SHARE02="Medialab - Photos, series, movies, music and general media content only." >/dev/null
    XTRA_SHARE03="Homelab - Everything to do with your smart home." >/dev/null
    XTRA_SHARE04="Privatelab - User has access to all NAS data." >/dev/null
    PS3="Select your new shared folders group permission rights (entering numeric) : "
    echo
    select xtra_type in "$XTRA_SHARE01" "$XTRA_SHARE02" "$XTRA_SHARE03" "$XTRA_SHARE04"
    do
    echo
    info "You have selected: $xtra_type ..."
    echo
    break
    done
    if [ "$xtra_type" = "$XTRA_SHARE01" ]; then
      XTRA_USERGRP="root 0750 chrootjail:rwx privatelab:rwx"
    elif [ "$xtra_type" = "$XTRA_SHARE02" ]; then
      XTRA_USERGRP="root 0750 medialab:rwx privatelab:rwx"
    elif [ "$xtra_type" = "$XTRA_SHARE03" ]; then
      XTRA_USERGRP="root 0750 homelab:rwx privatelab:rwx"
    elif [ "$xtra_type" = "$XTRA_SHARE04" ]; then
      XTRA_USERGRP="root 0750 privatelab:rwx"
    fi
    echo "$xtra_sharename $XTRA_USERGRP" >> pve_zfs_nas_base_folder_setup
    echo "$xtra_sharename $XTRA_USERGRP" >> pve_zfs_nas_base_folder_setup-xtra
  else
    info "Skipping creating anymore additional shared folders."
    XTRA_SHARES=1 >/dev/null
    break
  fi
done
echo


# Create NAS Share points
msg "Creating NAS base $BASE_FOLDER_VAR folder shares..."
echo
cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | sed '/^$/d' >/dev/null > pve_zfs_nas_base_folder_setup_input
dir_schema="$BASE_FOLDER_VAR"
while read -r dir group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
  if [ -d "$dir_schema${dir}" ]; then
    info "Pre-existing folder: ${RED}"$dir_schema${dir}"${NC}\n  Setting ${group} group permissions for existing folder."
    sudo chgrp -R "${group}" "$dir_schema${dir}" >/dev/null
    sudo chmod -R "${permission}" "$dir_schema${dir}" >/dev/null
    if [ ! -z ${acl_01} ]; then
      sudo setfacl -Rm g:${acl_01} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_02} ]; then
      sudo setfacl -Rm g:${acl_02} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_03} ]; then
      sudo setfacl -Rm g:${acl_03} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_04} ]; then
      sudo setfacl -Rm g:${acl_04} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_05} ]; then
      sudo setfacl -Rm g:${acl_05} "$dir_schema${dir}"
    fi
    echo
  else
    info "New base folder created:\n  ${WHITE}"$dir_schema${dir}"${NC}"
    sudo mkdir -p "$dir_schema${dir}" >/dev/null
    sudo chgrp -R "${group}" "$dir_schema${dir}" >/dev/null
    sudo chmod -R "${permission}" "$dir_schema${dir}" >/dev/null
    if [ ! -z ${acl_01} ]; then
      sudo setfacl -Rm g:${acl_01} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_02} ]; then
      sudo setfacl -Rm g:${acl_02} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_03} ]; then
      sudo setfacl -Rm g:${acl_03} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_04} ]; then
      sudo setfacl -Rm g:${acl_04} "$dir_schema${dir}"
    fi
    if [ ! -z ${acl_05} ]; then
      sudo setfacl -Rm g:${acl_05} "$dir_schema${dir}"
    fi
    echo
  fi
done < pve_zfs_nas_base_folder_setup_input


# Create Default NAS SubFolders
if [ -f pve_zfs_nas_base_subfolder_setup ]; then
  msg "Creating NAS subfolder shares..."
  echo
  echo -e "$(eval "echo -e \"`<pve_zfs_nas_base_subfolder_setup`\"")" | sed '/^#/d' | sed '/^$/d' >/dev/null > pve_zfs_nas_base_subfolder_setup_input
  while read -r dir group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
    if [ -d "${dir}" ]; then
      info "${dir} exists, setting ${group} group permissions for this folder."
      sudo chgrp -R "${group}" "${dir}" >/dev/null
      sudo chmod -R "${permission}" "${dir}" >/dev/null
      if [ ! -z ${acl_01} ]; then
        sudo setfacl -Rm g:${acl_01} "${dir}"
      fi
      if [ ! -z ${acl_02} ]; then
        sudo setfacl -Rm g:${acl_02} "${dir}"
      fi
      if [ ! -z ${acl_03} ]; then
        sudo setfacl -Rm g:${acl_03} "${dir}"
      fi
      if [ ! -z ${acl_04} ]; then
        sudo setfacl -Rm g:${acl_04} "${dir}"
      fi
      if [ ! -z ${acl_05} ]; then
        sudo setfacl -Rm g:${acl_05} "${dir}"
      fi
      echo
    else
      info "New subfolder created:\n  ${WHITE}"${dir}"${NC}"
      sudo mkdir -p "${dir}" >/dev/null
      sudo chgrp -R "${group}" "${dir}" >/dev/null
      sudo chmod -R "${permission}" "${dir}" >/dev/null
      if [ ! -z ${acl_01} ]; then
        sudo setfacl -Rm g:${acl_01} "${dir}"
      fi
      if [ ! -z ${acl_02} ]; then
        sudo setfacl -Rm g:${acl_02} "${dir}"
      fi
      if [ ! -z ${acl_03} ]; then
        sudo setfacl -Rm g:${acl_03} "${dir}"
      fi
      if [ ! -z ${acl_04} ]; then
        sudo setfacl -Rm g:${acl_04} "${dir}"
      fi
      if [ ! -z ${acl_05} ]; then
        sudo setfacl -Rm g:${acl_05} "${dir}"
      fi
      echo
    fi
  done < pve_zfs_nas_base_subfolder_setup_input
fi

#### Install and Configure Samba ####
section "$SECTION_HEAD - Installing and configuring Samba."

# Configure Samba Basics
echo
box_out '#### PLEASE READ CAREFULLY - SAMBA SETUP ####' '' 'In the next step you have some choices to make. Easy Script is about to modify' 'your SMB configuration file (/etc/samba/smb.conf).' '' 'The first choice is whether you permit our Easy Script to modify your current' 'SMB Global Settings in your smb.conf file and set a Public folder share.' 'The following are the only settings which will be modified:' '   [global]' '   inherit permissions = yes' '   inherit acls = yes' '   vfs objects = acl_xattr' '   follow symlinks = yes' '   hosts allow = 127.0.0.1 (appending only)' '                 192.168.1.0/24' '                 192.168.20.0/24' '                 192.168.30.0/24' '                 192.168.40.0/24' '                 192.168.50.0/24' '                 192.168.60.0/24' '                 192.168.80.0/24' '' 'We recommend you agree to this action. In the worst case a backup of your old' '/etc/samba/smb.conf has been created (/etc/samba/smb.conf.bak)'
echo
echo
msg "Configuring Samba..."
msg ""
read -p "Modify your current SMB configuration (Careful - Read Above!) [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
msg "Stopping your SMB service..."
sudo service smbd stop 2>/dev/null
msg "Creating a backup of your /etc/samba/smb.conf file..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak >/dev/null
msg "Modifying /etc/samba/smb.conf..."
# SMB Config file
SMB_CONFIG='/etc/samba/smb.conf'
# inherit permissions
PATTERN='inherit permissions =.*'
PATTERN_MOD='inherit permissions = yes'
SECTION='global'
for i in $SECTION; do
    sed -n '/\['$i'\]/,/\[/{/^\[.*$/!p}' $SMB_CONFIG | while read -r line; do
        if [[ $(echo $line | grep "$PATTERN") ]]; then
            sudo sed -i "s/$PATTERN/$PATTERN_MOD/" $SMB_CONFIG
        fi
    done
done
# inherit acls
PATTERN='inherit acls =.*'
PATTERN_MOD='inherit acls = yes'
SECTION='global'
for i in $SECTION; do
    sed -n '/\['$i'\]/,/\[/{/^\[.*$/!p}' $SMB_CONFIG | while read -r line; do
        if [[ $(echo $line | grep "$PATTERN") ]]; then
            sudo sed -i "s/$PATTERN/$PATTERN_MOD/" $SMB_CONFIG
        fi
    done
done
# vfs objects
PATTERN='vfs objects =.*'
PATTERN_MOD='vfs objects = acl_xattr'
SECTION='global'
for i in $SECTION; do
    sed -n '/\['$i'\]/,/\[/{/^\[.*$/!p}' $SMB_CONFIG | while read -r line; do
        if [[ $(echo $line | grep "$PATTERN") ]]; then
            sudo sed -i "s/$PATTERN/$PATTERN_MOD/" $SMB_CONFIG
        fi
    done
done
# follow symlinks
PATTERN='follow symlinks =.*'
PATTERN_MOD='follow symlinks = yes'
SECTION='global'
for i in $SECTION; do
    sed -n '/\['$i'\]/,/\[/{/^\[.*$/!p}' $SMB_CONFIG | while read -r line; do
        if [[ $(echo $line | grep "$PATTERN") ]]; then
            sudo sed -i "s/$PATTERN/$PATTERN_MOD/" $SMB_CONFIG
        fi
    done
done
# hosts allow (adding to existing)
while IFS= read -r line
do
  echo $line | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\.\)[0-9]*/\10/' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""20"".0/24"}' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""30"".0/24"}' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""40"".0/24"}' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""50"".0/24"}' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""60"".0/24"}' >> smb_export_list_var01
  echo $line | awk -F'.' '{print $1"."$2".""80"".0/24"}' >> smb_export_list_var01
done <<< $(cat pve_ip_list)
# Remove Duplicates, one line
cat smb_export_list_var01 | awk '! a[$0]++' | sort  | tr '\n' ' ' | sed 's/ *$//' | sed 's:/:\\/:g' > smb_export_list
PATTERN='hosts allow =.*'
PATTERN_MOD="$smb_export_list"
SECTION='global'
for i in $SECTION; do
    sed -n '/\['$i'\]/,/\[/{/^\[.*$/!p}' $SMB_CONFIG | while read -r line; do
        if [[ $(echo $line | grep "$PATTERN") ]]; then
            sudo sed -i "s/$PATTERN/& $PATTERN_MOD/" $SMB_CONFIG
        fi
    done
done
# Adding public folder
if [[ $(cat $SMB_CONFIG | grep '[public]') ]]; then
    msg "You have a existing SMB [public] share.\nRenaming existing [public] to [nas-public]..."
    sudo sed -i "s/^\[public]/\[nas-public\]/" $SMB_CONFIG
fi
msg "Creating a PVE [public] SMB share..."
echo -e "\n[public]\ncomment = public anonymous access\npath = $BASE_FOLDER_VAR/public\nwritable = yes\nbrowsable =yes\npublic = yes\nread only = no\ncreate mode =0777\ndirectorymode = 0777\nforce user = nobody\nguest ok = yes\nhide dot files = yes" >> $SMB_CONFIG

# Create your Default and Custom Samba Shares 
msg "Creating default and custom Samba folder shares..."
cat pve_zfs_nas_base_folder_setup pve_zfs_nas_base_folder_setup-xtra | sed '/^#/d' | sed '/^$/d' | awk '!seen[$0]++' | awk '{ print $1 }' | sed '/homes/d;/public/d' > pve_zfs_nas_base_folder_setup-samba_dir
schemaExtractDir="$BASE_FOLDER_VAR"
while read dir; do
  dir01="$schemaExtractDir/$dir"
  if [ -d "$dir01" ]; then
    dirgrp01=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $2}' | sed 's/chrootjail.*//') || true >/dev/null
    dirgrp02=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $4}' | sed 's/chrootjail.*//' | sed 's/:.*//') || true >/dev/null
    dirgrp03=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $5}' | sed 's/chrootjail.*//' | sed 's/:.*//') || true >/dev/null
    dirgrp04=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $6}' | sed 's/chrootjail.*//' | sed 's/:.*//') || true >/dev/null
    dirgrp05=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $7}' | sed 's/chrootjail.*//' | sed 's/:.*//') || true >/dev/null
    dirgrp06=$(cat pve_zfs_nas_base_folder_setup | sed '/^#/d' | grep -i $dir | awk '{ print $8}' | sed 's/chrootjail.*//' | sed 's/:.*//') || true >/dev/null
	sudo eval "cat <<-EOF >> /etc/samba/smb.conf

	[$dir]
		comment = $dir folder access
		path = ${dir01}
		browsable =yes
		read only = no
		create mask = 0775
		directory mask = 0775
		valid users = %S$([ ! -z "$dirgrp01" ] && echo ", @$dirgrp01")$([ ! -z "$dirgrp02" ] && echo ", @$dirgrp02")$([ ! -z "$dirgrp03" ] && echo ", @$dirgrp03")$([ ! -z "$dirgrp04" ] && echo ", @$dirgrp04")$([ ! -z "$dirgrp05" ] && echo ", @$dirgrp05")$([ ! -z "$dirgrp06" ] && echo ", @$dirgrp06")
	EOF"
  else
	info "${dir01} does not exist: skipping."
	echo
  fi
done < pve_zfs_nas_base_folder_setup-samba_dir # file listing of folders to create
service smbd start 2>/dev/null # Restart Samba
systemctl is-active smbd >/dev/null 2>&1 && info "Samba server status: ${GREEN}active (running).${NC}" || info "Samba server status: ${RED}inactive (dead).${NC} Your intervention is required."
echo


#### Install and Configure NFS ####
section "$SECTION_HEAD - Installing and configuring NFS Server."

# Create NFS Shares
# Edit Exports
msg "Modifying $HOSTNAME /etc/exports file..."
if [ "$XTRA_SHARES" = 0 ]; then
	echo
	box_out '#### PLEASE READ CAREFULLY - ADDITIONAL NFS SHARED FOLDERS ####' '' 'In a previous step you created extra custom shared folders.' '' 'You can now choose which custom folders are to be included as NFS shares.'
	echo
	read -p "Create NFS shares for your custom shared folders [y/n]? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    NFS_XTRA_SHARES=0 >/dev/null
  else
    NFS_XTRA_SHARES=1 >/dev/null
    info "Your custom shared folders will not be available as NFS shares (default shared folders only) ..."
    echo
  fi
	echo
else
  NFS_XTRA_SHARES=1 >/dev/null
fi

if [ "$NFS_XTRA_SHARES" = 0 ] && [ "$XTRA_SHARES" = 0 ]; then
  set +u
  msg "Please select which custom folders are to be included as NFS shares."
  menu() {
    echo "Available options:"
    for i in ${!options[@]}; do 
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    if [[ "$msg" ]]; then echo "$msg"; fi
  }
  cat pve_zfs_nas_base_folder_setup-xtra | awk '{ print $1,$2 }' | sed -e 's/^/"/g' -e 's/$/"/g' | tr '\n' ' ' | sed -e 's/^\|$//g' | sed 's/\s*$//' > pve_zfs_nas_base_folder_setup-xtra_options
  mapfile -t options < pve_zfs_nas_base_folder_setup-xtra_options
  prompt="Check an option (again to uncheck, ENTER when done): "
  while menu && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] &&
    (( num > 0 && num <= ${#options[@]} )) ||
    { msg="Invalid option: $num"; continue; }
    ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
  done
  echo
  printf "You selected:\n"; msg=" nothing"
  for i in ${!options[@]}; do 
    [[ "${choices[i]}" ]] && { printf " %s" "${options[i]}"; msg=""; } && echo $({ printf " %s" "${options[i]}"; msg=""; }) | sed 's/\"//g' >> included_nfs_xtra_folders
  done
  echo
  set -u
else
  touch included_nfs_xtra_folders
fi
echo

# Create Input lists to create NFS Exports
grep -v -Ff included_nfs_xtra_folders pve_zfs_nas_base_folder_setup-xtra > excluded_nfs_xtra_folders # all rejected NFS additional folders
cat included_nfs_xtra_folders | sed '/medialab/!d' > included_nfs_folders-media_dir # included additional medialab NFS folders
cat included_nfs_xtra_folders | sed '/medialab/d' > included_nfs_folders-default_dir # included additional default NFS folders

# Create Default NFS export option
while IFS= read -r line
do
  echo "$line(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)" >> nfs_export_options_default_var01
done <<< $(cat pve_ip_list | sed 's/\/24//')
cat nfs_export_options_default_var01 | sort  | tr '\n' ' ' | sed 's/ *$//' > nfs_export_options_default

# Create Media NFS export option
while IFS= read -r line
do
  echo "$line(rw,async,no_wdelay,crossmnt,insecure,all_squash,insecure_locks,sec=sys,anonuid=1024,anongid=100)" > nfs_export_options_media_var01
done <<< $(cat pve_ip_list | awk -F'.' '{print $1"."$2".""50"".0/24"}' | awk '! a[$0]++')
cat nfs_export_options_default_var01 nfs_export_options_media_var01 | sort  | tr '\n' ' ' | sed 's/ *$//' > nfs_export_options_media

# Create Default NFS exports
grep -vxFf excluded_nfs_xtra_folders pve_zfs_nas_base_folder_setup | sed '$r included_nfs_folders-default_dir' | sed '/git/d;/homes/d;/openvpn/d;/sshkey/d' | sed '/audio/d;/books/d;/music/d;/photo/d;/video/d' | awk '{ print $1 }' | sed '/^#/d' | sed '/^$/d' > pve_zfs_nas_base_folder_setup-nfs_default_dir
schemaExtractDir="$BASE_FOLDER_VAR"
while read dir; do
  dir01="$schemaExtractDir/$dir"
  if [ -d "$dir01" ]; then
	eval "cat <<-EOF >> /etc/exports

	# $dir export
	$BASE_FOLDER_VAR/$dir $(cat nfs_export_options_default)
	EOF"
  else
	info "${dir01} does not exist: skipping..."
	echo
  fi
done < pve_zfs_nas_base_folder_setup-nfs_default_dir # file listing of folders to create
# Create Media NFS exports
cat pve_zfs_nas_base_folder_setup | grep -i 'audio\|books\|music\|photo\|\video' | sed '$r included_nfs_folders-media_dir' | awk '{ print $1 }' | sed '/^#/d' | sed '/^$/d' > pve_zfs_nas_base_folder_setup-nfs_media_dir 
schemaExtractDir="$BASE_FOLDER_VAR"
while read dir; do
  dir01="$schemaExtractDir/$dir"
  if [ -d "$dir01" ]; then
	eval "cat <<-EOF >> /etc/exports

	# $dir export
	$BASE_FOLDER_VAR/$dir $(cat nfs_export_options_media)
	EOF"
  else
	info "${dir01} does not exist: skipping..."
	echo
  fi
done < pve_zfs_nas_base_folder_setup-nfs_media_dir # file listing of folders to create


# NFS Server Restart
msg "Restarting NFS Server..."
service nfs-kernel-server restart 2>/dev/null
if [ "$(systemctl is-active --quiet nfs-kernel-server; echo $?) -eq 0" ]; then
	info "NFS Server status: ${GREEN}active (running).${NC}"
	echo
elif [ "$(systemctl is-active --quiet nfs-kernel-server; echo $?) -eq 3" ]; then
	info "NFS Server status: ${RED}inactive (dead).${NC}. Your intervention is required."
	echo
fi


#### Finish ####
section "$SECTION_HEAD - Completion Status."

echo
msg "${WHITE}Success.${NC}"
sleep 3

# Cleanup
cleanup