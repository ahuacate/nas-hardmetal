#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     synology_nas_setup.sh
# Description:  Setup script to build a Synology DiskStation NAS
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
COMMON_PVE_SOURCE="${DIR}/../../../../common/pve/source"

#---- Dependencies -----------------------------------------------------------------

# Check for Internet connectivity
if nc -zw1 google.com 443; then
  echo
else
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your PVE hosts internet connection and try again..."
  echo
  exit 0
fi

# Run Bash Header
source ${COMMON_PVE_SOURCE}/pvesource_bash_defaults.sh

# Check for a Synology OS
if [ ! $(uname -a | grep -i --color=never '.*linux.*' &> /dev/null; echo $?) == 0 ]; then
  warn "There are problems with this installation:

    --  Wrong Hardware. This setup script is for Linux hardware only ( i.e Ubuntu ).
  
  Bye..."
  return 0
# Check for a Synology OS
elif [ $(uname -a | grep -i --color=never '.*linux.*' &> /dev/null; echo $?) == 0 ] && [ $(uname -a | grep -i --color=never '.*synology*\|.*pve*' &> /dev/null; echo $?) == 0 ] || [ ! $(id -u) == 0 ]; then
  warn "There are problems with this installation:

  $(if [ $(uname -a | grep -i --color=never '.*synology*\|.*pve*' &> /dev/null; echo $?) == 0 ]; then echo "  --  Wrong Linux hardware. This setup script is for hard metal Linux debian based appliance NOT a Synology, Proxmox host or any other OEM brand NAS"; fi)
  $(if [ ! $(id -u) == 0 ]; then echo "  --  This script must be run under User 'root'."; fi)

  Fix the issues and try again. Bye..."
  return 0
fi

# Check for ACL installation
if [ $(dpkg -s acl > /dev/null 2>&1; echo $?) != 0 ]; then
  msg "Installing ACL..."
  apt-get install -y acl > /dev/null
fi

# Check for Putty tools
if [ $(dpkg -s putty-tools > /dev/null 2>&1; echo $?) != 0 ]; then
  msg "Installing Putty Tools..."
  apt-get install -y putty-tools > /dev/null
fi

# Check for SMB
if [ $(dpkg -s samba > /dev/null 2>&1; echo $?) != 0 ]; then
  msg "Installing Samba..."
  apt-get install -y samba-common-bin samba > /dev/null
fi

# Check for NFS
if [ $(dpkg -s nfs-kernel-server > /dev/null 2>&1; echo $?) != 0 ]; then
  msg "Installing NFS..."
  apt-get install -y nfs-kernel-server > /dev/null
fi

# Check for chattr
if [ ! $(chattr --help &> /dev/null; echo $?) == 1 ]; then
  msg "Installing Chattr..."
  apt-get -y install e2fsprogs
fi

# Check for User & Group conflict
unset USER_ARRAY
USER_ARRAY+=( "media medialab 1605 65605" "home homelab 1606 65606" "private privatelab 1607 65607" )
while read USER GROUP UUID GUID; do
  # Check for Group conflict
  if [ ! $(egrep -i "^${GROUP}" /etc/group >/dev/null; echo $?) == 0 ] && [ $(awk -F':' '{print $3}' /etc/group | grep "${GUID}" &> /dev/null; echo $?) == 0 ]; then
    GUID_CONFLICT=$(awk 'BEGIN{FS=OFS=":"} {print $1,$3}' /etc/group | grep -i --color=never "${GUID}$" | awk -F':' '{print $1}')
    msg "${RED}[WARNING]${NC}\nThere are issues with this NAS:
    
    1. The Group GUID $GUID is in use by another NAS group named: ${GUID_CONFLICT^}. GUID $GUID must be available for the new group ${GROUP^}.
    2. The User must fix this issue before proceeding by assigning a different GUID to the conflicting group '${GUID_CONFLICT^}' or by deleting group '${GUID_CONFLICT^}'.
    
    Exiting script. Fix the issue and try again..."
    echo
    return
  fi
  # Check for User conflict
  if [ ! $(id ${USER} &> /dev/null; echo $?) == 0 ] && [ $(id -u $UUID &> /dev/null; echo $?) == 0 ]; then
    UUID_CONFLICT=$(id -nu $UUID)
    msg "${RED}[WARNING]${NC}\nThere are issues with this NAS:
    
    1. The User UUID $UUID is in use by another NAS user named: ${UUID_CONFLICT^}. UUID $UUID must be available for the new user ${USER^}.
    2. The User must fix this issue before proceeding by assigning a different UUID to the conflicting user '${UUID_CONFLICT^}' or by deleting Synology user '${UUID_CONFLICT^}'.
    
    Exiting script. Fix the issue and try again..."
    echo
    return
  fi
done  < <( printf '%s\n' "${USER_ARRAY[@]}" )

#---- Static Variables -------------------------------------------------------------

# Easy Script Section Header Body Text
SECTION_HEAD='Linux NAS'

# No. of reserved PVE node IPs
PVE_HOST_NODE_CNT='5'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------

# Copy source files
sed -i 's/65605/medialab/g' pve_nas_basefolderlist # Edit GUID to Group name
sed -i 's/65606/homelab/g' pve_nas_basefolderlist # Edit GUID to Group name
sed -i 's/65607/privatelab/g' pve_nas_basefolderlist # Edit GUID to Group name
sed -i 's/65608/chrootjail/g' pve_nas_basefolderlist # Edit GUID to Group name
sed -i 's/65605/medialab/g' pve_nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65606/homelab/g' pve_nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65607/privatelab/g' pve_nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65608/chrootjail/g' pve_nas_basefoldersubfolderlist # Edit GUID to Group name

#---- Body -------------------------------------------------------------------------

#---- Prerequisites
section "Introduction"

msg_box "#### PLEASE READ CAREFULLY ####\n
This script will setup your Linux NAS to support Proxmox CIFS or NFS backend storage pools. Tasks performed include:

  -- User Groups ( create: medialab, homelab, privatelab, chrootjail )
  -- Users ( create: media, home, private - default CT App user accounts )
  -- Create all required shared folders required by Ahuacate CTs & VMs
  -- Create all required sub-folders
  -- Set new folder share permissions, chattr and ACLs ( Users and Group rights )
  -- Create NFS exports to Proxmox primary and secondary host nodes
  -- Enable NFS 4.1 and NFS Unix permissions
  -- Enable SMB with 'min protocol=SMB2' & 'max protocol=SMB3'

After running this script a fully compatible suite of Synology NAS folder shares and sub-folders will be created. Proxmox can then add storage by creating a CIFS or NFS backend storage pool to your NAS exported mount points ( we recommend NFS ). 

User input is required in the next steps. This script will not delete any existing NAS folders or files but may modify file access permissions on existing shared folders. It is recommended you have a NAS file and settings backup before proceeding."
echo
echo
while true; do
  read -p "Proceed with your NAS setup [y/n]?: " -n 1 -r YN
  echo
  case $YN in
    [Yy]*)
      echo
      break
      ;;
    [Nn]*)
      msg "You have chosen not to proceed. Exiting script..."
      echo
      return 0
      ;;
    *)
      warn "Error! Entry must be 'y' or 'n'. Try again..."
      echo
      ;;
  esac
done

#---- Confirm NAS IP address
section "Confirm NAS IP address"

msg "Confirming NAS IP..."
NAS_IP=$(hostname -i)
PVE_HOST_IP=$(echo ${NAS_IP} | awk -F'.' 'BEGIN { OFS = "." } { print $1,$2,$3,"101" }')
i=$(( $(echo ${PVE_HOST_IP} | cut -d . -f 4) + 1 ))
k=2
if [[ "${NAS_IP}" == *10.0.1.* || "${NAS_IP}" == *192.168.1.* ]] && [[ ! "${NAS_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.(101|102|103|104|105)$ ]]; then
  info "Our recommended PVE node cluster using your NAS IP address '${NAS_IP}' would be (note the ascending IP addresses):\n\n  -- pve-01  ${PVE_HOST_IP} ( Primary host )\n$(until [ ${i} = $(( $(echo ${PVE_HOST_IP} | cut -d . -f 4) + ${PVE_HOST_NODE_CNT} )) ]; do echo "  -- pve-0${k}  $(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i} ( Secondary host )";  ((i=i+1)); ((k=k+1)); done)\n\nWe recommend you reserve the above ${PVE_HOST_NODE_CNT}x IP addresses for your PVE nodes ( cluster )."
  echo
elif [[ "${NAS_IP}" == *10.0.1.* || "${NAS_IP}" == *192.168.1.* ]] && [[ "${NAS_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.(101|102|103|104|105)$ ]]; then
  warn "#### PLEASE READ CAREFULLY - IP Conflict? ####"
  msg "Your NAS IP address '${NAS_IP}' meets our scripts network prefix standards BUT there is a 'potential' IP conflict. The last IP octet of your Synology NAS conflicts with our recommended standard PVE node cluster IP addresses. A typical PVE node cluster using your NAS IP network prefix would be ( note the ascending IP addresses ):\n\n  -- pve-01  ${PVE_HOST_IP} ( Primary host )\n$(until [ ${i} = $(( $(echo ${PVE_HOST_IP} | cut -d . -f 4) + ${PVE_HOST_NODE_CNT} )) ]; do echo "  -- pve-0${k}  $(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i} ( Secondary host ) $(if [ "${NAS_IP}" == "$(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i}" ]; then echo "<< ${RED}IP conflict${NC}"; fi)";  ((i=i+1)); ((k=k+1)); done)\n\nWe RECOMMEND the User changes the NAS IP to '$(echo ${NAS_IP} | awk -F'.' 'BEGIN { OFS = "." } { print $1,$2,$3,"10" }')' and try running this configuration script again. Or continue with caution when inputting your Proxmox host IP addresses in the next steps to avoid IP conflicts."
  echo
  while true; do
    read -p "Accept NAS IP '${WHITE}${NAS_IP}${NC}' [y/n]? " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        info "NAS IP status: ${YELLOW}accepted${NC}"
        echo
        break
        ;;
      [Nn]*)
        msg "No problem. Change your NAS IP and try again. Bye..."
        echo
        return
        ;;
      *)
        warn "Error! Entry must be 'y' or 'n'. Try again..."
        echo
        ;;
    esac
  done
elif [[ ! "${NAS_IP}" == *10.0.0.* || ! "${NAS_IP}" == *192.168.1.* ]] && [[ ! "${NAS_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.(101|102|103|104|105)$ ]]; then
  msg "Your NAS IP address '${NAS_IP}' is non-standard but is acceptable. A typical PVE node cluster using your NAS IP network prefix would be ( note the ascending IP addresses ):\n\n  -- pve-01  ${PVE_HOST_IP} ( Primary host )\n$(until [ ${i} = $(( $(echo ${PVE_HOST_IP} | cut -d . -f 4) + ${PVE_HOST_NODE_CNT} )) ]; do echo "  -- pve-0${k}  $(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i} ( Secondary host ) $(if [ "${NAS_IP}" == "$(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i}" ]; then echo "<< ${RED}IP conflict${NC}"; fi)";  ((i=i+1)); ((k=k+1)); done)\n\nWe recommend you reserve the above ${PVE_HOST_NODE_CNT}x IP addresses for your PVE nodes ( cluster )."
  echo
fi


#---- Input PVE-01 IP address
section "Input Proxmox primary host IP address"

# Checking PVE-01 host IP address
msg "The User must input the IPv4 address of your Proxmox PVE primary host ( pve-01 ). If the User has not installed their Proxmox primary host then we suggest pve-01 IP address would be '${PVE_HOST_IP}' but yours may be different."
while true; do
  read -p "Enter your Proxmox PVE primary host (pve-01) IPv4 address: " -e -i ${PVE_HOST_IP} PVE_01_IP
  msg "Performing checks on your input ( be patient, may take a while )..."
  if [ ! $(valid_ip ${PVE_01_IP} > /dev/null; echo $?) == 0 ]; then
    warn "There are problems with your input:
    
    1. The IP address is incorrectly formatted. It must be in the IPv4 format, quad-dotted octet format (i.e xxx.xxx.xxx.xxx ).
    
    Try again..."
    echo
  elif [ $(valid_ip ${PVE_01_IP} > /dev/null; echo $?) == 0 ] && [ $(ping -s 1 -c 2 ${PVE_01_IP} > /dev/null; echo $?) != 0 ]; then
    warn "There are problems with your input:
    
    1. The IP address meets the IPv4 standard.
    2. The PVE host IP address '${PVE_01_IP}' is not reachable ( maybe offline? )."
    echo
    while true; do
      read -p "Accept PVE primary host ( pve-01 ) IPv4 address ${WHITE}${PVE_01_IP}${NC} anyway [y/n]? " -n 1 -r YN
      echo
      case $YN in
        [Yy]*)
          info "PVE primary host ( pve-01 ) node IPv4 address is set: ${YELLOW}${PVE_01_IP}${NC}"
          echo
          msg "Setting your PVE host nodes IPv4 addresses as shown:"
          echo
          msg "  -- pve-01  ${PVE_01_IP} ( Primary host )"
          i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4) + 1 ))
          k=2
          j=2
          counter=1
          until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
          do
            msg "  -- pve-0${k}  $(echo ${PVE_01_IP} | cut -d"." -f1-3).${i} ( Secondary host )"
            # export "PVE_0${j}_IP=$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
            ((i=i+1))
            ((k=k+1))
            ((j=j+1))
            ((counter++))
          done
          echo
          break 2
          ;;
        [Nn]*)
          msg "No problem. Try again..."
          echo
          break
          ;;
        *)
          warn "Error! Entry must be 'y' or 'n'. Try again..."
          echo
          ;;
      esac
    done
    echo
  elif [ $(valid_ip ${PVE_01_IP} > /dev/null; echo $?) == 0 ] && [ $(ping -s 1 -c 2 ${PVE_01_IP} > /dev/null; echo $?) = 0 ]; then
    info "Your input appears okay:\n\n  1. The IP address meets the IPv4 standard.\n  2. The PVE host IP address '${PVE_01_IP}' is reachable.\n\nSetting your PVE host nodes IPv4 addresses as shown:"
    echo
    msg "  -- pve-01  ${PVE_01_IP} ( Primary host )"
    i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4) + 1 ))
    k=2
    j=2
    counter=1
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      msg "  -- pve-0${k}  $(echo ${PVE_01_IP} | cut -d"." -f1-3).${i} ( Secondary host )"
      # export "PVE_0${j}_IP=$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
      ((i=i+1))
      ((k=k+1))
      ((j=j+1))
      ((counter++))
    done
    echo
    while true; do
      read -p "Accept PVE primary host (pve-01) IPv4 address ${WHITE}${PVE_01_IP}${NC} [y/n]? " -n 1 -r YN
      echo
      case $YN in
        [Yy]*)
          info "PVE primary host ( pve-01 ) node IPv4 address is set: ${YELLOW}${PVE_01_IP}${NC}"
          echo
          break 2
          ;;
        [Nn]*)
          msg "No problem. Try again ..."
          echo
          break
          ;;
        *)
          warn "Error! Entry must be 'y' or 'n'. Try again..."
          echo
          ;;
      esac
    done
  fi
done

#---- Synology Hostname
if [[ ! "$(synonet --get_hostname)" =~ ^nas-0([0-9])$ ]]; then
  section "Query Hostname"

  msg "You may want to change your Synology NAS hostname from '$(synonet --get_hostname)' to 'nas-01' (i.e nas-02/03/04/05 ). Conforming to our standard network NAS naming convention assists our scripts in automatically detecting and resolving storage variables and other scripted tasks.\n\nThe system will now scan the network in ascending order the availability of our standard NAS hostname names beginning with: 'nas-01'. You may choose to accept our suggested new hostname or not."
  echo
  while true; do
    # Check for available hostname(s)
    i=1
    counter=1
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      if [ ! $(ping -s 1 -c 2 nas-0${i} &> /dev/null; echo $?) = 0 ]; then
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
    while true; do
      read -p "Change Synology NAS hostname to '${HOSTNAME_VAR}' [y/n]? " -n 1 -r YN
      echo
      case $YN in
        [Yy]*)
          info "New Synology hostname is set: ${YELLOW}${HOSTNAME_VAR}${NC}"
          SYNO_HOSTNAME_MOD=0
          echo
          break 2
          ;;
        [Nn]*)
          info "No problem. Synology hostname is unchanged."
          HOSTNAME_VAR="$(synonet --get_hostname)"
          SYNO_HOSTNAME_MOD=1
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
  HOSTNAME_VAR="$(synonet --get_hostname)"
  SYNO_HOSTNAME_MOD=1
fi


#---- Create Users and Groups
section "Create Ahuacate default Users and Groups"

msg "Creating default users..."
# Media user
if [ ! $(synouser --get media > /dev/null; echo $?) == 0 ]; then
  synouser --add media "" "Medialab user" 0 "" 0
  info "Default user created: ${YELLOW}media${NC} of group medialab"
fi
# Home user
if [ ! $(synouser --get home > /dev/null; echo $?) == 0 ]; then
  synouser --add home "" "Homelab user" 0 "" 0
  info "Default user created: ${YELLOW}home${NC} of groups medialab, homelab"
fi
# Private user
if [ ! $(synouser --get private > /dev/null; echo $?) == 0 ]; then
  synouser --add private "" "Privatelab user" 0 "" 0
  info "Default user created: ${YELLOW}private${NC} of groups medialab, homelab and privatelab"
fi
echo

msg "Creating default user groups..."
# Medialab group
if [ ! $(synogroup --get medialab > /dev/null; echo $?) == 0 ]; then
  synogroup --add medialab
  synogroup --descset medialab "Medialab user group"
  synogroup --member medialab media home private
  info "Default user group created: ${YELLOW}medialab${NC}"
fi
# Homelab group
if [ ! $(synogroup --get homelab > /dev/null; echo $?) == 0 ]; then
  synogroup --add homelab
  synogroup --descset homelab "Homelab user group"
  synogroup --member homelab home private
  info "Default user group created: ${YELLOW}homelab${NC}"
fi
# Medialab group
if [ ! $(synogroup --get privatelab > /dev/null; echo $?) == 0 ]; then
  sudo synogroup --add privatelab
  synogroup --descset privatelab "Privatelab user group"
  synogroup --member privatelab private
  info "Default user group created: ${YELLOW}privatelab${NC}"
fi
# Chrootjail group
if [ ! $(synogroup --get chrootjail > /dev/null; echo $?) == 0 ]; then
  sudo synogroup --add chrootjail
  synogroup --descset chrootjail "Chrootjail user group"
  info "Default user group created: ${YELLOW}chrootjail${NC}"
fi
echo

# Edit GUID ( Set GIDs )
sed -i 's|^medialab:x:*:.*|medialab:x:65605:media,home,private|g' /etc/group
sed -i 's|^homelab:x:*:.*|homelab:x:65606:home,private|g' /etc/group
sed -i 's|^privatelab:x:*:.*|privatelab:x:65607:private|g' /etc/group
sed -i 's|^chrootjail:x:*:.*|chrootjail:x:65608:|g' /etc/group
synogroup --rebuild all

# Edit UID ( Set UIDs )
msg "Finding and modifying old User UUID ( media, home, private ) to new UUID ( be patient, may take a while... )"
unset userid
userid=$(id -u media)
sed -i 's|^media:x:.*|media:x:1605:100:Medialab user:/var/services/homes/media:/sbin/nologin|g' /etc/passwd
find / -uid $userid \( -path /proc \) -exec chown media "{}" \;
unset userid
userid=$(id -u home)
sed -i 's|^home:x:.*|home:x:1606:100:Homelab user:/var/services/homes/home:/sbin/nologin|g' /etc/passwd
find / -uid $userid \( -path /proc \) -exec chown home "{}" \;
unset userid
userid=$(id -u private)
sed -i 's|^private:x:.*|private:x:1607:100:Privatelab user:/var/services/homes/private:/sbin/nologin|g' /etc/passwd
find / -uid $userid \( -path /proc \) -exec chown private "{}" \;
unset userid
synouser --rebuild all
echo


#---- New Synology Shared Folder
section "New Synology Shared Folders"

# Set DIR Schema
if [ -d /volume1 ]; then
  DIR_SCHEMA_TMP='/volume1'
else
  DIR_SCHEMA_TMP='/storage_example'
fi
msg "#### PLEASE READ CAREFULLY - SHARED FOLDERS ####\n
Shared folders are the basic directories where you can store files and folders on your Synology NAS. Below is a list of the Ahuacate default Synology shared folders.

$(while IFS=',' read -r var1 var2; do echo "  --  $DIR_SCHEMA_TMP/'${var1}'"; done < <( cat pve_nas_basefolderlist | sed 's/^#.*//' | sed '/^$/d' ))

Some of these shared folders may already exist. This script will modify the permissions and ACLs of matching existing shared folders and create new shared folders if required. You should always perform a Synology backup before running this script. This script will NOT delete any existing data but may change shared folder permissions.

The User must now select a Synology storage volume or pool location for our default shared storage folders."
echo

unset options
mapfile -t options <<< $(df -hx tmpfs --output=target | grep -v 'Mounted on\|^/dev$\|^/$')
PS3="Select a Synology storage volume (entering numeric) : "
select DIR_SCHEMA in "${options[@]}"; do
  msg "You have assigned and set: ${YELLOW}$DIR_SCHEMA${NC}"
  while true; do
    read -p "Confirm your selection is correct [y/n]?: " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        echo
        break 2
        ;;
      [Nn]*)
        msg "No problem. Try again..."
        echo
        break
        ;;
      *)
        warn "Error! Entry must be 'y' or 'n'. Try again..."
        echo
        ;;
    esac
  done
done


# Create storage share folders
msg "Creating ${SECTION_HEAD^} base ${DIR_SCHEMA} storage shares..."
echo
cat pve_nas_basefolderlist | sed '/^#/d' | sed '/^$/d' >/dev/null > pve_nas_basefolderlist_input
while IFS=',' read -r dir desc group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
  if [ -d "${DIR_SCHEMA}/${dir}" ]; then
    info "Pre-existing folder: ${UNDERLINE}"${DIR_SCHEMA}/${dir}"${NC}\n  Setting ${group^} group permissions for existing folder."
    find "${DIR_SCHEMA}/${dir}" -name .foo_protect -exec chattr -i {} \;
    # Delete old ACLs ( medialab, homelab, privatelab, chrootjail only )
    while read -r acl_entry; do 
      synoacltool -del ${DIR_SCHEMA}/${dir} ${acl_entry} > /dev/null
    done < <( synoacltool -get "${DIR_SCHEMA}/${dir}" | grep -i --color=never ".*medialab.*\|.*homelab.*\|.*privatelab.*\|.*chrootjail.*" | grep --color=never -Po "(?<=\[).*?(?=\])" | sort -r )
    # Set ACLs
    if [ ! -z ${acl_01} ]; then
      acl_var=${acl_01}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_02} ]; then
      acl_var=${acl_02}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_03} ]; then
      acl_var=${acl_03}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_04} ]; then
      acl_var=${acl_04}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_05} ]; then
      acl_var=${acl_05}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    echo
  else
    info "New base folder created:\n  ${WHITE}"${DIR_SCHEMA}/${dir}"${NC}"
    synoshare --add "${dir}" "${desc}" "${DIR_SCHEMA}/${dir}" "" "@administrators" "" 1 0
    # Set ACLs
    if [ ! -z ${acl_01} ]; then
      acl_var=${acl_01}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_02} ]; then
      acl_var=${acl_02}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_03} ]; then
      acl_var=${acl_03}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_04} ]; then
      acl_var=${acl_04}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    if [ ! -z ${acl_05} ]; then
      acl_var=${acl_05}
      synoaclset "${DIR_SCHEMA}/${dir}"
    fi
    echo
  fi
done < pve_nas_basefolderlist_input

# Create Default SubFolders
if [ -f pve_nas_basefoldersubfolderlist ]; then
  msg "Creating ${SECTION_HEAD^} subfolder shares..."
  echo
  echo -e "$(eval "echo -e \"`<pve_nas_basefoldersubfolderlist`\"")" | sed '/^#/d' | sed '/^$/d' >/dev/null > pve_nas_basefoldersubfolderlist_input
  while IFS=',' read -r dir group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
    if [ -d "${dir}" ]; then
      info "${dir} exists.\n  Setting ${group^} group permissions for this folder."
      find ${dir} -name .foo_protect -exec chattr -i {} \;
      chgrp -R "${group}" "${dir}" >/dev/null
      chmod -R "${permission}" "${dir}" >/dev/null
      if [ ! -z ${acl_01} ]; then
        acl_var=${acl_01}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_02} ]; then
        acl_var=${acl_02}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_03} ]; then
        acl_var=${acl_03}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_04} ]; then
        acl_var=${acl_04}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_05} ]; then
        acl_var=${acl_05}
        synoaclset "${dir}"
      fi
      echo
    else
      info "New subfolder created:\n  ${WHITE}"${dir}"${NC}"
      mkdir -p "${dir}" >/dev/null
      chgrp -R "${group}" "${dir}" >/dev/null
      chmod -R "${permission}" "${dir}" >/dev/null
      if [ ! -z ${acl_01} ]; then
        acl_var=${acl_01}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_02} ]; then
        acl_var=${acl_02}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_03} ]; then
        acl_var=${acl_03}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_04} ]; then
        acl_var=${acl_04}
        synoaclset "${dir}"
      fi
      if [ ! -z ${acl_05} ]; then
        acl_var=${acl_05}
        synoaclset "${dir}"
      fi
      echo
    fi
  done < pve_nas_basefoldersubfolderlist_input

  # Chattr set share points attributes to +a
  while IFS=',' read -r dir group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
    touch ${dir}/.foo_protect
    chattr +i ${dir}/.foo_protect
  done < pve_nas_basefoldersubfolderlist_input
fi

#---- Create NFS exports
# Stop NFS service
if [[ $(synoservice --is-enabled nfsd) ]]; then
  synoservice --disable nfsd &> /dev/null
fi

while IFS=',' read -r dir desc group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
  if [[ $(grep -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_SRC_FILE}) ]]; then
    # Edit existing nfs export share
    i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4)))
    counter=0
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      PVE_0X_IP="$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
      match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_SRC_FILE})
      if [[ $(echo "${match}" | grep -ws "${PVE_0X_IP}") ]]; then
        substitute=$(echo "${match}" | sed "s/${PVE_0X_IP}[^\t]*/${PVE_0X_IP}${NFS_STRING}/")
        sed -i "s|${match}|${substitute}|" ${NFS_SRC_FILE}
      else
        # Add to existing nfs export share
        substitute=$(echo "${match}" | sed "s/$/\t${PVE_0X_IP}${NFS_STRING}/")
        sed -i "s|${match}|${substitute}|g" ${NFS_SRC_FILE}
      fi
      ((i=i+1))
      ((counter++))
    done
  else
    # Create new nfs export share
    printf "\n"${DIR_SCHEMA}/${dir}"" >> ${NFS_SRC_FILE}
    i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4)))
    counter=0
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      PVE_0X_IP="$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
      match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_SRC_FILE})
      # Add to existing nfs export share
      substitute=$(echo "${match}" | sed "s/$/\t${PVE_0X_IP}${NFS_STRING}/")
      sed -i "s|${match}|${substitute}|g" ${NFS_SRC_FILE}
      ((i=i+1))
      ((counter++))
    done
  fi
done < pve_nas_basefolderlist_input

# Set NFS settings
sed -i "s#^\(nfsv4_enable.*\s*=\s*\).*\$#\1yes#" /etc/nfs/syno_nfs_conf # Enable nfs4.1
sed -i "s#^\(nfs_unix_pri_enable.*\s*=\s*\).*\$#\11#" /etc/nfs/syno_nfs_conf # Enable Unix permissions

# Restart NFS
if ! [ $(synoservice --status nfsd > /dev/null; echo $?) == 0 ]; then
  synoservice --reload nfsd
  synoservice --enable nfsd
fi

#---- Enable SMB
/usr/syno/etc/rc.sysv/S80samba.sh stop &> /dev/null
sed -i "s#\(min protocol.*\s*=\s*\).*\$#\1SMB2#" ${SMB_SRC_FILE}
sed -i "s#\(max protocol.*\s*=\s*\).*\$#\1SMB3#" ${SMB_SRC_FILE}
/usr/syno/etc/rc.sysv/S80samba.sh reload &> /dev/null
/usr/syno/etc/rc.sysv/S80samba.sh restart &> /dev/null

#---- Set Synology Hostname
if [ ${SYNO_HOSTNAME_MOD} == 0 ]; then
  synonet --set_hostname ${HOSTNAME_VAR}
fi

#---- Finish Line ------------------------------------------------------------------

section "Completion Status."

msg "Success. ${HOSTNAME_VAR^} build has completed and is ready to provide NFS/CIFS file storage to your Proxmox nodes.

$(if [ ${SYNO_HOSTNAME_MOD} == 0 ]; then echo "  --  Synology NAS hostname has changed to: ${WHITE}${HOSTNAME_VAR}${NC}\n"; fi)
More information about configuring a Synology NAS is available here:

  --  ${WHITE}https://github.com/ahuacate/pve-nas${NC}
  
We recommend the User now reboots this Synology NAS."