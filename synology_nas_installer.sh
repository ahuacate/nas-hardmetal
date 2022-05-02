#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     synology_nas_installer.sh
# Description:  Installer script for configuring a Synology DiskStation NAS
#
# Usage:        SSH into Synology. Login as 'admin'.
#               Then type cmd 'sudo -i' to run as root. Use same pwd as admin.
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/nas-hardmetal/master/synology_nas_installer.sh)"

#---- Source local Git
# /volume1/git/ahuacate/nas-hardmetal/synology_nas_installer.sh

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root.\nSSH into Synology. Login as 'admin'.\nThen type cmd 'sudo -i' to run as root. Use same pwd as admin.\nTry again. Bye..."
   sleep 3
   exit 1
fi

# Check for Internet connectivity
if ping -c 2 -q google.com &> /dev/null; then
  echo
else
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your Synology internet connection and try again..."
  echo
  exit 0
fi

# # Installer cleanup
# function installer_cleanup () {
# cd /tmp
# rm -R ${TEMP_DIR} &> /dev/null
# unset TEMP_DIR
# }

# Installer cleanup
function installer_cleanup () {
rm -R ${REPO_TEMP}/${GIT_REPO} &> /dev/null
rm ${REPO_TEMP}/${GIT_REPO}.tar.gz &> /dev/null
}

#---- Static Variables -------------------------------------------------------------

# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='nas-hardmetal'
# Git branch
GIT_BRANCH='master'
# Git common
GIT_COMMON='0'
# Installer App script
GIT_APP_SCRIPT='synology_nas_setup.sh'

# # Set Bash Temp Folder
# if [ -z "${TEMP_DIR+x}" ]; then
#     TEMP_DIR=$(mktemp -d)
#     pushd $TEMP_DIR > /dev/null
# else
#     if [ $(pwd -P) != $TEMP_DIR ]; then
#     cd $TEMP_DIR > /dev/null
#     fi
# fi

# Set Package Installer Temp Folder
REPO_TEMP='/tmp'
cd ${REPO_TEMP}

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------

# #---- Package loader
# if [ -f /volume1/git/${GIT_USER}/developer_settings.git ] && [ -f /volume1/git/${GIT_USER}/${GIT_REPO}/synology_nas_installer.sh ]; then
#   # Copy files from Synology Git
#   cp /volume1/git/${GIT_USER}/${GIT_REPO}/src/synology/synology_nas_setup.sh ${TEMP_DIR}/synology_nas_setup.sh
#   cp /volume1/git/${GIT_USER}/${GIT_REPO}/common/nas/src/nas_basefolderlist ${TEMP_DIR}/nas_basefolderlist
#   cp /volume1/git/${GIT_USER}/${GIT_REPO}/common/nas/src/nas_basefoldersubfolderlist ${TEMP_DIR}/nas_basefoldersubfolderlist
#   chmod +x ${TEMP_DIR}/synology_nas_setup.sh
# else
#   # Download from Github
#   wget -qL - https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/master/src/synology/synology_nas_setup.sh -O ${TEMP_DIR}/synology_nas_setup.sh
#   wget -qL - https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/master/common/nas/src/nas_basefolderlist -O ${TEMP_DIR}/nas_basefolderlist
#   wget -qL - https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/master/common/nas/src/nas_basefoldersubfolderlist -O ${TEMP_DIR}/nas_basefoldersubfolderlist
#   chmod +x ${TEMP_DIR}/synology_nas_setup.sh
# fi

#---- Package loader
if [ -f /mnt/pve/nas-*[0-9]-git/${GIT_USER}/developer_settings.git ] && [ -f /mnt/pve/nas-*[0-9]-git/${GIT_USER}/${GIT_REPO}/common/bash/src/pve_repo_loader.sh ]; then
  # Developer Options loader
  source /mnt/pve/nas-*[0-9]-git/${GIT_USER}/${GIT_REPO}/common/bash/src/pve_repo_loader.sh
else
  # Download Github loader
  wget -qL - https://raw.githubusercontent.com/${GIT_USER}/common/master/bash/src/pve_repo_loader.sh -O ${REPO_TEMP}/pve_repo_loader.sh
  chmod +x ${REPO_TEMP}/pve_repo_loader.sh
  source ${REPO_TEMP}/pve_repo_loader.sh
fi

#---- Body -------------------------------------------------------------------------

# #---- Run Installer
# source ${TEMP_DIR}/${GIT_APP_SCRIPT}

#---- Run Installer
chmod +x ${REPO_TEMP}/${GIT_REPO}/src/${GIT_APP_SCRIPT}
${REPO_TEMP}/${GIT_REPO}/src/${GIT_APP_SCRIPT}

#---- Finish Line ------------------------------------------------------------------
#--- Cleanup
installer_cleanup