#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_medialab_ct_kodi-rsync_serveraddclient.sh
# Description:  This script is for creating a Kodi-Rsync Client
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-medialab/master/scripts/pve_medialab_ct_kodi-rsync_serveraddclient.sh)"

#---- Source -----------------------------------------------------------------------

source <(curl -s https://raw.githubusercontent.com/ahuacate/common/master/pve/source/pvesource_bash_defaults.sh)

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PVE_SOURCE="$DIR/../../common/pve/source"
info "Here is DIR: ${YELLOW}${DIR}${NC}"
info "Here is PVE_SOURCE: ${PVE_SOURCE}"
info "Here is TEMP_DIR: ${TEMP_DIR}"
