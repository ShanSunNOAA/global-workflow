#!/bin/ksh

#BSUB -o gfs_vminmon.o%J
#BSUB -e gfs_vminmon.o%J
#BSUB -J gfs_vminmon
#BSUB -q dev
#BSUB -M 80
#BSUB -W 00:05
#BSUB -P GFS-T2O
#BSUB -R "select[mem>80] rusage[mem=80]"
##BSUB -cwd /gpfs/hps/ptmp/Edward.Safford
##BSUB -cwd ${PWD}

set -x

export PDATE=${PDATE:-2016030700}

#############################################################
# Specify whether the run is production or development
#############################################################
export PDY=`echo $PDATE | cut -c1-8`
export cyc=`echo $PDATE | cut -c9-10`
export job=gfs_vminmon.${cyc}
export pid=${pid:-$$}
export jobid=${job}.${pid}
export envir=para


#############################################################
# Specify versions
#############################################################
export gfs_ver=${gfs_ver:-v14.1.0}
export global_shared_ver=${global_shared_ver:-v14.1.0}
export gfs_minmon_ver=${gfs_minmon_ver:-v1.0.0}
export minmon_shared_ver=${minmon_shared_ver:-v1.0.0}


#############################################################
# Load modules
#############################################################
. $MODULESHOME/init/ksh 2>>/dev/null

module load prod_util 2>>/dev/null
module load pm5 2>>/dev/null
module list 2>>/dev/null


#############################################################
# WCOSS environment settings
#############################################################
export POE=YES


#############################################################
# Set user specific variables
#############################################################
export DATAROOT=${DATAROOT:-/gpfs/hps/emc/da/noscrub/$LOGNAME/test_data}
export COMROOT=${COMROOT:-/gpfs/hps/ptmp/$LOGNAME/com}
export MINMON_SUFFIX=${MINMON_SUFFIX:-testminmon}
export NWTEST=${NWTEST:-/gpfs/hps/emc/da/noscrub/${LOGNAME}/gfs_q3fy17}
export HOMEgfs=${NWTEST}/gfs.${gfs_ver}
export JOBGLOBAL=${HOMEgfs}/jobs
export HOMEminmon=${NWTEST}/global_shared.${global_shared_ver}
export COM_IN=${DATAROOT}
export M_TANKverf=${M_TANKverf:-${COMROOT}/${MINMON_SUFFIX}}

#############################################################
# Execute job
#############################################################
$JOBGLOBAL/JGFS_VMINMON

exit

