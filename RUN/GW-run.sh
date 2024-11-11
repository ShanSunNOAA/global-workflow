#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
#ss REPO=NeilBarton-NOAA && HASH=gefs_replay_ci 
#ss #REPO=NeilBarton-NOAA && HASH=SFS 
#ss #REPO=NeilBarton-NOAA && HASH=C192 
export IDATE=2018050100
HOMEgfs=${1:-${PWD}/../}
#YAML=${2:-${HOME}/GW/YAMLS/SFS.yaml}
#ssYAML=${2:-${HOMEgfs}/ci/cases/pr/C96_S2SWA_gefs_replay_ics.yaml}
YAML=${2:-${HOMEgfs}/ci/cases/sfs/C96mx100_S2S.yaml}

########################
# Check Code
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1
echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"

########################
NPB_WORKDIR# Machine Specific and Personallized options
machine=$(uname -n)
ACCOUNT=gsd-fv3-dev
#ssexport TOPICDIR=${NPB_WORKDIR}/ICs
export TOPICDIR=/scratch2/NCEPDEV/stmp1/Neil.Barton/ICs
export RUNTESTS=${HOMEgfs}
[[ ${machine:0:3} == hfe ]] && m=hera && RUNDIRS=/scratch1/NCEPDEV/stmp2/Neil.Barton/RUNDIRS && ACCOUNT=marine-cpu
[[ ${machine} == *[cd]login* ]] && m=wcoss2 && ACCOUNT=GFS-DEV 
[[ ${machine} == *Orion* ]] && m=orion && RUNDIRS=/work/noaa/stmp/nbarton/ORION/RUNDIRS
[[ ${machine} == hercules* ]] && m=hercules && RUNDIRS=/work/noaa/stmp/nbarton/HERCULES/RUNDIRS

############
# set up run
#ss export pslot=${HASH}_$(basename ${YAML/.yaml*})
export pslot=orig
CD=$(dirname "$0")
source ${HOMEgfs}/ci/platforms/config.${m/.*}
source ${HOMEgfs}/workflow/gw_setup.sh
export HPC_ACCOUNT=${ACCOUNT}
export YAML_DIR=${HOMEgfs}
${HOMEgfs}/workflow/create_experiment.py --yaml "${YAML}" 

################################################
# Soft link items into expdir for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
set -u
cd ${TOPEXPDIR}
ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS
ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -sf ${HOMEgfs}/workflow/setup_xml.py . 
ln -sf ${HOMEgfs}/workflow/rocoto_viewer.py .

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
## rocotorun -d ${db_file} -w ${xml_file}
## crontab -l | cat - ${cron_file} | crontab -
# echo crontab file
## echo "db=${db_file}"
## echo "xml=${xml_file}"
