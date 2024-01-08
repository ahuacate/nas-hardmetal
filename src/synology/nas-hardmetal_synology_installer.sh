#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     nas-hardmetal_synology_installer.sh
# Description:  Setup script to build a Synology DiskStation NAS
#
# Usage:        SSH into Synology. Login as 'admin'.
#               Then type cmd 'sudo -i' to run as root. Use same pwd as admin.
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Requires file: 'nas_basefolderlist' & 'nas_basefoldersubfolderlist'

# Check user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root.\nSSH into Synology. Login as 'admin'.\nThen type cmd 'sudo -i' to run as root. Use same pwd as admin.\nTry again. Bye..."
    sleep 3
    return
fi

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

# ACL permissions
# Permission '000'
perm_01=':deny:rwxpdDaARWcCo'
# Permission '---'
perm_02=':deny:rwxpdDaARWcCo'
# Permission 'rwx'
perm_03=':allow:rwxpdDaARWc--'
# Permission 'rw-'
perm_04=':allow:rw-p-DaARWc--'
# Permission 'r-x'
perm_05=':allow:r-x---a-R-c--'
# Permission 'r--'
perm_06=':allow:r-----a-R-c--'
# Permission '-w-'
perm_07=':allow:-w-p-D-A-W---'
# Permission '--x'
perm_08=':allow:--x----------'

# No. of reserved PVE node IPs
PVE_HOST_NODE_CNT='5'

# NFS string and settings
NFS_STRING='(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)'
NFS_EXPORTS='/etc/exports'

# SMB settings
SMB_CONF='/etc/samba/smb.conf'

# DHCP status
if [[ $(synonet --show 2> /dev/null | grep "^DHCP.*") ]]; then
    NAS_DHCP='1'
    NAS_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
elif [[ $(synonet --show 2> /dev/null | grep "^Manual\sIP.*") ]]; then
    NAS_DHCP='0'
    NAS_IP=$(synonet --show 2> /dev/null | grep -i --color=never "^IP:" | awk -F':' '{ print $2 }' | sed -r 's/\s+//g')
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

# Synoacltool ACL Set Function
function synoacl_set() {
    # Usage: synoacl_set "path/to/dir"

    # Set a dir acl
    # "$1" is path/to/dir

    # Set inherit permission acl
    if [ -n "$inherit" ] && [ "$inherit" -eq 0 ]; then
        local perm_inherit='----'
    elif [ -n "$inherit" ] && [ "$inherit" -eq 1 ]; then
        local perm_inherit='fd--'
    else
        local perm_inherit='----'
    fi

    # Set acl
    if [ -n "$1" ] && [ -n "${acl_var%%:*}" ]; then
        synoacltool -add "$1" $(echo ${acl_var} | awk -F':' -v perm_01=${perm_01} -v perm_02=${perm_02} -v perm_03=${perm_03} -v perm_04=${perm_04} -v perm_05=${perm_05} -v perm_06=${perm_06} -v perm_07=${perm_07} -v perm_08=${perm_08} -v perm_inherit="${perm_inherit}" '{
            if ($2 == "000") print "group:"$1 perm_01":" perm_inherit;
            else if ($2 == "---") print "group:"$1 perm_02":" perm_inherit;
            else if ($2 == "rwx") print "group:"$1 perm_03":" perm_inherit;
            else if ($2 == "rw-") print "group:"$1 perm_04":" perm_inherit;
            else if ($2 == "r-x") print "group:"$1 perm_05":" perm_inherit;
            else if ($2 == "r--") print "group:"$1 perm_06":" perm_inherit;
            else if ($2 == "-w-") print "group:"$1 perm_07":" perm_inherit;
            else if ($2 == "--x") print "group:"$1 perm_08":" perm_inherit;
            else print "group:"$1":deny:rwxpdDaARWcCo:fd--";
        }')
        wait
    else
        echo "Skipping processing acl entry: '$acl_var' (invalid acl)"
    fi
}

# Synoacltool ACL Get Function
function synoacl_get() {
    # Usage: synoacl_get "path/to/dir"

    # Gets all acl entries of the given path
    # "$1" is path/to/dir

    # Set inherit permission acl
    if [ -n "$inherit" ] && [ "$inherit" -eq 0 ]; then
        local perm_inherit='----'
    elif [ -n "$inherit" ] && [ "$inherit" -eq 1 ]; then
        local perm_inherit='fd--'
    else
        local perm_inherit='----'
    fi

    # Get ACL
    synoacltool -get "$1" | grep "$(echo ${acl_var} | awk -F':' -v perm_01=${perm_01} -v perm_02=${perm_02} -v perm_03=${perm_03} -v perm_04=${perm_04} -v perm_05=${perm_05} -v perm_06=${perm_06} -v perm_07=${perm_07} -v perm_08=${perm_08} -v perm_inherit="${perm_inherit}" '{
            if ($2 == "000") print "group:"$1 perm_01":" perm_inherit;
            else if ($2 == "---") print "group:"$1 perm_02":" perm_inherit;
            else if ($2 == "rwx") print "group:"$1 perm_03":" perm_inherit;
            else if ($2 == "rw-") print "group:"$1 perm_04":" perm_inherit;
            else if ($2 == "r-x") print "group:"$1 perm_05":" perm_inherit;
            else if ($2 == "r--") print "group:"$1 perm_06":" perm_inherit;
            else if ($2 == "-w-") print "group:"$1 perm_07":" perm_inherit;
            else if ($2 == "--x") print "group:"$1 perm_08":" perm_inherit;
            else print "group:"$1":deny:rwxpdDaARWcCo:fd--";
        }')"
        wait
}

# Synoacltool ACL Clean Function
function synoacl_clean() {
    # Usage: synoacl_clean "path/to/dir"

    # Checks for acl entry by group name and if exists removes (all) the acl entries of group name
    # "$1" is path/to/dir

    while synoacltool -get "$1" | grep -q "$(echo ${acl_var} | awk -F':' '{print $1}')"; do
        acl_index=$(synoacltool -get "$1" | grep "$(echo ${acl_var} | awk -F':' '{print $1}')" | awk -F'[][]' '{print $2}' | head -n 1)

        if [ -n "$acl_index" ]; then
            synoacltool -del "$1" $acl_index
            wait
        else
            break  # Exit the loop if no more entries are found
        fi
    done
}

#---- Body -------------------------------------------------------------------------

#---- Prerequisites
# Check for a Synology OS
eval $(grep "^majorversion=" /etc.defaults/VERSION)
DSM_MIN='7'
if [[ ! $(uname -a | grep -i --color=never '.*synology.*') ]]; then
    warn "There are problems with this installation:

        --  Wrong Hardware. This setup script is for a Synology DiskStations.
    
    Bye..."
    return
elif [[ $(uname -a | grep -i --color=never '.*synology.*') ]] && [ ! ${majorversion} -ge ${DSM_MIN} ] || [[ ! $(id -u) ]]; then
    warn "There are problems with this installation:

    $(if [ ! ${majorversion} -ge ${DSM_MIN} ]; then echo "  --  Wrong Synology DSM OS version. This setup script is for a Synology DSM Version ${DSM_MIN} or later. Try upgrading your Synology DSM OS."; fi)
    $(if [ ! $(id -u) == 0 ]; then echo "  --  This script must be run under User 'root'."; fi)

    Fix the issues and try again. Bye..."
    return
fi

# Check for User & Group conflict
unset USER_ARRAY
USER_ARRAY+=( "media medialab 1605 65605" "home homelab 1606 65606" "private privatelab 1607 65607" )
while read USER GROUP UUID GUID; do
    # Check for Group conflict
    if [ ! $(synogroup --get $GROUP &> /dev/null; echo $?) -eq 0 ] && [ $(synogroup --getgid $GUID &> /dev/null; echo $?) -eq 0 ]; then
        GUID_CONFLICT=$(synogroup --getgid $GUID | grep --color=never '^Group Name.*' | grep --color=never -Po '\[\K[^]]*')
        msg "${RED}[WARNING]${NC}\nThere are issues with this Synology:
        
        1. The Group GUID $GUID is in use by another Synology group named: ${GUID_CONFLICT^}. GUID $GUID must be available for the new group ${GROUP^}.
        2. The User must fix this issue before proceeding by assigning a different GUID to the conflicting group '${GUID_CONFLICT^}' or by deleting Synology group '${GUID_CONFLICT^}'.
        
        Exiting script. Fix the issue and try again..."
        echo
        return
    fi
    # Check for User conflict
    if [ ! $(synouser --get $USER &> /dev/null; echo $?) -eq 0 ] && [ $(synouser --getuid $UUID &> /dev/null; echo $?) -eq 0 ]; then
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
if [ $(chattr --help &> /dev/null; echo $?) -ne 1 ]; then
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

  -- User Groups
     ( create: medialab, homelab, privatelab, chrootjail )
  -- Users
     ( create: media, home, private - default CT App user accounts )
  -- Create all required shared folders required by Ahuacate CTs & VMs
  -- Create all required sub-folders
  -- Set new folder share permissions, chattr and ACLs
  -- Create a '.stignore' support for Syncthing
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
        return
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
if [[ $(printf '%s\n' "${searchdomain_LIST[@]}" | awk -F':' '{ print $1 }' | grep "^${SEARCHDOMAIN}$" >/dev/null 2>&1; echo $?) -eq '0' ]]; then
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
            return
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
    until [ $counter -eq 5 ]; do
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
          SYNO_HOSTNAME_MOD=1
          echo
          break 2
          ;;
        [Nn]*)
          info "No problem. Synology hostname is unchanged."
          HOSTNAME_VAR="$(synonet --get_hostname)"
          SYNO_HOSTNAME_MOD=0
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
    SYNO_HOSTNAME_MOD=0
fi


#---- Set PVE primary host hostname and IP address
section "Input Proxmox primary hostname and IP address"
msg "#### PLEASE READ CAREFULLY ####\n\nThe User must confirm their PVE primary hostname (i.e pve-01) and IP address. Only input your PVE primary host details and NOT a secondary hostname. These inputs are critical for system and networking configuration."
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
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]; do
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
    until [ $counter -eq ${PVE_HOST_NODE_CNT} ]; do
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
rebuild_status=0  # Rebuild status control. '0' for no, '1' for yes

msg "Creating default users..."
# Media user
if [ ! $(synouser --get media &> /dev/null; echo $?) -eq 0 ]; then
    synouser --add media "" "Medialab user" 0 "" 0
    info "Default user created: ${YELLOW}media${NC} of group medialab"
fi
# Home user
if [ ! $(synouser --get home &> /dev/null; echo $?) -eq 0 ]; then
    synouser --add home "" "Homelab user" 0 "" 0
    info "Default user created: ${YELLOW}home${NC} of groups medialab, homelab"
fi
# Private user
if [ ! $(synouser --get private &> /dev/null; echo $?) -eq 0 ]; then
        synouser --add private "" "Privatelab user" 0 "" 0
        info "Default user created: ${YELLOW}private${NC} of groups medialab, homelab and privatelab"
fi
echo

msg "Creating default user groups..."
# Medialab group
if [ ! $(synogroup --get medialab &> /dev/null; echo $?) -eq 0 ]; then
    synogroup --add medialab
    synogroup --descset medialab "Medialab user group"
    synogroup --member medialab media home private
    info "Default user group created: ${YELLOW}medialab${NC}"
fi
# Homelab group
if [ ! $(synogroup --get homelab &> /dev/null; echo $?) -eq 0 ]; then
    synogroup --add homelab
    synogroup --descset homelab "Homelab user group"
    synogroup --member homelab home private
    info "Default user group created: ${YELLOW}homelab${NC}"
fi
# Medialab group
if [ ! $(synogroup --get privatelab &> /dev/null; echo $?) -eq 0 ]; then
    sudo synogroup --add privatelab
    synogroup --descset privatelab "Privatelab user group"
    synogroup --member privatelab private
    info "Default user group created: ${YELLOW}privatelab${NC}"
fi
# Chrootjail group
if [ ! $(synogroup --get chrootjail &> /dev/null; echo $?) -eq 0 ]; then
    sudo synogroup --add chrootjail
    synogroup --descset chrootjail "Chrootjail user group"
    info "Default user group created: ${YELLOW}chrootjail${NC}"
fi
echo

# Edit GUID ( Set GIDs )
# Medialab group
if ! grep -q '^medialab:x:65605:media,home,private' /etc/group; then
    sed -i 's|^medialab:x:*:.*|medialab:x:65605:media,home,private|' /etc/group  # Update guid
    rebuild_status=1  # '1' denotes update required
fi
# Homelab group
if ! grep -q '^homelab:x:*:.*|homelab:x:65606:home,private' /etc/group; then
    sed -i 's|^homelab:x:*:.*|homelab:x:65606:home,private|' /etc/group  # Update guid
    rebuild_status=1  # '1' denotes update required
fi
# Privatelab group
if ! grep -q '^privatelab:x:*:.*|privatelab:x:65607:private' /etc/group; then
    sed -i 's|^privatelab:x:*:.*|privatelab:x:65607:private|' /etc/group  # Update guid
    rebuild_status=1  # '1' denotes update required
fi
# Chrootjail group
if ! grep -q '^chrootjail:x:65608:' /etc/group; then
    sed -i 's|^chrootjail:x:*:.*|chrootjail:x:65608:|' /etc/group  # Update guid
    rebuild_status=1  # '1' denotes update required
fi

# Perform Syno update/rebuild
if [ "$rebuild_status" -eq 1 ]; then
    synogroup --rebuild all
    wait
    rebuild_status=0  # Reset rebuild status control. '0' for no, '1' for yes
fi

# Edit UID ( Set UIDs )
msg "Finding and modifying any old User UUID ( media, home, private ) to new UUID ( be patient, may take a long, long, long while... )"
userid=$(id -u media)
if [ ! "$userid" -eq 1605 ]; then
    sed -i 's|^media:x:.*|media:x:1605:100:Medialab user:/var/services/homes/media:/sbin/nologin|g' /etc/passwd
    find / -uid $userid \( -path /proc \) -exec chown media "{}" \;
    rebuild_status=1  # '1' denotes update required
fi
userid=$(id -u home)
if [ ! "$userid" -eq 1606 ]; then
    sed -i 's|^home:x:.*|home:x:1606:100:Homelab user:/var/services/homes/home:/sbin/nologin|g' /etc/passwd
    find / -uid $userid \( -path /proc \) -exec chown home "{}" \;
    rebuild_status=1  # '1' denotes update required
fi
userid=$(id -u private)
if [ ! "$userid" -eq 1607 ]; then
    sed -i 's|^private:x:.*|private:x:1607:100:Privatelab user:/var/services/homes/private:/sbin/nologin|g' /etc/passwd
    find / -uid $userid \( -path /proc \) -exec chown private "{}" \;
    rebuild_status=1  # '1' denotes update required
fi

# Perform Syno update/rebuild
if [ "$rebuild_status" -eq 1 ]; then
    synouser --rebuild all
    wait
    rebuild_status=0  # Reset rebuild status control. '0' for no, '1' for yes
fi
echo


#---- New Synology Shared Folder
section "New Synology Shared Folders"

# Set DIR Schema
if [ -d "/volume1" ]; then
    DIR_SCHEMA_TMP='/volume1'
else
    DIR_SCHEMA_TMP='/storage_example'
fi
msg "#### PLEASE READ CAREFULLY - SHARED FOLDERS ####\n
Shared folders are the basic directories where you can store files and folders on your Synology NAS. Below is a list of the Ahuacate default Synology shared folders.

$(while IFS=',' read -r var1 var2; do echo "  --  ${DIR_SCHEMA_TMP}/'${var1}'"; done < <( cat ${COMMON_DIR}/nas/src/nas_basefolderlist | sed 's/^#.*//' | sed '/^$/d' ))

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
    nas_basefoldersubfolder_LIST+=( "${DIR_SCHEMA}/${line}" )
done < ${COMMON_DIR}/nas/src/nas_basefoldersubfolderlist


# Create storage share folders
msg "Creating ${SECTION_HEAD^} base ${DIR_SCHEMA} storage shares..."
echo
while IFS=',' read -r dir desc user group permission inherit acl_01 acl_02 acl_03 acl_04 acl_05; do
    if [ -d "$DIR_SCHEMA/$dir" ]; then
        info "Pre-existing folder: ${UNDERLINE}"$DIR_SCHEMA/$dir"${NC}\nSetting ${group^} group permissions for existing folder."
        find "$DIR_SCHEMA/$dir" -name .foo_protect -exec chattr -i {} \;

        # Set 'administrators' ACL
        acl_var='administrators:rwx'  # acl var (user/group:permissions)
        if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
            synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi

        # Set ACLs
        if [ -n "$acl_01" ]; then
            acl_var="$acl_01"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
                synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
                synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_02" ]; then
            acl_var="$acl_02"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
                synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
                synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_03" ]; then
            acl_var="$acl_03"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
                synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
                synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_04" ]; then
            acl_var="$acl_04"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
                synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
                synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_05" ]; then
            acl_var="$acl_05"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
                synoacl_clean "$DIR_SCHEMA/$dir"  # Remove old non-conforming acl entry
                synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
            fi
        fi
        echo
    else
        info "New base folder created:\n${WHITE}"$DIR_SCHEMA/$dir"${NC}"
        synoshare --add "$dir" "$desc" "$DIR_SCHEMA/$dir" "" "@administrators" "" 1 0
        sleep 2

        # Set 'administrators' ACL
        acl_var='administrators:rwx'  # acl var (user/group:permissions)
        if [[ ! $(synoacl_get "$DIR_SCHEMA/$dir") ]]; then
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi

        # Set ACLs
        if [ -n "$acl_01" ]; then
            acl_var="$acl_01"  # acl var (user/group:permissions)
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi
        if [ -n "$acl_02" ]; then
            acl_var="$acl_02"  # acl var (user/group:permissions)
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi
        if [ -n "$acl_03" ]; then
            acl_var="$acl_03"  # acl var (user/group:permissions)
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi
        if [ -n "$acl_04" ]; then
            acl_var="$acl_04"  # acl var (user/group:permissions)
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi
        if [ -n "$acl_05" ]; then
            acl_var="$acl_05"  # acl var (user/group:permissions)
            synoacl_set "$DIR_SCHEMA/$dir"  # Make new acl entry
        fi
        echo
    fi

    # Add file '.stignore' for Syncthing
    if [ -d "$DIR_SCHEMA/$dir" ]; then
        common_stignore="$COMMON_DIR/nas/src/nas_stignorelist"
        file_stignore="$DIR_SCHEMA/$dir/.stignore"

        # Create missing '.stignore' file
        if [ ! -f "$file_stignore" ]; then
            touch "$DIR_SCHEMA/$dir/.stignore"
        fi

        # Read each line from the common ignore list
        while IFS= read -r pattern; do
            # Check if the pattern exists in the directory's .stignore file
            if ! grep -qF "$pattern" "$file_stignore"; then
                # If not, append the pattern to the .stignore file
                echo "$pattern" >> "$file_stignore"
                echo "Added: $pattern"
            else
                echo "Already exists: $pattern"
            fi
        done < "$common_stignore"
    fi
done < <( printf '%s\n' "${nas_basefolder_LIST[@]}" )

# Create Default SubFolders
msg "Creating ${SECTION_HEAD^} subfolder shares..."
echo
while IFS=',' read -r dir user group permission inherit acl_01 acl_02 acl_03 acl_04 acl_05; do
    if [ -d "$dir" ]; then
        info "$dir exists.\nSetting ${group^} group permissions for this folder."
        find "$dir" -name .foo_protect -exec chattr -i {} \;
        chgrp -R "root" "$dir" >/dev/null
        chmod -R "$permission" "$dir" >/dev/null

        # Set 'administrators' ACL
        acl_var='administrators:rwx'  # acl var (user/group:permissions)
        if [[ ! $(synoacl_get "$dir") ]]; then
            synoacl_clean "$dir"  # Remove old non-conforming acl entry
            synoacl_set "$dir"  # Make new acl entry
        fi

        # Set ACLs
        if [ -n "$acl_01" ]; then
            acl_var="$acl_01"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$dir") ]]; then
                synoacl_clean "$dir"  # Remove old non-conforming acl entry
                synoacl_set "$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_02" ]; then
            acl_var="$acl_02"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$dir") ]]; then
                synoacl_clean "$dir"  # Remove old non-conforming acl entry
                synoacl_set "$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_03" ]; then
            acl_var="$acl_03"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$dir") ]]; then
                synoacl_clean "$dir"  # Remove old non-conforming acl entry
                synoacl_set "$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_04" ]; then
            acl_var="$acl_04"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$dir") ]]; then
                synoacl_clean "$dir"  # Remove old non-conforming acl entry
                synoacl_set "$dir"  # Make new acl entry
            fi
        fi
        if [ -n "$acl_05" ]; then
            acl_var="$acl_05"  # acl var (user/group:permissions)
            if [[ ! $(synoacl_get "$dir") ]]; then
                synoacl_clean "$dir"  # Remove old non-conforming acl entry
                synoacl_set "$dir"  # Make new acl entry
            fi
        fi
        echo
    else
        info "New subfolder created:\n${WHITE}"$dir"${NC}"
        mkdir -p "$dir" >/dev/null
        chgrp -R "root" "$dir" >/dev/null
        chmod -R "$permission" "$dir" >/dev/null

        # Set 'administrators' ACL
        acl_var='administrators:rwx'  # acl var (user/group:permissions)
        if [[ ! $(synoacl_get "$dir") ]]; then
            synoacl_clean "$dir"  # Remove old non-conforming acl entry
            synoacl_set "$dir"  # Make new acl entry
        fi

        # Set ACLs
        if [ -n "$acl_01" ]; then
            acl_var="$acl_01"  # acl var (user/group:permissions)
            synoacl_set "$dir"  # Make new acl entry
        fi
        if [ -n "$acl_02" ]; then
            acl_var="$acl_02"  # acl var (user/group:permissions)
            synoacl_set "$dir"  # Make new acl entry
        fi
        if [ -n "$acl_03" ]; then
            acl_var="$acl_03"  # acl var (user/group:permissions)
            synoacl_set "$dir"  # Make new acl entry
        fi
        if [ -n "$acl_04" ]; then
            acl_var="$acl_04"  # acl var (user/group:permissions)
            synoacl_set "$dir"  # Make new acl entry
        fi
        if [ -n "$acl_05" ]; then
            acl_var="$acl_05"  # acl var (user/group:permissions)
            synoacl_set "$dir"  # Make new acl entry
        fi
        echo
    fi
done < <( printf '%s\n' "${nas_basefoldersubfolder_LIST[@]}" )

# Chattr set share points attributes to +a
while IFS=',' read -r dir user group permission inherit acl_01 acl_02 acl_03 acl_04 acl_05; do
    touch "$dir/.foo_protect"
    chattr +i "$dir/.foo_protect"
done < <( printf '%s\n' "${nas_basefoldersubfolder_LIST[@]}" )


#---- Create NFS exports
section "Setup NFS exports"

# Stop NFS service
# if [[ $(synoservice --is-enabled nfsd) ]]; then
#   synoservice --disable nfsd &> /dev/null
# fi
if [[ $(systemctl is-active nfs-mountd.service) ]]; then
    # synoservice --disable nfsd &> /dev/null
    systemctl stop nfs-idmapd.service
    systemctl stop nfs-mountd.service
fi

# Check if Static hostnames are mapped
if [ ! $(nslookup $(synonet --get_hostname) >/dev/null 2>&1; echo $?) -eq 0 ]; then
    # Set NFS export method (because nslookup failed to resolve PVE primary hostname)
    display_msg1="Search domain:${SEARCHDOMAIN}:Use local, home.arpa, localdomain or lan only.\nDNS Server 1:$(ip route show default | awk '/default/ {print $3}' | awk -F'.' 'BEGIN {OFS=FS} { print $1, $2, $3, "254" }'):This is your PiHole server IP address\nDNS Server 2:$(ip route show default | awk '/default/ {print $3}'):This is your network router DNS IP"
    display_msg2="/volume1/audio:${PVE_HOST_IP}(rw,sync):IP based\n/volume1/audio:${PVE_HOSTNAME}(rw,sync):Hostname based (Recommended)"

    msg "#### PLEASE READ CAREFULLY - NFS SHARED FOLDERS ####\n\nYour Proxmox primary host probably requires shared storage mountpoints to this NAS. You can choose between 'hostname' or 'IP' based NAS NFS exports.\n\nUnfortunately some network DNS servers may not map arbitrary hostnames to their static IP addresses (UniFi for example). An alternative is to configure NFS exports with 'IP' based exports when configuring NFS '/etc/exports'. Or we recommend you install a PVE CT PiHole DNS server to resolve arbitrary hostnames to their static IP addresses by adding each PVE host IP and NAS IP to the PiHole local DNS record. Also enable 'Use Conditional Forwarding' and fields and enable 'Use DNSSEC'. Your PiHole Local DNS Records will be:\n\n$(printf '%s\n' "${pve_node_LIST[@]}" | sed "$ a ${HOSTNAME_VAR},${NAS_IP}" | awk -F',' -v searchdomain="$(echo ${SEARCHDOMAIN})" 'BEGIN {OFS="\t"} { print $1"."searchdomain, $2 }' | indent2)\n\nThen edit each PVE host DNS setting ( in identical order, PiHole first ) as follows:\n\n$(echo -e "${display_msg1}" | awk -F':' 'BEGIN{OFS="\t"} {$1=$1;print}' | indent2)\n\nRemember in the event the User changes their PVE hosts IP addresses you must update the PiHole local DNS records.\n\nExamples of NFS exports is as follows:\n\n$(echo -e "${display_msg2}" | awk -F':' '{ printf "%-15s %-25s %-20s\n", $1, $2, $3 }' | indent2)"
    echo
    echo

    unset options
    options=( "Hostname Based (Recommended)" "IP Based" )
    PS3="Select a NFS export type (entering numeric) : "
    select NFS_TYPE_VAR in "${options[@]}"; do
        msg "You have assigned and set: ${YELLOW}$NFS_TYPE_VAR${NC}"
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
    # Set NFS Type var
    if [[ "$NFS_TYPE_VAR" =~ ^Hostname ]]; then
        NFS_EXPORT_TYPE=0
    elif [[ "$NFS_TYPE_VAR" =~ ^IP ]]; then
        NFS_EXPORT_TYPE=1
    fi
else
    # NFS exports set to use hostnames
    NFS_EXPORT_TYPE=0
fi

# Update NFS exports file
msg "Creating new NFS exports..."
while IFS=',' read -r dir desc user group permission inherit user_groups; do
    [[ "$dir" =~ 'none' ]] && continue
    # Check for dir
    if [ -d "$DIR_SCHEMA/$dir" ]; then
        if [[ $(grep -xs "^${DIR_SCHEMA}/${dir}.*" "$NFS_EXPORTS") ]]; then
            # Edit existing nfs export share
            while IFS=, read hostid ipaddr desc; do
                nfs_var=$(if [[ "$NFS_EXPORT_TYPE" -eq 0 ]]; then echo "${hostid}.${SEARCHDOMAIN}"; else echo "$ipaddr"; fi)
                match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" "$NFS_EXPORTS")
                if [[ $(echo "$match" | grep -ws "$nfs_var") ]]; then
                    substitute=$(echo "$match" | sed -e "s/${nfs_var}[^\t]*/${nfs_var}${NFS_STRING}/")
                    sed -i "s|${match}|${substitute}|" "$NFS_EXPORTS"
                else
                    # Add to existing nfs export share
                    substitute=$(echo "$match" | sed -e "s/$/\t${nfs_var}${NFS_STRING}/")
                    sed -i "s|${match}|${substitute}|g" "$NFS_EXPORTS"
                fi
            done < <( printf '%s\n' "${pve_node_LIST[@]}" )
            info "Updating NFS share: ${YELLOW}$DIR_SCHEMA/$dir${NC}"
        else
            # Create new nfs export share
            printf "\n"$DIR_SCHEMA/$dir"" >> "$NFS_EXPORTS"
            while IFS=, read hostid ipaddr desc; do
                nfs_var=$(if [ "$NFS_EXPORT_TYPE" -eq 0 ]; then echo "${hostid}.${SEARCHDOMAIN}"; else echo "$ipaddr"; fi)
                match=$(grep --color=never -xs "^${DIR_SCHEMA}/${dir}.*" "$NFS_EXPORTS")
                # Add to existing nfs export share
                substitute=$(echo "$match" | sed -e "s/$/\t${nfs_var}${NFS_STRING}/")
                sed -i "s|${match}|${substitute}|g" "$NFS_EXPORTS"
            done < <( printf '%s\n' "${pve_node_LIST[@]}" )
            info "New NFS share: ${YELLOW}$DIR_SCHEMA/$dir${NC}"
        fi
    else
        info "$DIR_SCHEMA/$dir does not exist. Skipping..."
    fi
done < <( printf '%s\n' "${nas_basefolder_LIST[@]}" | sed '/^backup/d' | sed '/^sshkey/d' )
echo

# Update '/etc/hosts' file
if [[ "$NFS_EXPORT_TYPE" -eq 0 ]]; then 
    while IFS=, read hostid ipaddr desc; do
        # Check if the entry already exists in /etc/hosts
        if grep -q "${hostid}\.${SEARCHDOMAIN}" /etc/hosts; then
            # Entry exists, update it
            sed -i "s/.*${hostid}\.${SEARCHDOMAIN}.*/${ipaddr} ${hostid}.${SEARCHDOMAIN} ${hostid} # ${desc}/" /etc/hosts
        else
            # Entry doesn't exist, add it
            echo "${ipaddr} ${hostid}.${SEARCHDOMAIN} ${hostid} # ${desc}" >> /etc/hosts
        fi
    done < <( printf '%s\n' "${pve_node_LIST[@]}" )
fi


# Set NFS settings
sed -i "s#^\(nfsv4_enable.*\s*=\s*\).*\$#\1yes#" /etc/nfs/syno_nfs_conf # Enable nfs4.1
sed -i "s#^\(nfs_unix_pri_enable.*\s*=\s*\).*\$#\11#" /etc/nfs/syno_nfs_conf # Enable Unix permissions

# Restart NFS
if ! [ $(systemctl status nfs-mountd.service > /dev/null; echo $?) -eq 0 ]; then
    systemctl restart nfs-mountd.service
    systemctl restart nfs-idmapd.service
fi

# Read /etc/exports
sudo exportfs -ra

#---- Enable SMB
if [ $(systemctl status pkg-synosamba-smbd.service > /dev/null; echo $?) -eq 0 ]; then
    systemctl stop pkg-synosamba-smbd.service
    systemctl stop pkg-synosamba-nmbd.service
fi

sed -i "s#\(min protocol.*\s*=\s*\).*\$#\1SMB2#" "$SMB_CONF"
sed -i "s#\(max protocol.*\s*=\s*\).*\$#\1SMB3#" "$SMB_CONF"

if ! [ $(systemctl status pkg-synosamba-smbd.service > /dev/null; echo $?) -eq 0 ]; then
    systemctl restart pkg-synosamba-smbd.service
    systemctl restart pkg-synosamba-nmbd.service
fi

#---- Enable WS-Discovery
systemctl restart pkg-synosamba-wsdiscoveryd.service
systemctl restart pkg-synosamba-wstransferd.service


#---- Set Synology Hostname
if [ "$SYNO_HOSTNAME_MOD" -eq 1 ]; then
    synonet --set_hostname "$HOSTNAME_VAR"
fi

#---- Finish Line ------------------------------------------------------------------

section "Completion Status."

msg "Success. ${HOSTNAME_VAR^} NAS is fully configured and is ready to provide NFS and/or SMB/CIFS backend storage mounts to your PVE hosts.
$(if [ "$SYNO_HOSTNAME_MOD" -eq 1 ]; then echo "  --  Synology NAS hostname has changed to: ${WHITE}$HOSTNAME_VAR${NC}\n"; fi)
More information about configuring a Synology NAS and PVE hosts is available here:

  --  ${WHITE}https://github.com/ahuacate/nas-hardmetal${NC}
  --  ${WHITE}https://github.com/ahuacate/pve-host${NC}

We recommend the User now:
  --  Enables WS-Discovery using the Synology WebGUI
      ( 'Control Panel' > 'File Services' > 'Advanced' > 'WS-Discovery' )
  --  If existing files select sub-folders, not base folder, and apply permissions
      ( 'Properties' > 'Permissions' > 'Apply to this folder, sub-folders, and files' )
  --  Reboot your Synology NAS.

If you have issues with NFS using hostnames simply re-run this script and select IP based NFS exports.

WARNING: Synology WebGUI will not show the new NFS exports. But they are working. To edit /etc/exports use nano or vi (as root). After editing type 'sudo exportfs -ra' to propogate the NFS server with any changes."
echo
#-----------------------------------------------------------------------------------