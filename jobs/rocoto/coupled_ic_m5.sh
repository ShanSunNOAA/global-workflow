#!/bin/bash

set -x

###############################################################
## Abstract:
## Create FV3 initial conditions from GFS intitial conditions
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

export DATAROOT="$RUNDIR/$CDATE/$CDUMP"
[[ ! -d $DATAROOT ]] && mkdir -p $DATAROOT

###############################################################
# Source relevant configs
configs="base fv3ic wave"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

###############################################################
# Source machine runtime environment
. $BASE_ENV/${machine}.env fv3ic
status=$?
[[ $status -ne 0 ]] && exit $status

# Create ICSDIR if needed
[[ ! -d $ICSDIR/$CDATE ]] && mkdir -p $ICSDIR/$CDATE
[[ ! -d $ICSDIR/$CDATE/atmos ]] && mkdir -p $ICSDIR/$CDATE/atmos
[[ ! -d $ICSDIR/$CDATE/ocn ]] && mkdir -p $ICSDIR/$CDATE/ocn
[[ ! -d $ICSDIR/$CDATE/ice ]] && mkdir -p $ICSDIR/$CDATE/ice

if [ $ICERES = '025' ]; then
  ICERESdec="0.25"
fi 
if [ $ICERES = '050' ]; then         
 ICERESdec="0.50"        
fi 

# Setup ATM initial condition files
##cp -r $ORIGIN_ROOT/$CPL_ATMIC/$CDATE/$CDUMP/*  $ICSDIR/$CDATE/atmos/
##ssun "replaced by l64 data" 
#/bin/cp -r /scratch2/BMC/gsd-hpcs/Shan.Sun/p6l64_cfs2fv3ic/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
 /bin/cp -r /scratch2/BMC/gsd-hpcs/Shan.Sun/p6l64_cfs2fv3ic_m5/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
##ssun "replaced by l64 data with chem" 
/bin/cp -r /scratch2/BMC/gsd-hpcs/Shan.Sun/p6l64_cfs2fv3chemic_m5/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/

/bin/cp /home/Shan.Sun/helpme/gfs_ctrl_64.nc $ICSDIR/$CDATE/atmos/C384/INPUT/gfs_ctrl.nc
##ssun:"replaced by l127 data" 
##/bin/cp -r /scratch2/BMC/gsd-hpcs/Shan.Sun/p6_cfs2fv3ic/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
##/bin/cp /home/Shan.Sun/helpme/gfs_ctrl_127.nc $ICSDIR/$CDATE/atmos/C384/INPUT/gfs_ctrl.nc

yyyy=`echo $CDATE|cut -c 1-4`
y1=2011
y2=2017
if [[ $yyyy -gt $y2  ||  $yyyy -lt $y1 ]] ; then 
  /bin/cp /scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/MOM6_ICs/MOM4_TS_restart_regular_${CDATE}.nc $ICSDIR/$CDATE/ocn/MOM6_IC_TS.nc
  /bin/cp /scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/CICE_ICs/cice5_model_0.25.res_${CDATE}.nc $ICSDIR/$CDATE/ice/cice_model_0.25.res_${CDATE}.nc
else
# Setup Ocean IC files 
  cp -r $ORIGIN_ROOT/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM*.nc $ICSDIR/$CDATE/ocn/

#Setup Ice IC files 
  cp $ORIGIN_ROOT/$CPL_ICEIC/$CDATE/ice/$ICERES/cice5_model_${ICERESdec}.res_$CDATE.nc $ICSDIR/$CDATE/ice/cice_model_${ICERESdec}.res_$CDATE.nc
fi

if [ $cplwav = ".true." ]; then
  [[ ! -d $ICSDIR/$CDATE/wav ]] && mkdir -p $ICSDIR/$CDATE/wav
  for grdID in $waveGRD
  do
    cp $ORIGIN_ROOT/$CPL_WAVIC/$CDATE/wav/$grdID/*restart.$grdID $ICSDIR/$CDATE/wav/
  done
fi

# Stage the FV3 initial conditions to ROTDIR
export OUTDIR="$ICSDIR/$CDATE/atmos/$CASE/INPUT"
COMOUT="$ROTDIR/$CDUMP.$PDY/$cyc/atmos"
[[ ! -d $COMOUT ]] && mkdir -p $COMOUT
cd $COMOUT || exit 99
rm -rf INPUT
$NLN $OUTDIR .

##############################################################
# Exit cleanly

set +x
exit 0