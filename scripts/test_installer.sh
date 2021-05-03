#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_medialab_ct_kodi-rsync_serveraddclient.sh
# Description:  This script is for creating a Kodi-Rsync Client
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-medialab/master/scripts/pve_medialab_ct_kodi-rsync_serveraddclient.sh)"

#---- Source -----------------------------------------------------------------------

# Set Temp Folder
if [ -z "${TEMP_DIR+x}" ]; then
  TEMP_DIR=$(mktemp -d)
  cd $TEMP_DIR >/dev/null
else
  if [ $(pwd -P) != $TEMP_DIR ]; then
    cd $TEMP_DIR >/dev/null
  fi
fi

wget https://github.com/ahuacate/nas-oem-setup/archive/refs/heads/master.tar.gz
tar -zxvf master.tar.gz

source ${TEMP_DIR}/nas-oem-setup-master/scripts/test.sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
PVE_SOURCE="$DIR/../../common/pve/source"
echo "Here is DIR: ${DIR}"
PVE_SOURCE="$DIR/../../common/pve/source"
echo "Here is DIR: ${PVE_SOURCE}"
