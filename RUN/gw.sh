#!/bin/sh
set -u
#ssun this file is located under HOMEgfs/RUN and only pslot needs to be edited
#
####################################
# set up GW runs with YAML file
####################################
# Code
HOMEgfs=${1:-${PWD}/../}
YAML=${2:-${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_CPC_ICS.yaml}
export HPC_ACCOUNT=gsd-fv3-dev

########################
# for hera
export TOPICDIR=/scratch2/NCEPDEV/ensemble/Xiaqiong.Zhou/noscrub/data/SFSICS

#ssun export RUNTESTS=/scratch3/BMC/gsd-fv3-dev/$USER/sfs_kate
export RUNTESTS=$HOMEgfs

########################
# Check Code
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1

echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"
export pslot=skin_c192

source ${HOMEgfs}/dev/ush/gw_setup.sh
echo $HPC_ACCOUNT
${HOMEgfs}/dev/workflow/create_experiment.py -y "${YAML}"
