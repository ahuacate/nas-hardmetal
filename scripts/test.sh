#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_medialab_ct_kodi-rsync_serveraddclient.sh
# Description:  This script is for creating a Kodi-Rsync Client
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-medialab/master/scripts/pve_medialab_ct_kodi-rsync_serveraddclient.sh)"

#---- Source -----------------------------------------------------------------------
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
PVE_SOURCE="$DIR/../../common/pve/source"
echo ${DIR}
