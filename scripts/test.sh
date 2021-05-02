#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_medialab_ct_kodi-rsync_serveraddclient.sh
# Description:  This script is for creating a Kodi-Rsync Client
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-medialab/master/scripts/pve_medialab_ct_kodi-rsync_serveraddclient.sh)"

#---- Source -----------------------------------------------------------------------

script="`readlink -f "${BASH_SOURCE[0]}"`"
dir="`dirname "$script"`"

echo ${dir}
