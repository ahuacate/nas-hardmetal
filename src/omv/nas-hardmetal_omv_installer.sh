#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     nas-hardmetal_omv_installer.sh
# Description:  Setup script to build a OMV NAS
#
# Usage:        SSH into OMV. Login as 'root'.
# ----------------------------------------------------------------------------------
#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Easy Script Section Head
SECTION_HEAD='OMV NAS'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Functions --------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

# #---- Run Bash Header
# source ${COMMON_PVE_SRC_DIR}/pvesource_bash_defaults.sh

#---- Introduction
section "Introduction"

msg_box "#### PLEASE READ CAREFULLY ####
This script will fully setup your OMV NAS to support Proxmox NFS or CIFS/SMB backend storage pools (PVESM). This installer can be run on new and existing OMV builds. When run on existing builds all ahuacate defaults will be restored.

Requirements:
  -- A existing OMV file storage system ready for NAS folder shares
     (recommend you read our guide)

OMV configuration modification/changes includes:
  -- Set general OMV settings ( update, community addons, OMV-Extras, locale )
  -- User Groups ( create: medialab, homelab, privatelab, chrootjail, sftp-access )
  -- Users ( create: media, home, private - default CT App user accounts )
  -- Create all required shared folders required by Ahuacate CTs & VMs
  -- Create all required sub-folders
  -- Set new folder share permissions, chattr and ACLs ( including Users and Group rights )
  -- Create NFS exports to Proxmox primary and secondary host nodes
  -- Enable NFS4 and NFS Unix permissions
  -- Enable SMB with 'min protocol=SMB2' & 'max protocol=SMB3'
  -- Validate OMV hostname, search domain and more
  -- Perform a OMV update

User input is required in the next steps to set NFS export settings. This script will not delete any existing NAS folders or files BUT may modify file access permissions on existing shared folders. It is recommended you make a full NAS file and settings backup before proceeding."
echo
echo
while true; do
  read -p "Proceed with your OMV NAS setup [y/n]?: " -n 1 -r YN
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

#---- Run setup
source ${COMMON_DIR}/nas/src/nas_omv_setup.sh
#-----------------------------------------------------------------------------------