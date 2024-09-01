#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
export IDATE=1994050100
HOMEgfs=${1:-${PWD}/../}
YAML=${2:-${HOMEgfs}/RUN/SFS.yaml}
FULL_BASELINE=F # Run all forecasts

########################
# Machine Specific and Personallized options
machine=$(uname -n)
ACCOUNT=gsd-fv3-dev
if [[ ${machine:0:3} == hfe ]]; then
    export TOPICDIR=/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs
    export RUNTESTS=${HOMEgfs}
elif [[ ${machine} == hercules* ]]; then 
    export TOPICDIR=/work/noaa/marine/nbarton/ICs
    export RUNTESTS=${HOMEgfs}
fi

########################
# Check Code
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1
echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"
export pslot=c96mx100

########################
# Set Up Experiment
source ${HOMEgfs}/workflow/gw_setup.sh
export HPC_ACCOUNT=${ACCOUNT}
${HOMEgfs}/workflow/create_experiment.py --yaml "${YAML}" 

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
cd ${TOPEXPDIR}
set -u
ln -s ${DATAROOT} DATAROOT
ln -s ${HOMEgfs} GW-CODE
ln -s ${HOMEgfs}/parm/config ORIG_CONFIGS
ln -s ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -s ${HOMEgfs}/workflow/setup_xml.py . 
ln -s ${HOMEgfs}/workflow/rocoto_viewer.py .

################################################
# All forecasts?
if [[ ${FULL_BASELINE} == T ]]; then
    f=${TOPEXPDIR}/*xml
    echo ${f}
    line=$(grep -n 'cycledef group' ${f} | cut -d: -f1) 
    sed -i ${line}d $f
    MONTHS="05 11"
    for Y in $(seq 1994 2023); do
        for M in ${MONTHS}; do 
            text="<cycledef group="gefs">${Y}${M}010000 ${Y}${M}010000 24:00:00</cycledef>"
            sed -i "${line} i   ${text}" ${f}
            line=$(( line + 1))
        done
    done
    exit 1
fi

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
## rocotorun -d ${db_file} -w ${xml_file}
## crontab -l | cat - ${cron_file} | crontab -
# echo crontab file
## echo "db=${db_file}"
## echo "xml=${xml_file}"
