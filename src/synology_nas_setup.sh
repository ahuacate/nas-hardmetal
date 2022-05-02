#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     synology_nas_setup.sh
# Description:  Setup script to build a Synology DiskStation NAS
#
# Usage:        SSH into Synology. Login as 'admin'.
#               Then type cmd 'sudo -i' to run as root. Use same pwd as admin.
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
COMMON_DIR="${DIR}/../common"
COMMON_PVE_SRC="${DIR}/../common/pve/src"
SHARED_DIR="${DIR}/../shared"

#---- Dependencies -----------------------------------------------------------------

# Requires file: 'nas_basefolderlist' & 'nas_basefoldersubfolderlist'

# Check user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root.\nSSH into Synology. Login as 'admin'.\nThen type cmd 'sudo -i' to run as root. Use same pwd as admin.\nTry again. Bye..."
   sleep 3
   exit 1
fi

#---- Cleanup
function pushd () {
  command pushd "$@" &> /dev/null
}
function popd () {
  command popd "$@" &> /dev/null
}
function cleanup() {
  popd
  rm -rf $TEMP_DIR &> /dev/null
  unset TEMP_DIR
}

#---- Bash Messaging Functions
function msg() {
  local TEXT="$1"
  echo -e "$TEXT" | fmt -s -w 80 
}
function msg_nofmt() {
  local TEXT="$1"
  echo -e "$TEXT"
}
function warn() {
  local REASON="${WHITE}$1${NC}"
  local FLAG="${RED}[WARNING]${NC}"
  msg "$FLAG"
  msg "$REASON"
}
function info() {
  local REASON="$1"
  local FLAG="\e[36m[INFO]\e[39m"
  msg_nofmt "$FLAG $REASON"
}
function section() {
  local REASON="\e[97m$1\e[37m"
  printf -- '-%.0s' {1..84}; echo ""
  msg "  $SECTION_HEAD - $REASON"
  printf -- '-%.0s' {1..84}; echo ""
  echo
}
function indent() {
    eval "$@" |& sed "s/^/\t/"
    return "$PIPESTATUS"
}
function indent2() { sed 's/^/  /'; } # Use with pipe echo 'sample' | indent2

#---- Terminal settings
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
WHITE=$'\033[1;37m'
NC=$'\033[0m'
UNDERLINE=$'\033[4m'
printf '\033[8;40;120t'

#---- Static Variables -------------------------------------------------------------

# Regex checks
ip4_regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
ip6_regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
hostname_regex='^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$'
domain_regex='^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$'
R_NUM='^[0-9]+$' # Check numerals only
pve_hostname_regex='^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[0-9])$'

#---- Other Variables --------------------------------------------------------------

# Easy Script Section Header Body Text
SECTION_HEAD='Synology'

# Permission '000'
perm_01=':deny:rwxpdDaARWcCo:fd--'
# Permission '---'
perm_02=':deny:rwxpdDaARWcCo:fd--'
# Permission 'rwx'
perm_03=':allow:rwxpdDaARWc--:fd--'
# Permission 'rw-'
perm_04=':allow:rw-p-DaARWc--:fd--'
# Permission 'r-x'
perm_05=':allow:r-x---a-R-c--:fd--'
# Permission 'r--'
perm_06=':allow:r-----a-R-c--:fd--'
# Permission '-w-'
perm_07=':allow:-w-p-D-A-W---:fd--'
# Permission '--x'
perm_08=':allow:--x----------:fd--'

# No. of reserved PVE node IPs
PVE_HOST_NODE_CNT='5'

# NFS string and settings
NFS_STRING='(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)'
NFS_EXPORTS='/etc/exports'

# SMB settings
SMB_CONF='/etc/samba/smb.conf'

# DHCP status
if [[ $(synonet --show | grep "^DHCP.*") ]]; then
  NAS_DHCP='1'
elif [[ $(synonet --show | grep "^Manual\sIP.*") ]]; then
  NAS_DHCP='0'
  NAS_IP=$(synonet --show | grep -i --color=never "^IP:" | awk -F':' '{ print $2 }' | sed -r 's/\s+//g')
fi

# Search domain (local domain)
unset searchdomain_LIST
searchdomain_LIST=()
while IFS= read -r line; do
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

# Copy source files
sed -i 's/65605/medialab/g' ${COMMON_DIR}/nas/src/nas_basefolderlist # Edit GUID to Group name
sed -i 's/65606/homelab/g' ${COMMON_DIR}/nas/src/nas_basefolderlist # Edit GUID to Group name
sed -i 's/65607/privatelab/g' ${COMMON_DIR}/nas/src/nas_basefolderlist # Edit GUID to Group name
sed -i 's/65608/chrootjail/g' ${COMMON_DIR}/nas/src/nas_basefolderlist # Edit GUID to Group name
sed -i 's/65605/medialab/g' ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65606/homelab/g' ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65607/privatelab/g' ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist # Edit GUID to Group name
sed -i 's/65608/chrootjail/g' ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist # Edit GUID to Group name

#---- Functions --------------------------------------------------------------------

# Check IP Validity of Octet
function valid_ip() {
  local  ip=$1
  local  stat=1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      OIFS=$IFS
      IFS='.'
      ip=($ip)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
          && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi
  return $stat
}

# Synology ACL Function
function synoaclset() {
  synoacltool -add "$1" $(echo ${acl_var} | awk -F':' -v perm_01=${perm_01} -v perm_02=${perm_02} -v perm_03=${perm_03} -v perm_04=${perm_04} -v perm_05=${perm_05} -v perm_06=${perm_06} -v perm_07=${perm_07} -v perm_08=${perm_08} '{if ($2 == "000") print "group:"$1 perm_01;
  else if ($2 == "---") print "group:"$1 perm_02;
  else if ($2 == "rwx") print "group:"$1 perm_03;
  else if ($2 == "rw-") print "group:"$1 perm_04;
  else if ($2 == "r-x") print "group:"$1 perm_05;
  else if ($2 == "r--") print "group:"$1 perm_06;
  else if ($2 == "-w-") print "group:"$1 perm_07;
  else if ($2 == "--x") print "group:"$1 perm_08;
  else print "group:"$1":deny:rwxpdDaARWcCo:fd--"}')
}

#---- Body -------------------------------------------------------------------------

#---- Prerequisites
# Check for a Synology OS
eval $(grep "^majorversion=" /etc.defaults/VERSION)
DSM_MIN='6'
if [ ! $(uname -a | grep -i --color=never '.*synology.*' &> /dev/null; echo $?) == 0 ]; then
  warn "There are problems with this installation:

    --  Wrong Hardware. This setup script is for a Synology DiskStations.
  
  Bye..."
  return 0
elif [ $(uname -a | grep -i --color=never '.*synology.*' &> /dev/null; echo $?) == 0 ] && [ ! ${majorversion} -ge ${DSM_MIN} ] || [ ! $(id -u) == 0 ]; then
  warn "There are problems with this installation:

  $(if [ ! ${majorversion} -ge ${DSM_MIN} ]; then echo "  --  Wrong Synology DSM OS version. This setup script is for a Synology DSM Version ${DSM_MIN} or later. Try upgrading your Synology DSM OS."; fi)
  $(if [ ! $(id -u) == 0 ]; then echo "  --  This script must be run under User 'root'."; fi)

  Fix the issues and try again. Bye..."
  return 0
fi

# Check for User & Group conflict
unset USER_ARRAY
USER_ARRAY+=( "media medialab 1605 65605" "home homelab 1606 65606" "private privatelab 1607 65607" )
while read USER GROUP UUID GUID; do
  # Check for Group conflict
  if [ ! $(synogroup --get $GROUP &> /dev/null; echo $?) == 0 ] && [ $(synogroup --getgid $GUID &> /dev/null; echo $?) == 0 ]; then
    GUID_CONFLICT=$(synogroup --getgid $GUID | grep --color=never '^Group Name.*' | grep --color=never -Po '\[\K[^]]*')
    msg "${RED}[WARNING]${NC}\nThere are issues with this Synology:
    
    1. The Group GUID $GUID is in use by another Synology group named: ${GUID_CONFLICT^}. GUID $GUID must be available for the new group ${GROUP^}.
    2. The User must fix this issue before proceeding by assigning a different GUID to the conflicting group '${GUID_CONFLICT^}' or by deleting Synology group '${GUID_CONFLICT^}'.
    
    Exiting script. Fix the issue and try again..."
    echo
    return
  fi
  # Check for User conflict
  if [ ! $(synouser --get $USER &> /dev/null; echo $?) == 0 ] && [ $(synouser --getuid $UUID &> /dev/null; echo $?) == 0 ]; then
    UUID_CONFLICT=$(synouser --getuid $UUID | grep --color=never '^User Name.*' | grep --color=never -Po '\[\K[^]]*')
    msg "${RED}[WARNING]${NC}\nThere are issues with this Synology:
    
    1. The User UUID $UUID is in use by another Synology user named: ${UUID_CONFLICT^}. UUID $UUID must be available for the new user ${USER^}.
    2. The User must fix this issue before proceeding by assigning a different UUID to the conflicting user '${UUID_CONFLICT^}' or by deleting Synology user '${UUID_CONFLICT^}'.
    
    Exiting script. Fix the issue and try again..."
    echo
    return
  fi
done  < <( printf '%s\n' "${USER_ARRAY[@]}" )

# Check for chattr
if [ $(chattr --help &> /dev/null; echo $?) != 1 ]; then
  msg "${RED}[WARNING]${NC}\nThere are issues with this Synology:
    
  1. Chattr status: missing
  2. Install chattr ( use opkg ).
  
  Exiting script. Fix the issue and try again..."
  echo
  return
fi


#---- Introduction
section "Introduction"

msg "#### PLEASE READ CAREFULLY ####
This script will setup your Synology NAS to support Proxmox CIFS or NFS backend storage pools. Tasks and changes includes:

  -- User Groups ( create: medialab, homelab, privatelab, chrootjail )
  -- Users ( create: media, home, private - default CT App user accounts )
  -- Create all required shared folders required by Ahuacate CTs & VMs
  -- Create all required sub-folders
  -- Set new folder share permissions, chattr and ACLs ( Users and Group rights )
  -- Create NFS exports to Proxmox primary and secondary host nodes
  -- Enable NFS 4.1 and NFS Unix permissions
  -- Enable SMB with 'min protocol=SMB2' & 'max protocol=SMB3'

After running this script a fully compatible suite of Synology NAS folder shares and sub-folders will be created. Proxmox can then add storage by creating a CIFS or NFS backend storage pool to Synology NAS exported mount points ( we recommend NFS ). 

User input is required in the next steps to set Synology NFS export settings. This script will not delete any existing Synology folders or files but may modify file access permissions on existing shared folders. It is recommended you have a Synology file and settings backup before proceeding."
echo
echo
while true; do
  read -p "Proceed with your Synology NAS setup [y/n]?: " -n 1 -r YN
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


#---- Search Domain
# Check DNS Search domain setting compliance with Ahuacate default options
section "Validate Search Domain"
SEARCHDOMAIN=$(cat /etc/resolv.conf | grep -i '^domain' | awk '{ print $2 }' | sed -r 's/\s+//g')
display_msg="#### ABOUT SEARCH DOMAINS ####
A Search domain is also commonly known as the local domain. Search domain means the domain that will be automatically appended when you only use the hostname for a particular host or computer. Its used to resolve a devices hostname to its assigned IP address between computers. It is especially important in DHCP networks where hostnames are used for inter-machine communication (NFS, SMB and Applications like Sonarr, Radarr). Search Domain is NOT your DNS server IP address.

It is important all network devices are set with a identical Search Domain name. Most important are your routers, switches and DNS servers including PiHole. It's best to choose only top-level domain (spTLD) names for residential and small networks names because they cannot be resolved across the internet. Routers and DNS servers know, in theory, not to forward ARPA requests they do not understand onto the public internet. Choose one of our listed names for your whole LAN network Search Domain and you will not have any problems.

If you insist on using a made-up search domain name, then DNS requests may go unfulfilled by your router and forwarded onto global internet DNS root servers. This leaks information about your network such as device names.

Alternatively, you can use a registered domain name or subdomain if you know what you are doing.\n\nWe recommend you change your Search Domain setting '${SEARCHDOMAIN}' on all your network devices.

$(printf '%s\n' "${searchdomain_LIST[@]}" | grep -v 'other' | awk -F':' '{ print "  --  "$1 }')\n"
# Confirm Search Domain
msg "Checking Synology Search Domain name..."
if [[ $(printf '%s\n' "${searchdomain_LIST[@]}" | awk -F':' '{ print $1 }' | grep "^${SEARCHDOMAIN}$" >/dev/null 2>&1; echo $?) == '0' ]]; then
  info "Synology Search Domain is set: ${YELLOW}${SEARCHDOMAIN}${NC} ( unchanged )"
  echo
else
  warn "The Synology DNS Search Domain name '${SEARCHDOMAIN}' is non-standard."
  echo
  msg "$display_msg"
  echo
  while true; do
    read -p "Proceed with your Synology Search Domain '${SEARCHDOMAIN}' [y/n]?: " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        echo
        break
        ;;
      [Nn]*)
        msg "You have chosen not to proceed. Change your Synology DNS Search Domain using the Synology DNS Server application. Then re-run this script again. Exiting script..."
        echo
        return 0
        ;;
      *)
        warn "Error! Entry must be 'y' or 'n'. Try again..."
        echo
        ;;
    esac
  done
fi


#---- Synology Hostname
if [[ ! "$(synonet --get_hostname)" =~ ^.*([0-9])$ ]]; then
  section "Query Hostname"

  msg "You may want to change your Synology NAS hostname from '$(synonet --get_hostname)' to 'nas-01' ( i.e when adding additional NAS appliances use hostnames nas-02/03/04/05 ). Conforming to our standard network NAS naming convention assists our scripts in automatically detecting and resolving storage variables and other scripted tasks.\n\nThe system will now scan the network in ascending order the availability of our standard NAS hostname names beginning with: 'nas-01'. You may choose to accept our suggested new hostname or not."
  echo
  while true; do
    # Check for available hostname(s)
    i=1
    counter=1
    until [ $counter -eq 5 ]
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


#---- Set PVE primary host hostname and IP address
section "Input Proxmox primary hostname and IP address"
msg "#### PLEASE READ CAREFULLY ####\n\nThe User must confirm your PVE primary hostname and IP address. Only input the PVE primary host details and NOT the secondary host. These inputs are critical for system and networking configuration."
echo
HOSTNAME_FAIL_MSG="The PVE hostname is not valid. A valid PVE hostname is when all of the following constraints are satisfied:\n
  --  it does exists on the network.
  --  it contains only lowercase characters.
  --  it may include numerics, hyphens (-) and periods (.) but not start or end with them.
  --  it must end with a numeric.
  --  it doesn't contain any other special characters [!#$&%*+_].
  --  it doesn't contain any white space.
  --  it must end with a numeric '0' or '1'\n
Why is this important?
Because Proxmox computing power is expanded using clusters of PVE machine hosts. Each PVE hostname should be denoted and sequenced with a numeric suffix beginning with '1' or '01' for easy installation scripting identification. Our standard PVE host naming convention is 'pve-01', 'pve-02', 'pve-03' and so on. Our scripts by default create NFS and SMB export permissions based on consecutive PVE hostnames beginning with the primary hostname (i.e pve-01 to pve-0${PVE_HOST_NODE_CNT}). If you use non-valid hostname such as 'pve-one', which has no identifiable numeric suffix, our scripts cannot work.\nWe recommend the User immediately changes the PVE primary hostname to 'pve-01' and all secondary PVE hosts to 'pve-02' and so on, or any hostname suffixed with numerics, before proceeding.\n"
IP_FAIL_MSG="The IP address is not valid. A valid IP address is when all of the following constraints are satisfied:\n
  --  it meets the IPv4 or IPv6 standard.
  --  it doesn't contain any white space.\n
Try again..."

# Input PVE hostname
while true; do
  read -p "Enter your PVE primary host hostname: " -e PVE_HOSTNAME_VAR
  if [[ ${PVE_HOSTNAME_VAR} =~ ${pve_hostname_regex} ]] && [[ ${PVE_HOSTNAME_VAR} =~ ^.*([1|0])$ ]]; then
    PVE_HOSTNAME=${PVE_HOSTNAME_VAR}
    info "PVE primary hostname is set: ${YELLOW}${PVE_HOSTNAME}${NC}"
    break
  else
    echo
    warn "$HOSTNAME_FAIL_MSG"
    while true; do
      read -p "Do you want enter a different input ( another hostname ) [y/n]? " -n 1 -r YN
      echo
      case $YN in
        [Yy]*)
          echo
          ;;
        [Nn]*)
          msg "No problem. Change your PVE host primary hostname and try again. Bye..."
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
done

# Input PVE primary IP
while true; do
  read -p "Enter your PVE primary host IP address: " -e PVE_HOST_IP_VAR
  if [[ ${PVE_HOST_IP_VAR} =~ ${ip4_regex} ]] || [[ ${PVE_HOST_IP_VAR} =~ ${ip6_regex} ]]; then
    PVE_HOST_IP=${PVE_HOST_IP_VAR}
    info "PVE primary host IP address is set: ${YELLOW}${PVE_HOST_IP}${NC}"
    echo
    break
  else
    warn "$IP_FAIL_MSG"
    echo
  fi
done

# Create PVE hostname and IP array
if [[ ${PVE_HOSTNAME} =~ ^.*([1|0])$ ]] && [[ ${PVE_HOST_IP} =~ ${ip4_regex} ]]; then
  # Multi PVE nodes IPv4
  msg "Setting your PVE host nodes identities as shown ( total of ${PVE_HOST_NODE_CNT} reserved PVE nodes for future Proxmox cluster expansion ):"
  unset pve_node_LIST
  pve_node_LIST=()
  # IP vars
  i=$(( $(echo ${PVE_HOST_IP} | cut -d . -f 4) + 1 ))
  # Hostname vars
  j=$(( $(echo ${PVE_HOSTNAME} | awk '{print substr($0,length,1)}') + 1 ))
  PVE_HOSTNAME_VAR=$(echo ${PVE_HOSTNAME} | sed 's/.$//')
  counter=1
  # Add first node to array
  pve_node_LIST+=( "${PVE_HOSTNAME},${PVE_HOST_IP},primary host" )
  until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
  do
    pve_node_LIST+=( "${PVE_HOSTNAME_VAR}${j},$(echo ${PVE_HOST_IP} | cut -d"." -f1-3).${i},secondary host" )
    ((i=i+1))
    ((j=j+1))
    ((counter++))
  done
  echo
  printf '%s\n' "${pve_node_LIST[@]}" | awk -F',' '{ print "  --  "$1"\t"$2"\t"$3 }'
  echo
elif [[ ${PVE_HOSTNAME} =~ ^.*([1|0])$ ]] && [[ ${PVE_HOST_IP} =~ ${ip6_regex} ]]; then
  # Multi PVE nodes IPv6
  msg "Setting ${PVE_HOST_NODE_CNT} reserved PVE host nodes identities as shown. All NFS exports will use hostnames only:"
  unset pve_node_LIST
  pve_node_LIST=()
  # Hostname vars
  j=$(( $(echo ${PVE_HOSTNAME} | awk '{print substr($0,length,1)}') + 1 ))
  PVE_HOSTNAME_VAR=$(echo ${PVE_HOSTNAME} | sed 's/.$//')
  counter=1
  # Add first node to array
  pve_node_LIST+=( "${PVE_HOSTNAME},${PVE_HOST_IP},primary host" )
  until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
  do
    pve_node_LIST+=( "${PVE_HOSTNAME_VAR}${j},IPv6,secondary host" )
    ((j=j+1))
    ((counter++))
  done
  echo
  printf '%s\n' "${pve_node_LIST[@]}" | awk -F',' '{ print "  --  "$1"\t"$2"\t"$3 }'
  echo
fi

#---- Start Build ------------------------------------------------------------------

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

$(while IFS=',' read -r var1 var2; do echo "  --  $DIR_SCHEMA_TMP/'${var1}'"; done < <( cat nas_basefolderlist | sed 's/^#.*//' | sed '/^$/d' ))

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

# Create base folder array list
rm_match='^\#.*$|^\s*$'
# 'nas_basefolder_LIST' array
unset nas_basefolder_LIST
nas_basefolder_LIST=()
while IFS= read -r line; do
  [[ "$line" =~ (${rm_match}) ]] && continue
  nas_basefolder_LIST+=( "$line" )
done < ${COMMON_DIR}/nas/src/nas_basefolderlist

# Create subfolder array list
rm_match='^\#.*$|^\s*$'
# 'nas_basefoldersubfolder_LIST' array
unset nas_basefoldersubfolder_LIST
nas_basefoldersubfolder_LIST=()
while IFS= read -r line; do
  [[ "$line" =~ (${rm_match}) ]] && continue
  nas_basefoldersubfolder_LIST+=( "$(eval echo -e "$line")" )
done < ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist

# Create storage share folders
msg "Creating ${SECTION_HEAD^} base ${DIR_SCHEMA} storage shares..."
echo
# cat nas_basefolderlist | sed '/^#/d' | sed '/^$/d' >/dev/null > nas_basefolderlist_input
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
done <<< $(printf '%s\n' "${nas_basefolder_LIST[@]}")

# Create Default SubFolders
msg "Creating ${SECTION_HEAD^} subfolder shares..."
echo
# echo -e "$(eval "echo -e \"`<nas_basefoldersubfolderlist`\"")" | sed '/^#/d' | sed '/^$/d' >/dev/null > nas_basefoldersubfolderlist_input
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
done <<< $(printf '%s\n' "${nas_basefoldersubfolder_LIST[@]}")

# Chattr set share points attributes to +a
while IFS=',' read -r dir group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
  touch ${dir}/.foo_protect
  chattr +i ${dir}/.foo_protect
done <<< $(printf '%s\n' "${nas_basefoldersubfolder_LIST[@]}")


#---- Create NFS exports
# Stop NFS service
if [[ $(synoservice --is-enabled nfsd) ]]; then
  synoservice --disable nfsd &> /dev/null
fi

while IFS=',' read -r dir desc group permission acl_01 acl_02 acl_03 acl_04 acl_05; do
  if [[ $(grep -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_EXPORTS}) ]]; then
    # Edit existing nfs export share
    i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4)))
    counter=0
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      PVE_0X_IP="$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
      match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_EXPORTS})
      if [[ $(echo "${match}" | grep -ws "${PVE_0X_IP}") ]]; then
        substitute=$(echo "${match}" | sed "s/${PVE_0X_IP}[^\t]*/${PVE_0X_IP}${NFS_STRING}/")
        sed -i "s|${match}|${substitute}|" ${NFS_EXPORTS}
      else
        # Add to existing nfs export share
        substitute=$(echo "${match}" | sed "s/$/\t${PVE_0X_IP}${NFS_STRING}/")
        sed -i "s|${match}|${substitute}|g" ${NFS_EXPORTS}
      fi
      ((i=i+1))
      ((counter++))
    done
  else
    # Create new nfs export share
    printf "\n"${DIR_SCHEMA}/${dir}"" >> ${NFS_EXPORTS}
    i=$(( $(echo ${PVE_01_IP} | cut -d . -f 4)))
    counter=0
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]
    do
      PVE_0X_IP="$(echo ${PVE_01_IP} | cut -d"." -f1-3).${i}"
      match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" ${NFS_EXPORTS})
      # Add to existing nfs export share
      substitute=$(echo "${match}" | sed "s/$/\t${PVE_0X_IP}${NFS_STRING}/")
      sed -i "s|${match}|${substitute}|g" ${NFS_EXPORTS}
      ((i=i+1))
      ((counter++))
    done
  fi
done <<< $(printf '%s\n' "${nas_basefolder_LIST[@]}")

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
sed -i "s#\(min protocol.*\s*=\s*\).*\$#\1SMB2#" ${SMB_CONF_FILE}
sed -i "s#\(max protocol.*\s*=\s*\).*\$#\1SMB3#" ${SMB_CONF_FILE}
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