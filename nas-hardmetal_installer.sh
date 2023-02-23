#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     nas-hardmetal_installer.sh
# Description:  Installer script for NAS Hardmetal setups
# Notes:        Do NOT upgrade to installer scripts.
#               This installer uses simple BASH language (for multi OS)
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/nas-hardmetal/main/nas-hardmetal_installer.sh)"

#---- Source local Git
# /volume1/git/ahuacate/nas-hardmetal/nas-hardmetal_installer.sh
# /srv/<uuid>/ahuacate/nas-hardmetal/nas-hardmetal_installer.sh

#---- Source -----------------------------------------------------------------------

# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='nas-hardmetal'
# Git branch
GIT_BRANCH='main'
# Git common
GIT_COMMON='0'

#---- Dependencies -----------------------------------------------------------------

#---- Check for Internet connectivity

# List of well-known websites to test connectivity (in case one is blocked)
# Do NOT change to use 'nc'. Synology and OMV only use ping.
websites=( "google.com" "github.com" "cloudflare.com" "apple.com" "amazon.com" )
# Loop through each website in the list
for website in "${websites[@]}"
do
  # Test internet connectivity
  ping -c1 $website > /dev/null 2>&1
  # Check the exit status of the ping command
  if [ $? = 0 ]
  then
    # Flag to track if internet connection is up
    connection_up=0
    break
  else
  # Flag to track if internet connection is down
  connection_up=1
  fi
done
# On connection fail
if [ "$connection_up" = 1 ]
then
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your PVE hosts internet connection and try again..."
  echo
  exit 0
fi

#---- Static Variables -------------------------------------------------------------

#---- Set Package Installer Temp Dir 

# Set 'rep_temp' dir
REPO_TEMP='/tmp'
# Change to 'repo temp' dir
cd $REPO_TEMP

#---- Script path variables

DIR="$REPO_TEMP/$GIT_REPO"
SRC_DIR="$DIR/src"
COMMON_DIR="$DIR/common"
COMMON_PVE_SRC_DIR="$DIR/common/pve/src"
SHARED_DIR="$DIR/shared"
TEMP_DIR="$DIR/tmp"


#---- Terminal settings

RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
WHITE=$'\033[1;37m'
NC=$'\033[0m'
UNDERLINE=$'\033[4m'
printf '\033[8;40;120t'

#---- Local Repo path (check if local)

# For local SRC a 'developer_settings.git' file must exist in repo dir
REPO_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P | sed "s/${GIT_USER}.*/$GIT_USER/" )"

#---- Other Variables --------------------------------------------------------------

# List of Hardmetal NAS OS. Edit this list to control the available NAS installer.
# First field must match git_app_script filename 'nas_<name>_installer.sh'
# Second field is menu description only
nas_LIST=( "synology:Synology DiskStation"
"omv:Open Media Vault (OMV)"
"TYPE00:None - Exit this installer" )

# Easy Script Section Header Body Text
SECTION_HEAD='PVE NAS Hardmetal'

#---- Other Files ------------------------------------------------------------------

#---- Package loader
if [ -f "$REPO_PATH/common/bash/src/linux_repo_loader.sh" ] && [ "$(sed -n 's/^dev_git_mount=//p' $REPO_PATH/developer_settings.git 2> /dev/null)" = 0 ]
then
  # Download Local loader (developer)
  source $REPO_PATH/common/bash/src/linux_repo_loader.sh
else
  # Download Github loader
  wget -qL - https://raw.githubusercontent.com/$GIT_USER/common/main/bash/src/linux_repo_loader.sh -O $REPO_TEMP/linux_repo_loader.sh
  chmod +x $REPO_TEMP/linux_repo_loader.sh
  source $REPO_TEMP/linux_repo_loader.sh
fi

#---- Functions --------------------------------------------------------------------

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

#---- Installer cleanup
function installer_cleanup() {
rm -R $REPO_TEMP/$GIT_REPO &> /dev/null
if [ -f "$REPO_TEMP/${GIT_REPO}.tar.gz" ]
then
  rm $REPO_TEMP/${GIT_REPO}.tar.gz > /dev/null
fi
}


#---- Body -------------------------------------------------------------------------
# Do not edit here down

#---- Run Installer

section "Select a NAS OS Product"

msg "#### SELECT A PRODUCT INSTALLER ####\n\nSelect a installer or service from the list or 'None - Exit this installer' to leave.\n\nAny terminal inactivity is caused by background tasks be run, system updating or downloading of Linux files. So be patient because some tasks can be slow."
echo
# Create menu list
unset options
mapfile -t options < <( printf '%s\n' "${nas_LIST[@]}" | awk -F':' '{ print $2 }' )
PS3="Select a NAS type (entering numeric) : "
select i in "${options[@]}"; do
  [[ -n $i ]] && break || {
      echo "Invalid input. Try again..."
  }
done
n=$((${REPLY}-1))
RESULTS=$(echo "${nas_LIST[$n]}" | awk -F':' '{ print $1 }')
# Display selected
echo "User has selected:"
printf '    %s\n' ${YELLOW}"${i}"${NC}
echo

#---- Run the NAS installer
if [ "$RESULTS" = 'TYPE00' ]
then
  # Exit installation
  msg "You have chosen not to proceed. Aborting. Bye..."
  echo
  sleep 1
elif [ "$RESULTS" = 'omv' ]
then
  # Set Installer App script name
  git_app_script="${GIT_REPO}_${RESULTS,,}_installer.sh"
  chmod +x "$SRC_DIR/${RESULTS,,}/$git_app_script"

  #---- Run Bash Header
  source $COMMON_PVE_SRC_DIR/pvesource_bash_defaults.sh

  #---- Run Installer
  source $SRC_DIR/${RESULTS,,}/$git_app_script
else
  # Set Installer App script name
  git_app_script="${GIT_REPO}_${RESULTS,,}_installer.sh"
  chmod +x "$SRC_DIR/${RESULTS,,}/$git_app_script"

  #---- Run Installer
  source $SRC_DIR/${RESULTS,,}/$git_app_script
fi

#---- Finish Line ------------------------------------------------------------------

#---- Cleanup
installer_cleanup
#-----------------------------------------------------------------------------------