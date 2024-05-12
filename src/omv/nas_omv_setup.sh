#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     nas_omv_setup.sh
# Description:  Setup script for OMV NAS (full build setup)
#
# Usage:        Use from 'nas-hardmetal_installer.sh'
#               Run anytime to fix share permissions.
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check OMV version
majorversion=$(dpkg -l | grep -i "openmediavault -" | awk {'print $3'} | cut -d '.' -f1)
omv_min=6
if ! [[ $(dpkg -l | grep -w openmediavault) ]]; then
  echo "There are problems with this installation:

    --  Wrong Hardware. This setup script is for a OpenMediaVault (OMV).
  
  Bye..."
  sleep 2
  return
elif [[ $(dpkg -l | grep -w openmediavault) ]] && [ ! "$majorversion" -ge $omv_min ] || [[ ! $(id -u) ]]; then
  echo "There are problems with this installation:

  $(if [ ! "$majorversion" -ge $omv_min ]; then echo "  --  Wrong OMV OS version. This setup script is for a OMV Version $omv_min or later. Try upgrading your OMV OS."; fi)
  $(if [[ ! $(id -u) ]]; then echo "  --  This script must be run under User 'root'."; fi)

  Fix the issues and try again. Bye..."
  return
fi

# Check OMV availaible FS storage
if [ "$(xmlstarlet sel -t -m "//config/system/fstab/mntent" -v dir -nl /etc/openmediavault/config.xml | wc -l)" = 0 ]; then
  echo "There are problems with this installation:
  
  --  The installer could not identify a OMV file system for creating NAS storage.
  --  Use the OMV WebGUI 'Storage' > 'File Systems' and create a file system.
  
  Fix the issues and try again. Bye..."
  sleep 2
  echo
  return
fi

# Install chattr
if [ $(chattr --help &> /dev/null; echo $?) != 1 ]; then
 apt-get install e2fsprogs -y
fi

# Install nslookup
if [[ ! $(dpkg -s dnsutils 2> /dev/null) ]]; then
  apt-get install dnsutils -y
fi


#---- Static Variables -------------------------------------------------------------

# # Regex checks
# ip4_regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
# ip6_regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
# hostname_regex='^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$'
# domain_regex='^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$'
# R_NUM='^[0-9]+$' # Check numerals only
# pve_hostname_regex='^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[0-9])$'

# OMV config file
OMV_CONFIG='/etc/openmediavault/config.xml'

# Base dir permissions (ie 0750 or 0755)
DIR_PERM='0755'

# Set PVE primary host IP and hostname
if [ "$(nslookup -timeout=5 pve-01.$(hostname -d) >/dev/null 2>&1; echo $?)" = 0 ]; then
  PVE_HOSTNAME='pve-01'
  PVE_HOST_IP="$(nslookup -timeout=5 pve-01.$(hostname -d) | awk '/^Address: / { print $2 }')"
else
  # Temporary PVE hostname & IP
  PVE_HOSTNAME=ignore
  PVE_HOST_IP=0.0.0.0
fi

#---- Other Variables --------------------------------------------------------------

# Easy Script Section Header Body Text
SECTION_HEAD='OMV NAS'

# No. of reserved PVE node IPs
PVE_HOST_NODE_CNT='5'

# NFS string and settings
NFS_STRING='subtree_check,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100'

# SMB settings
# Allowed hosts
HOSTS_ALLOW="127.0.0.1 $(hostname -I | cut -d"." -f1-3).0/24 $(hostname -I | cut -d"." -f1-2).20.0/24 $(hostname -I | cut -d"." -f1-2).30.0/24 $(hostname -I | cut -d"." -f1-2).40.0/24 $(hostname -I | cut -d"." -f1-2).50.0/24 $(hostname -I | cut -d"." -f1-2).60.0/24 $(hostname -I | cut -d"." -f1-2).80.0/24"

# Search domain (local domain)
searchdomain_LIST=()
while IFS= read -r line
do
  [[ "$line" =~ ^\#.*$ ]] && continue
  searchdomain_LIST+=( "$line" )
done << EOF
# Example
# local:Special use domain for LAN. Supports mDNS, zero-config devices.
local:Special use domain for LAN. Supports mDNS (Recommended)
home.arpa:Special use domain for home networks (Recommended)
lan:Common domain name for small networks
localdomain:Common domain name for small networks
other:Input your own registered or made-up domain name
EOF

#---- Other Files ------------------------------------------------------------------
#---- Functions --------------------------------------------------------------------

# Spinner takes the pid of the process as the first argument and
# string to display as second argument (default provided) and spins
# until the process completes.
spinner() {
    local PROC="$1"
    local str="${2:-Working...}"
    local delay="0.1"
    tput civis  # hide cursor
    while [ -d /proc/$PROC ]; do
        printf '\033[s\033[u[ / ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u[ — ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u[ \ ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u[ | ] %s\033[u' "$str"; sleep "$delay"
    done
    printf '\033[s\033[u%*s\033[u\033[0m' $((${#str}+6)) " "  # return to normal
    tput cnorm  # restore cursor
    return 0
}

#---- Body -------------------------------------------------------------------------

# #---- Run Bash Header
# source ${COMMON_PVE_SRC_DIR}/pvesource_bash_defaults.sh

#---- Prerequisites
section "Prerequisites"

# OMV Helper functions
source /usr/share/openmediavault/scripts/helper-functions

# Backup /etc/openmediavault/config.xml'
file_bak="config.xml_backup_$(date +%F_%R)"
cp "$OMV_CONFIG" /etc/openmediavault/$file_bak

# Install OMV-Extras
if [ ! "$(dpkg -s openmediavault-omvextrasorg >/dev/null 2>&1; echo $?)" = 0 ]; then
  msg "Installing OMV-Extras..."
  sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | sudo bash
fi

# OMV system edits
msg "Setting OMV timezone & community updates..."
TIME_ZONE=$(timedatectl | awk '/Time zone:/ {print $3}')

xmlstarlet edit -L \
  --update "//config/system/apt/distribution/partner" \
  --value '1' \
  --update "//config/system/time/timezone" \
  --value "${TIME_ZONE}" \
  ${OMV_CONFIG}
  
# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run apt & spinner $!
sudo omv-salt deploy run timezone & spinner $!

# Perform OMV update
msg "Performing OMV OS update ( be patient, might take a long, long time )..."
omv-upgrade

# Edit UID_MIN and UID_MAX in /etc/login.defs
msg "Increasing UID/GID to 70000..."
sed -i 's|^UID_MAX.*|UID_MAX                 70000|g' /etc/login.defs
sed -i 's|^GID_MAX.*|GID_MAX                 70000|g' /etc/login.defs

# Setup Skel
sudo mkdir -p /etc/skel/{audio,backup,books,documents,downloads,templates,video,music,photo,public,.ssh}


#---- Search Domain
# Check DNS Search domain setting compliance with Ahuacate default options
section "Validate OMV NAS Search Domain"
SEARCHDOMAIN=$(hostname -d)
display_msg="#### ABOUT SEARCH DOMAINS ####
A Search domain is also commonly known as the local domain. Search domain means the domain that will be automatically appended when you only use the hostname for a particular host or computer. Its used to resolve a devices hostname to its assigned IP address between computers. It is especially important in DHCP networks where hostnames are used for inter-machine communication (NFS, SMB and Applications like Sonarr, Radarr). Search Domain is NOT your DNS server IP address.

It is important all network devices are set with a identical Search Domain name. Most important are your routers, switches and DNS servers including PiHole. It's best to choose only top-level domain (spTLD) names for residential and small networks names because they cannot be resolved across the internet. Routers and DNS servers know, in theory, not to forward ARPA requests they do not understand onto the public internet. Choose one of our listed names for your whole LAN network Search Domain and you will not have any problems.

If you insist on using a made-up search domain name, then DNS requests may go unfulfilled by your router and forwarded onto global internet DNS root servers. This leaks information about your network such as device names.

Alternatively, you can use a registered domain name or subdomain if you know what you are doing.\n\nWe recommend you change your Search Domain setting '${SEARCHDOMAIN}' on all your network devices.

$(printf '%s\n' "${searchdomain_LIST[@]}" | grep -v 'other' | awk -F':' '{ print "  --  "$1 }')\n"
# Confirm Search Domain
msg "Checking NAS Search Domain name..."
if [[ $(printf '%s\n' "${searchdomain_LIST[@]}" | awk -F':' '{ print $1 }' | grep "^${SEARCHDOMAIN}$" >/dev/null 2>&1; echo $?) == '0' ]]; then
  info "NAS Search Domain is set: ${YELLOW}${SEARCHDOMAIN}${NC} ( unchanged )"
  echo
else
  warn "The NAS DNS Search Domain name '${SEARCHDOMAIN}' is non-standard."
  echo
  msg_box "$display_msg"
  echo
  while true; do
    read -p "Proceed with your NAS Search Domain '${SEARCHDOMAIN}' [y/n]?: " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        echo
        break
        ;;
      [Nn]*)
        msg "You have chosen not to proceed. Change your NAS DNS Search Domain using the NAS DNS Server application. Then re-run this script again. Exiting script..."
        echo
        return
        ;;
      *)
        warn "Error! Entry must be 'y' or 'n'. Try again..."
        echo
        ;;
    esac
  done
fi


#---- OMV Hostname
if [[ ! "$(hostname)" =~ ^.*([0-9])$ ]]; then
  section "Query Hostname"

  msg "You may want to change your NAS hostname from '$(hostname)' to 'nas-01' ( i.e when adding additional NAS appliances use hostnames nas-02/03/04/05 ). Conforming to our standard network NAS naming convention assists our scripts in automatically detecting and resolving storage variables and other scripted tasks.\n\nThe system will now scan the network in ascending order the availability of our standard NAS hostname names beginning with: 'nas-01'. You may choose to accept our suggested new hostname or not."
  echo
  while true
  do
    # Check for available hostname(s)
    i=1
    counter=1
    until [ $counter -eq 5 ]
    do
      if [ ! "$(ping -s 1 -c 2 nas-0${i} &> /dev/null; echo $?)" = 0 ]; then
        HOSTNAME_VAR=nas-0${i}
        msg "Checking hostname 'nas-0${i}'..."
        info "New hostname 'nas-0${i}' status: ${GREEN}available${NC}"
        echo
        break
      else
        msg "Checking hostname 'nas-0${i}' status: ${WHITE}in use${NC} ( not available )"
      fi
      ((i=i+1))
      ((counter++))
    done
    # Confirm new hostname
    while true
    do
      read -p "Change NAS hostname to '${HOSTNAME_VAR}' [y/n]? " -n 1 -r YN
      echo
      case $YN in
        [Yy]*)
          info "New hostname is set: ${YELLOW}$HOSTNAME_VAR${NC}"
          HOSTNAME_MOD=0
          echo
          break 2
          ;;
        [Nn]*)
          info "No problem. NAS hostname is unchanged."
          HOSTNAME_VAR="$(hostname)"
          HOSTNAME_MOD=1
          echo
          break 2
          ;;
        *)
          warn "Error! Entry must be 'y' or 'n'. Try again..."
          echo
          ;;
      esac
    done
  done
else
  HOSTNAME_VAR="$(hostname)"
  HOSTNAME_MOD=1
fi

#---- Validating your PVE hosts
source $COMMON_PVE_SRC_DIR/pvesource_identify_pvehosts.sh


#---- Identify storage pool
source $COMMON_DIR/nas/src/nas_identify_storagepath.sh
# Get DIR_MAIN_SCHEMA & DIR_FAST_SCHEMA volume OMV UUID
DIR_MAIN_SCHEMA_UUID=$(xmlstarlet sel -t -v "//config/system/fstab/mntent[./dir[contains(., \"${DIR_MAIN_SCHEMA}\")]]/uuid" -nl /etc/openmediavault/config.xml)
if [ "$DIR_MAIN_SCHEMA" == "$DIR_FAST_SCHEMA" ]; then
  # Set DIR_FAST_SCHEMA_UUID to DIR_MAIN_SCHEMA_UUID
  DIR_FAST_SCHEMA_UUID="$DIR_MAIN_SCHEMA_UUID"
else
  # Set DIR_FAST_SCHEMA_UUID
  DIR_FAST_SCHEMA_UUID=$(xmlstarlet sel -t -v "//config/system/fstab/mntent[./dir[contains(., \"${DIR_FAST_SCHEMA}\")]]/uuid" -nl /etc/openmediavault/config.xml)
fi

#---- Identify storage volume
source $COMMON_DIR/nas/src/nas_identify_volumedir.sh

#---- Create User & Group lists
# Group LIST
# 1=GRPNAME:2=GID:3=COMMENT
grp_LIST=( "medialab:65605:For media apps (Sonarr, Radar, Jellyfin etc)"
"homelab:65606:For smart home apps (CCTV, Home Assistant)"
"privatelab:65607:Power, trusted or admin User group"
"chrootjail:65608:Users are jailed to their home folder (General user group)"
"sftp-access:65609:sFTP access group (for sftp plugin)" )

# Username List
# 1=USERNAME:2=UID:3=HOMEDIR:4=GRP:5=ADD_GRP:6=SHELL:7=COMMENT
user_LIST=( "media:1605:$DIR_MAIN_SCHEMA/$VOLUME_MAIN_DIR/homes/media:medialab:users:/bin/bash:Member of medialab group only"
"home:1606:$DIR_MAIN_SCHEMA/$VOLUME_MAIN_DIR/homes/home:homelab:users,medialab:/bin/bash:Member of homelab group (+ medialab)"
"private:1607:$DIR_MAIN_SCHEMA/$VOLUME_MAIN_DIR/homes/private:privatelab:users,medialab,homelab:/bin/bash:Member of privatelab group (+ medialab,homelab)" )

#---- Start Build ------------------------------------------------------------------

#---- Create default base and sub folders
source $COMMON_DIR/nas/src/nas_basefoldersetup.sh


#---- Create OVM 'Shared Folders'
section "Create Storage Shares"
msg "Creating OVM shares..."

# Fail msg
FAIL_MSG="${RED}[WARNING]${NC}\nThere is a conflict with a existing OMV storage folder setting:

--  Share name: '${name}'
    $(if [ "${name}" = "${dir}" ]; then printf "Status: ${GREEN}ok${NC}"; else printf "Status: ${RED}fail${NC} (requires: '${dir}')"; fi)
--  File system: '${file_system}'
    $(if [ "${file_system}" = "${DIR_SCHEMA_UUID}" ]; then printf "Status: ${GREEN}ok${NC}"; else printf "Status: ${RED}fail${NC} (requires: '${DIR_SCHEMA_UUID}')"; fi)
--  Relative path: '${relative_path}'
    $(if [ "${relative_path}" = "${dir}/" ]; then printf "Status: ${GREEN}ok${NC}"; else printf "Status: ${RED}fail${NC} (requires: '${dir/}')"; fi)

Use the OMV WebGUI 'Storage' > 'Shared Folders' to:

--  Delete the conflicting Shared Folder '${name}'
--  Delete any associated SMB or NFS '${name}' share 

Fix the issues and try again. Bye..."

# Create 'MAIN VOLUME DIR' share
if [[ ! $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${VOLUME_MAIN_DIR}' and reldirpath='${VOLUME_MAIN_DIR}/' and mntentref='${DIR_MAIN_SCHEMA_UUID}']" -nl ${OMV_CONFIG}) ]]; then
  info "New OMV share folder created: ${WHITE}'${VOLUME_MAIN_DIR}'${NC}"

  # Create uuid
  SHARE_MAIN_UUID="$(omv_uuid)"

  # OMV shared folder template
  echo "<sharedfolder>
    <uuid>${SHARE_MAIN_UUID}</uuid>
    <name>${VOLUME_MAIN_DIR}</name>
    <comment>Main volume</comment>
    <mntentref>${DIR_MAIN_SCHEMA_UUID}</mntentref>
    <reldirpath>${VOLUME_MAIN_DIR}/</reldirpath>
    <privileges></privileges>
  </sharedfolder>" > ${DIR}/shares_sharedfolder.xml

  # Delete subnode if already exist
  xmlstarlet ed -L -d  "//config/system/shares/sharedfolder[name='$VOLUME_MAIN_DIR' and mntentref='$DIR_MAIN_SCHEMA_UUID']" ${OMV_CONFIG}

  #Adding a new subnode to certain nodes
  TMP_XML=$(mktemp)
  xmlstarlet edit --subnode "//config/system/shares" --type elem --name "sharedfolder" \
  -v "$(xmlstarlet sel -t -c '/sharedfolder/*' ${DIR}/shares_sharedfolder.xml)" ${OMV_CONFIG} \
  | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
  mv "$TMP_XML" ${OMV_CONFIG}
fi

# Create 'FAST VOLUME DIR' share

if [ "$DIR_MAIN_SCHEMA" == "$DIR_FAST_SCHEMA" ]; then
  # Set all fast args to main args
  DIR_FAST_SCHEMA_UUID="${DIR_MAIN_SCHEMA_UUID}"
  SHARE_FAST_UUID="${SHARE_MAIN_UUID}"
else
  # Create 'FAST VOLUME DIR' share
  if [[ ! $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${VOLUME_FAST_DIR}' and reldirpath='${VOLUME_FAST_DIR}/' and mntentref='${DIR_FAST_SCHEMA_UUID}']" -nl ${OMV_CONFIG}) ]]; then
    info "New OMV share folder created: ${WHITE}'${VOLUME_FAST_DIR}'${NC}"

    # Create uuid
    SHARE_FAST_UUID="$(omv_uuid)"

    # OMV shared folder template
    echo "<sharedfolder>
      <uuid>${SHARE_FAST_UUID}</uuid>
      <name>${VOLUME_FAST_DIR}</name>
      <comment>Fast volume</comment>
      <mntentref>${DIR_FAST_SCHEMA_UUID}</mntentref>
      <reldirpath>${VOLUME_FAST_DIR}/</reldirpath>
      <privileges></privileges>
    </sharedfolder>" > ${DIR}/shares_sharedfolder.xml

    # Delete subnode if already exist
    xmlstarlet ed -L -d  "//config/system/shares/sharedfolder[name='$VOLUME_FAST_DIR' and mntentref='$DIR_FAST_SCHEMA_UUID']" ${OMV_CONFIG}

    #Adding a new subnode to certain nodes
    TMP_XML=$(mktemp)
    xmlstarlet edit --subnode "//config/system/shares" --type elem --name "sharedfolder" \
    -v "$(xmlstarlet sel -t -c '/sharedfolder/*' ${DIR}/shares_sharedfolder.xml)" ${OMV_CONFIG} \
    | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
    mv "$TMP_XML" ${OMV_CONFIG}
  fi
fi


# Check OMV share and process
while IFS=',' read -r dir fast desc grp other
do
  # Check if storage volume option, main or fast, and set args accordingly
  if [ "$DIR_MAIN_SCHEMA" == "$DIR_FAST_SCHEMA" ]; then
    DIR_SCHEMA="$DIR_MAIN_SCHEMA" # Override 'fast' arg (fast not available)
    VOLUME_DIR="$VOLUME_MAIN_DIR" # Set to use 'main' volume
    DIR_SCHEMA_UUID="$DIR_MAIN_SCHEMA_UUID" # Set to use 'main' uuid
  else
    if [ "$fast" -eq 0 ]; then
      DIR_SCHEMA="$DIR_MAIN_SCHEMA" # Set to use 'main' dir schema
      VOLUME_DIR="$VOLUME_MAIN_DIR" # Set to use 'main' volume
      DIR_SCHEMA_UUID="$DIR_MAIN_SCHEMA_UUID" # Set to use 'main' uuid
    elif [ "$fast" -eq 1 ]; then
      DIR_SCHEMA="$DIR_FAST_SCHEMA" # Set to use 'fast' dir schema
      VOLUME_DIR="$VOLUME_FAST_DIR" # Set to use 'fast' volume
      DIR_SCHEMA_UUID="$DIR_FAST_SCHEMA_UUID" # Set to use 'fast' uuid
    fi
  fi

  if [[ $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}' and reldirpath='${VOLUME_DIR}/${dir}/' and not(mntentref='${DIR_SCHEMA_UUID}')]" -nl ${OMV_CONFIG}) ]]; then
    # Set fail msg vars
    name=${dir}
    relative_path="${VOLUME_DIR}/${dir}/"
    file_system=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}']/mntentref" -nl ${OMV_CONFIG})
    # Print fail msg
    msg "$FAIL_MSG"
  elif [[ $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}' and not (reldirpath='${VOLUME_DIR}/${dir}/')]" -nl ${OMV_CONFIG}) ]]; then
    # Set fail msg vars
    name=${dir}
    relative_path=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}']/reldirpath" -nl ${OMV_CONFIG})
    file_system=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}']/mntentref" -nl ${OMV_CONFIG})
    # Print fail msg
    msg "$FAIL_MSG"
  elif [[ $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[reldirpath='${VOLUME_DIR}/${dir}/' and not (name='${dir}')]" -nl ${OMV_CONFIG}) ]]; then
    # Set fail msg vars
    name=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[reldirpath='${VOLUME_DIR}/${dir}/']/name" -nl ${OMV_CONFIG})
    relative_path="${VOLUME_DIR}/${dir}/"
    file_system=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[reldirpath='${VOLUME_DIR}/${dir}/']/mntentref" -nl ${OMV_CONFIG})
    # Print fail msg
    msg "$FAIL_MSG"
  elif [[ $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}' and reldirpath='${VOLUME_DIR}/${dir}/' and mntentref='${DIR_SCHEMA_UUID}']" -nl ${OMV_CONFIG}) ]]; then
    # Existing OMV share
    info "Pre-existing OMV share folder: '${dir}' (no change)"
    # Update share comment
    xmlstarlet edit -L --update "//config/system/shares/sharedfolder[name='${dir}']/comment" --value "${desc}" ${OMV_CONFIG}
  elif [[ ! $(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='${dir}' and reldirpath='${VOLUME_DIR}/${dir}/' and mntentref='${DIR_SCHEMA_UUID}']" -nl ${OMV_CONFIG}) ]]; then
    # Create new share folder
    info "New OMV share folder created: ${WHITE}'${dir}'${NC}"
    # Create uuid
    SHARE_UUID="$(omv_uuid)"

    # OMV shared folder template
    echo "<sharedfolder>
      <uuid>${SHARE_UUID}</uuid>
      <name>${dir}</name>
      <comment>${desc}</comment>
      <mntentref>${DIR_SCHEMA_UUID}</mntentref>
      <reldirpath>${VOLUME_DIR}/${dir}/</reldirpath>
      <privileges></privileges>
    </sharedfolder>" > ${DIR}/shares_sharedfolder.xml

    # Delete subnode if already exist
    xmlstarlet ed -L -d  "//config/system/shares/sharedfolder[name='$dir' and mntentref='$DIR_SCHEMA_UUID']" ${OMV_CONFIG}

    #Adding a new subnode to certain nodes
    TMP_XML=$(mktemp)
    xmlstarlet edit --subnode "//config/system/shares" --type elem --name "sharedfolder" \
    -v "$(xmlstarlet sel -t -c '/sharedfolder/*' ${DIR}/shares_sharedfolder.xml)" ${OMV_CONFIG} \
    | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
    mv "$TMP_XML" ${OMV_CONFIG}
  fi
done <<< $( printf '%s\n' "${nas_basefolder_LIST[@]}" | sed "s|^${VOLUME_DIR}/||" )
echo

# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run fstab & spinner $!


#---- Create Groups
section "Create default User Groups"
msg "Creating default groups..."

while IFS=':' read -r grpname gid comment
do
  # Create new grp
  if [ ! "$(egrep -i "^$grpname" /etc/group >/dev/null; echo $?)" = 0 ]; then
    groupadd -g $gid $grpname > /dev/null
    info "Default group created: ${YELLOW}$grpname${NC}"
  else
    # Check GID of existing grp
    if [ ! $(getent group $grpname | cut -d: -f3) = "$gid" ]; then
      groupmod -g $gid $grpname
    fi
  fi

  # Create uuid
  GRP_UUID="$(omv_uuid)"

  # OMV user group template
  echo "<group>
    <uuid>${GRP_UUID}</uuid>
    <name>${grpname}</name>
    <comment>${comment}</comment>
  </group>" > ${DIR}/add_grp.xml

  # Delete user if already exist
  xmlstarlet ed -L -d  "//config/system/usermanagement/groups/group[name='$grpname']" ${OMV_CONFIG}

  #Adding a new subnode to certain nodes
  TMP_XML=$(mktemp)
  xmlstarlet edit --subnode "//config/system/usermanagement/groups" --type elem --name "group" \
  -v "$(xmlstarlet sel -t -c '/group/*' ${DIR}/add_grp.xml)" ${OMV_CONFIG} \
  | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
  mv "$TMP_XML" ${OMV_CONFIG}
done <<< $( printf '%s\n' "${grp_LIST[@]}" )


#---- Create Users
section "Create default Users"
msg "Creating default users..."

# Edit OMV Home Dir
HOMES_UUID=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='homes']/uuid" -nl /etc/openmediavault/config.xml)
xmlstarlet edit -L \
  --update "//config/system/usermanagement/homedirectory/enable" \
  --value '1' \
  --update "//config/system/usermanagement/homedirectory/sharedfolderref" \
  --value "${HOMES_UUID}" ${OMV_CONFIG}

while IFS=':' read -r username uid homedir grp add_grp shell comment
do
  # Create new user
  if [ "$(id -u {username} &>/dev/null; echo $?)" = 1 ]; then
    useradd -m -d ${homedir} -u ${uid} -g ${grp} -s ${shell} -c "${comment}" ${username}
    # Additional groups
    if [ -n "${add_grp}" ]; then
      usermod -a -G $add_grp $username
    fi
    info "Default user created: ${YELLOW}$username${NC}"
  else
    # Check UID of existing user
    if [ $(id -u testuser) = "${uid}" ]; then
      usermod -u ${uid} -g ${grp} -G ${add_grp} ${username}
    fi
  fi

  # Create uuid
  USER_UUID="$(omv_uuid)"

  # OMV user template
  echo "<user>
    <uuid>${USER_UUID}</uuid>
    <name>${username}</name>
    <email></email>
    <disallowusermod>1</disallowusermod>
    <sshpubkeys></sshpubkeys>
  </user>" > ${DIR}/add_user.xml

  # Delete user if already exist
  xmlstarlet ed -L -d  "//config/system/usermanagement/users/user[name='$username']" ${OMV_CONFIG}

  #Adding a new subnode to certain nodes
  TMP_XML=$(mktemp)
  xmlstarlet edit --subnode "//config/system/usermanagement/users" --type elem --name "user" \
  -v "$(xmlstarlet sel -t -c '/user/*' ${DIR}/add_user.xml)" ${OMV_CONFIG} \
  | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
  mv "$TMP_XML" ${OMV_CONFIG}
done <<< $( printf '%s\n' "${user_LIST[@]}" )


#---- Create OVM 'NFS Shares'
section "Create NFS Shares"
msg "Creating NFS shares..."

# Enabled NFS
xmlstarlet edit -L \
  --update "//config/services/nfs/enable" \
  --value '1' ${OMV_CONFIG}

# Create 'nas_nfsfolder_LIST' array
rm_match='^\#.*$|^\s*$|^git.*$|^homes.*$|^openvpn.*$|^sshkey.*$'
# 'nas_basefolder_LIST' array
nas_nfsfolder_LIST=()
while IFS= read -r line
do
  [[ "$line" =~ (${rm_match}) ]] || [[ ${nas_basefolder_extra_LIST[@]} =~ "$line" ]] && continue
  nas_nfsfolder_LIST+=( "$line" )
done <<< $( printf '%s\n' "${nas_basefolder_LIST[@]}" | sed "s|^${VOLUME_MAIN_DIR}/||" -e "s|^${VOLUME_FAST_DIR}/||" )

# Create NFS share
while IFS=',' read -r dir fast desc user grp other
do
  # Create new NFS share folder
  info "New OMV NFS share created: ${WHITE}'${dir}'${NC}"

  # Check if storage volume option, main or fast, and set args accordingly
  if [ "$DIR_MAIN_SCHEMA" == "$DIR_FAST_SCHEMA" ]; then
    DIR_SCHEMA="$DIR_MAIN_SCHEMA" # Override 'fast' arg (fast not available)
    VOLUME_DIR="$VOLUME_MAIN_DIR" # Set to use 'main' volume
  else
    if [ "$fast" -eq 0 ]; then
      DIR_SCHEMA="$DIR_MAIN_SCHEMA" # Set to use 'main' dir schema
      VOLUME_DIR="$VOLUME_MAIN_DIR" # Set to use 'main' volume
    elif [ "$fast" -eq 1 ]; then
      DIR_SCHEMA="$DIR_FAST_SCHEMA" # Set to use 'fast' dir schema
      VOLUME_DIR="$VOLUME_FAST_DIR" # Set to use 'fast' volume
    fi
  fi

  # Create uuid(s)
  MNTENT_UUID="$(omv_uuid)"
  NFS_SHARE_UUID="$(omv_uuid)"
  SHARE_FOLDERREF=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='$dir']/uuid" -nl /etc/openmediavault/config.xml)

  # OMV fstab mntent template
  echo "<mntent>
    <uuid>${MNTENT_UUID}</uuid>
    <fsname>${DIR_SCHEMA}/${VOLUME_DIR}/${dir}/</fsname>
    <dir>/export/${dir}</dir>
    <type>none</type>
    <opts>bind,nofail</opts>
    <freq>0</freq>
    <passno>0</passno>
    <hidden>0</hidden>
    <usagewarnthreshold>0</usagewarnthreshold>
    <comment></comment>
  </mntent>" > ${DIR}/fstab_mntent.xml

  # Delete subnode if already exist
  xmlstarlet ed -L -d  "//config/system/fstab/mntent[dir='/export/${dir}' and fsname='${DIR_SCHEMA}/${VOLUME_DIR}/${dir}/']" ${OMV_CONFIG}

  # Adding a new subnode to fstab mntent
  TMP_XML=$(mktemp)
  xmlstarlet edit --subnode "//config/system/fstab" --type elem --name "mntent" \
  -v "$(xmlstarlet sel -t -c '/mntent/*' ${DIR}/fstab_mntent.xml)" ${OMV_CONFIG} \
  | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
  mv "$TMP_XML" ${OMV_CONFIG}

  # Create NFS share template
  while IFS=',' read -r host_id host_ip other
  do
    # NFS client IP
    NFS_CLIENT="${host_ip}/32"

    # OMV nfs share template
    echo "<share>
      <uuid>${NFS_SHARE_UUID}</uuid>
      <sharedfolderref>${SHARE_FOLDERREF}</sharedfolderref>
      <mntentref>${MNTENT_UUID}</mntentref>
      <client>${NFS_CLIENT}</client>
      <options>rw</options>
      <comment>${desc}</comment>
      <extraoptions>${NFS_STRING}</extraoptions>
    </share>" > ${DIR}/nfs_share.xml

    # Delete subnode if already exist
    xmlstarlet ed -L -d  "//config/services/nfs/shares/share[sharedfolderref='${SHARE_FOLDERREF}' and client='${NFS_CLIENT}']" ${OMV_CONFIG}

    #Adding a new subnode to nfs share
    TMP_XML=$(mktemp)
    xmlstarlet edit --subnode "//config/services/nfs/shares" --type elem --name "share" \
    -v "$(xmlstarlet sel -t -c '/share/*' ${DIR}/nfs_share.xml)" ${OMV_CONFIG} \
    | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
    mv "$TMP_XML" ${OMV_CONFIG} 
  done <<< $( printf '%s\n' "${pve_node_LIST[@]}" )
done <<< $( printf '%s\n' "${nas_nfsfolder_LIST[@]}" )

# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
# omv-salt stage run deploy & spinner $!
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run fstab & spinner $!
sudo omv-salt deploy run nfs & spinner $!


#---- Setup OVM SMB Shares
section "Create SMB Shares"
msg "Creating SMB shares..."

# Create 'nas_smbfolder_LIST' array
rm_match='^\#.*$|^\s*$|^homes.*$'
# 'nas_basefolder_LIST' array
nas_smbfolder_LIST=()
while IFS= read -r line
do
  [[ "$line" =~ (${rm_match}) ]] || [[ ${nas_basefolder_extra_LIST[@]} =~ "$line" ]] && continue
  nas_smbfolder_LIST+=( "$line" )
done <<< $( printf '%s\n' "${nas_basefolder_LIST[@]}" | sed "s|^${VOLUME_MAIN_DIR}/||" -e "s|^${VOLUME_FAST_DIR}/||" )

# Configure SMB Global settings
xmlstarlet edit -L \
  --update "//config/services/smb/enable" \
  --value '1' \
  --update "//config/services/smb/usesendfile" \
  --value '1' \
  --update "//config/services/smb/aio" \
  --value '1' \
  --update "//config/services/smb/timeserver" \
  --value '0' \
  --update "//config/services/smb/homesenable" \
  --value '1' \
  --update "//config/services/smb/homesbrowseable" \
  --value '0' \
  --update "//config/services/smb/homesrecyclebin" \
  --value '1' \
  ${OMV_CONFIG}
# Global extra options
xmlstarlet edit -L \
  --update "//config/services/smb/extraoptions" \
  --value "map to guest = bad user
  usershare allow guests = yes
  inherit permissions = yes
  inherit acls = yes
  vfs objects = acl_xattr
  follow symlinks = yes
  hosts allow = ${HOSTS_ALLOW}
  hosts deny = 0.0.0.0/0
  min protocol = SMB2
  max protocol = SMB3" \
  ${OMV_CONFIG}

# Configure SMB shares (dirs)
while IFS=',' read -r dir fast desc user grp other
do
  # Create new NFS share folder
  info "New OMV SMB share created: ${WHITE}'${dir}'${NC}"

  # Create uuid
  SMB_UUID="$(omv_uuid)"

  # Get DIR_SCHEMA volume OMV UUID
  SHARE_FOLDERREF=$(xmlstarlet sel -t -v "//config/system/shares/sharedfolder[name='$dir']/uuid" -nl /etc/openmediavault/config.xml)
  [[ ${SHARE_FOLDERREF} == "" ]] && continue

  # SMB share vars
  if [ ${dir} == 'public' ]; then
    # SMB vars
    GUEST=allow
    ENABLE=1
    READONLY=0
    BROWSEABLE=1
    RECYCLEBIN=0
    BINMAXSIZE=0
    BINMAXAGE=0
    HIDEDOT=1
    INHERITACLS=1
    INHERITPERMISSIONS=1
    EASUPPORT=0
    STOREDOSATTRIBUTES=0
    HOSTSALLOW=""
    HOSTSDENY=""
    AUDIT=0
    TIMEMACHINE=0
    # SMB extra options
    EXTRAOPTIONS='create mask = 0664
    force create mode = 0664
    directory mask = 0775
    force directory mode = 0775'
  else
    # SMB vars (default all)
    GUEST=no
    ENABLE=1
    READONLY=0
    BROWSEABLE=1
    RECYCLEBIN=0
    BINMAXSIZE=0
    BINMAXAGE=0
    HIDEDOT=1
    INHERITACLS=1
    INHERITPERMISSIONS=1
    EASUPPORT=0
    STOREDOSATTRIBUTES=0
    HOSTSALLOW=""
    HOSTSDENY=""
    AUDIT=0
    TIMEMACHINE=0
    # SMB extra options
    EXTRAOPTIONS=""
  fi

  # OMV smb share template
  echo "<share>
    <uuid>${SMB_UUID}</uuid>
    <enable>${ENABLE}</enable>
    <sharedfolderref>${SHARE_FOLDERREF}</sharedfolderref>
    <comment>${desc}</comment>
    <guest>${GUEST}</guest>
    <readonly>${READONLY}</readonly>
    <browseable>${BROWSEABLE}</browseable>
    <recyclebin>${RECYCLEBIN}</recyclebin>
    <recyclemaxsize>${BINMAXSIZE}</recyclemaxsize>
    <recyclemaxage>${BINMAXAGE}</recyclemaxage>
    <hidedotfiles>${HIDEDOT}</hidedotfiles>
    <inheritacls>${INHERITACLS}</inheritacls>
    <inheritpermissions>${INHERITPERMISSIONS}</inheritpermissions>
    <easupport>${EASUPPORT}</easupport>
    <storedosattributes>${STOREDOSATTRIBUTES}</storedosattributes>
    <hostsallow>${HOSTSALLOW}</hostsallow>
    <hostsdeny>${HOSTSDENY}</hostsdeny>
    <audit>${AUDIT}</audit>
    <timemachine>${TIMEMACHINE}</timemachine>
    <extraoptions>${EXTRAOPTIONS}</extraoptions>
  </share>" > ${DIR}/smb_share.xml

  # Delete subnode if already exist
  xmlstarlet ed -L -d  "//config/services/smb/shares/share[sharedfolderref='${SHARE_FOLDERREF}']" ${OMV_CONFIG}

  #Adding a new subnode to smb share
  TMP_XML=$(mktemp)
  xmlstarlet edit --subnode "//config/services/smb/shares" --type elem --name "share" \
  -v "$(xmlstarlet sel -t -c '/share/*' ${DIR}/smb_share.xml)" ${OMV_CONFIG} \
  | xmlstarlet unesc | xmlstarlet fo > "$TMP_XML"
  mv "$TMP_XML" ${OMV_CONFIG}
done <<< $( printf '%s\n' "${nas_smbfolder_LIST[@]}" )

# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run samba & spinner $!

#---- SSH
section "SSH Setup"
msg "Editing SSH config..."

# Creating SSH extra options
xmlstarlet edit -L \
  --update "//config/services/ssh/extraoptions" \
  --value "# Settings for chrootjail
  Match Group chrootjail
    AuthorizedKeysFile /var/lib/openmediavault/ssh/authorized_keys/%u
    ChrootDirectory ${DIR_MAIN_SCHEMA}/homes/%u
    PubkeyAuthentication yes
    PasswordAuthentication no
    AllowTCPForwarding no
    X11Forwarding no
    ForceCommand internal-sftp" \
  ${OMV_CONFIG}

# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run ssh & spinner $!

#---- Fail2ban

# Fail2ban plugin
if [ "$(dpkg -s openmediavault-fail2ban >/dev/null 2>&1; echo $?)" != 0 ]; then
  msg "Installing fail2ban plugin..."
  apt-get install openmediavault-fail2ban -y
fi

# Configure Fail2ban settings
xmlstarlet edit -L \
  --update "//config/services/fail2ban/enable" \
  --value '1' \
  ${OMV_CONFIG}

# Stage config edit
msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
sudo omv-salt stage run prepare & spinner $!
sudo omv-salt deploy run fail2ban & spinner $!


#---- Other OMV Plug-ins
section "Install OMV Plugins"

msg "Installing OMV plugins..."
# Required PVESM Storage Mounts for CT ( new version )
plugin_LIST=()
while IFS= read -r line
do
  [[ "$line" =~ ^\#.*$ ]] && continue
  plugin_LIST+=( "$line" )
done << EOF
# Example
# name:description
openmediavault-usbbackup:usb backup
openmediavault-remotemount:remote mount
EOF

# Check plugin status
while IFS=':' read -r plugin desc
do
  if [[ ! $(dpkg -s $plugin 2>/dev/null) ]]; then
    apt-get install $plugin -y
    info "OMV $desc plugin status: ${WHITE}installed${NC}"
  else
    info "OMV $desc plugin status: existing (already installed)"
  fi
done < <( printf '%s\n' "${plugin_LIST[@]}" )
echo


#---- Other OMV mods

#---- Set Hostname
if [ "$HOSTNAME_MOD" = 0 ]; then
  section "Modify OMV Hostname"

  # Change hostname
  xmlstarlet edit -L \
  --update "//config/system/network/dns/hostname" \
  --value "${HOSTNAME_VAR}" \
  ${OMV_CONFIG}

  # Stage config edit
  msg "Deploying 'omv-salt' config ( be patient, might take a long, long time )..."
  sudo omv-salt stage run prepare & spinner $!
  sudo omv-salt deploy run hostname & spinner $!
  echo
fi

#---- Finish Line ------------------------------------------------------------------

section "Completion Status"

# Interface
interface=$(ip route ls | grep default | grep -Po '(?<=dev )(\S+)')
# Get IP type (ip -4 addr show eth0)
if [ "$(ip addr show ${interface} | grep -q dynamic > /dev/null; echo $?)" = 0 ]; then 
  ip_type='dhcp - best use dhcp IP reservation'
else
  ip_type='static IP'
fi

#---- Set display text
# Webmin access URL
display_msg1=( "http://$(hostname).$(hostname -d)" )
display_msg1+=( "http://$(hostname -I | sed 's/\s.*$//') (${ip_type})" )
display_msg1+=( "Username: admin" )
display_msg1+=( "Password: openmediavault" )

# User Management
display_msg2=( "medialab - GUID 65605:For media Apps (Sonarr, Radar, Jellyfin etc)" )
display_msg2+=( "homelab - GUID 65606:For Smart Home (CCTV, Home Assistant)" )
display_msg2+=( "privatelab - GUID 65607:Power, trusted and admin Users" )
display_msg2+=( "chrootjail - GUID 65608:Users are restricted to their home folder" )
                                  
display_msg3=( "media - UID 1605:Member of medialab" )
display_msg3+=( "home - UID 1606:Member of homelab. Supplementary medialab" )
display_msg3+=( "private - UID 1607:Member of privatelab. Supplementary medialab, homelab" )

# File server login
x='\\\\'
display_msg4=( "$x$(hostname -I | sed 's/\s.*$//')\:" )
display_msg4+=( "$x$(hostname).$(hostname -d)\:" )

# Display msg
msg_box "${HOSTNAME^^} OMV NAS setup was a success. Your NAS is fully configured and is ready to provide NFS and/or SMB/CIFS backend storage mounts to your PVE hosts.

OMV NAS has a WebGUI management interface. Your login credentials are user 'admin' and password 'openmediavault'. You can change your login credentials using the WebGUI.

$(printf '%s\n' "${display_msg1[@]}" | indent2)

The NAS is installed with Ahuacate default Linux User accounts, Groups and file sharing permission. These new Users and Groups are a required by our PVE containers (Sonarr, Radarr etc). We recommend the User uses our preset NAS Groups for new user management.

$(printf '%s\n' "${display_msg2[@]}" | column -s ":" -t -N "GROUP NAME,DESCRIPTION" | indent2)

$(printf '%s\n' "${display_msg3[@]}" | column -s ":" -t -N "APP USER ACC ONLY,DESCRIPTION" | indent2)

To access ${HOSTNAME^^} files use SMB.

$(printf '%s\n' "${display_msg4[@]}" | column -s ":" -t -N "SMB NETWORK ADDRESS" | indent2)

NFSv4 is enabled and ready for creating PVE host storage mounts.

A backup file of your OMV configuration (pre-modification) is available here:
$(echo "/etc/${file_bak}" | indent2)

We recommend you now reboot your OMV NAS."
#-----------------------------------------------------------------------------------