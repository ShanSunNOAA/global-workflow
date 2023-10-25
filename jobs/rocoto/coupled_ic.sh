#! /usr/bin/env bash

source "$HOMEgfs/ush/preamble.sh"

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
err=0

###############################################################
# Source relevant configs
configs="base coupled_ic wave"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

###############################################################
# Source machine runtime environment
. $BASE_ENV/${machine}.env config.coupled_ic
status=$?
[[ $status -ne 0 ]] && exit $status

atm_ic=3  #Jieshun
atm_ic=1  #cfsr p8

me_wave=0

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
if [ $ICERES = '100' ]; then         
 ICERESdec="1.00"        
fi 

echo "$CASE"
# Setup ATM initial condition files
if [[ $CASE = 'C384' ]]; then
  cp -r $BASE_CPLIC/$CPL_ATMIC/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
fi
if [[ $CASE = 'C192' || $CASE = 'C96' ]]; then
  if [[ ${machine} = 'HERA' ]]; then
   if [[ $atm_ic -eq 3 ]]; then
    cp -r /scratch1/BMC/gsd-fv3-dev/fv3data/IC/jzhu/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
   else
    cp -r /scratch1/BMC/gsd-fv3-dev/fv3ic/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
   fi
  else
    cp -r /work2/noaa/wrfruc/Shan.Sun/fv3ic/$CDATE/$CDUMP/* $ICSDIR/$CDATE/atmos/
  fi
fi

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo "FATAL: Unable to copy $BASE_CPLIC/$CPL_ATMIC/$CDATE/$CDUMP/* to $ICSDIR/$CDATE/atmos/ (Error code $rc)" 
fi
err=$((err + rc))

# Setup Ocean IC files 
if [ $ocn_ic -eq 0 ]; then
 if [ $OCNRES -eq 100 ]; then   # use cfsr temporarily
   ln -sf /scratch1/BMC/gsd-fv3-dev/ocndata/MOM6_IC_TS.nc        $ICSDIR/$CDATE/ocn/
   rc=$?
 fi
fi

if [ $ocn_ic -eq 1 ]; then
 if [ $OCNRES -eq 100 ]; then   # use cfsr temporarily
   ln -sf /scratch1/BMC/gsd-fv3-dev/ocndata/MOM6_IC_TS.nc        $ICSDIR/$CDATE/ocn/
   rc=$?
 else
#ssun cp -r $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM*.nc  $ICSDIR/$CDATE/ocn/
   ln -sf $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM.res_1.nc $ICSDIR/$CDATE/ocn/
   ln -sf $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM.res_2.nc $ICSDIR/$CDATE/ocn/
   ln -sf $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM.res_3.nc $ICSDIR/$CDATE/ocn/
   ln -sf $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM.res_4.nc $ICSDIR/$CDATE/ocn/
   ln -sf $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM.res.nc   $ICSDIR/$CDATE/ocn/
   rc=$?
 fi
fi

if [ $ocn_ic -eq 2 ]; then
  if [[ ${machine} = 'HERA' ]]; then
    ln -sf /scratch2/BMC/gsd-fv3-test/Shan.Sun/oras5/$PDY/ORAS5.mx$OCNRES.ic.nc $ICSDIR/$CDATE/ocn/
  else
    ln -sf         /work2/noaa/wrfruc/Shan.Sun/oras5/$PDY/ORAS5.mx$OCNRES.ic.nc $ICSDIR/$CDATE/ocn/
  fi 
 ## cd $ICSDIR/$CDATE/ocn/
 ## hsi get /ESRL/BMC/fim/5year/Shan.Sun/Pegion_oras5/$PDY.zip
 ## unzip $PDY.zip
 ## /bin/rm $PDY.zip
  rc=$?
fi 

if [ $ocn_ic -eq 3 ]; then
  ln -sf /scratch2/BMC/gsd-fv3-test/Shan.Sun/GLORe/${PDY}12/ctrl/MOM.res.nc $ICSDIR/$CDATE/ocn/
  rc=$?
fi

if [[ $rc -ne 0 ]] ; then
 if [ $ocn_ic -eq 1 ]; then
  echo "FATAL: Unable to copy $BASE_CPLIC/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM*.nc to $ICSDIR/$CDATE/ocn/ (Error code $rc)"
 fi
 if [ $ocn_ic -eq 2 ]; then
  echo "FATAL: Unable to copy /scratch2/BMC/gsd-fv3-test/Shan.Sun/ORAS5/$PDY/ORAS5.mx$OCNRES.ic.nc to $ICSDIR/$CDATE/ocn/ (Error code $rc)"
 fi
fi
err=$((err + rc))

#Setup Ice IC files 
 if [ $ice_ic -eq 1 ]; then
   iceic=/scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/CICE_ICs/cice5_model_1.00.cpc.res_${PDY}00.nc
 fi
 if [ $ice_ic -eq 2 ]; then
   if [[ ${machine} = 'HERA' ]]; then
     iceic=/scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/oras5b_ice/oras5b_ice_${PDY}_mx${OCNRES}.nc
   else
                  iceic=/work2/noaa/wrfruc/Shan.Sun/oras5b_ice/oras5b_ice_${PDY}_mx${OCNRES}.nc
   fi
 fi
 if [ $ice_ic -eq 3 ]; then
   iceic=/scratch2/BMC/gsd-fv3-test/Shan.Sun/GLORe/${PDY}12/ctrl/iced.${PDY}-43200.nc
 fi
 echo "ice IC: ${iceic} to $ICSDIR/$CDATE/ice/cice_model_${ICERESdec}.res_$CDATE.nc "
 if [[ -f ${iceic} ]]; then
   cp ${iceic} $ICSDIR/$CDATE/ice/cice_model_${ICERESdec}.res_$CDATE.nc
   rc=$?
##ss else 
##ss if [[ -f $BASE_CPLIC/$CPL_ICEIC/$CDATE/ice/$ICERES/cice5_model_${ICERESdec}.res_$CDATE.nc ]]; then
 else
   cp $BASE_CPLIC/$CPL_ICEIC/$CDATE/ice/$ICERES/cice5_model_${ICERESdec}.res_$CDATE.nc $ICSDIR/$CDATE/ice/cice_model_${ICERESdec}.res_$CDATE.nc
   rc=$?
##ss   cp /scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/CICE_ICs_mx025/cice5_model_${ICERESdec}.res_$CDATE.nc $ICSDIR/$CDATE/ice/cice_model_${ICERESdec}.res_$CDATE.nc
##ss   rc=$?
 fi

if [[ $rc -ne 0 ]] ; then
  echo "FATAL: Unable to copy ${iceic} Error code $rc "
fi
err=$((err + rc))

if [ $me_wave -eq 1 ]; then
if [ $DO_WAVE = "YES" ]; then
  [[ ! -d $ICSDIR/$CDATE/wav ]] && mkdir -p $ICSDIR/$CDATE/wav
  for grdID in $waveGRD
  do
    cp $BASE_CPLIC/$CPL_WAVIC/$CDATE/wav/$grdID/*restart.$grdID $ICSDIR/$CDATE/wav/
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "FATAL: Unable to copy $BASE_CPLIC/$CPL_WAVIC/$CDATE/wav/$grdID/*restart.$grdID to $ICSDIR/$CDATE/wav/  Error code $rc " 
    fi
    err=$((err + rc))
  done
fi
fi

# Stage the FV3 initial conditions to ROTDIR
export OUTDIR="$ICSDIR/$CDATE/atmos/$CASE/INPUT"
COMOUT="$ROTDIR/$CDUMP.$PDY/$cyc/atmos"
[[ ! -d $COMOUT ]] && mkdir -p $COMOUT
cd $COMOUT || exit 99
rm -rf INPUT
$NLN $OUTDIR .

#Stage the WW3 initial conditions to ROTDIR 
if [ $DO_WAVE = "YES" ]; then
  export OUTDIRw="$ICSDIR/$CDATE/wav"
  COMOUTw="$ROTDIR/$CDUMP.$PDY/$cyc/wave/restart"
  [[ ! -d $COMOUTw ]] && mkdir -p $COMOUTw
  cd $COMOUTw || exit 99
#ssun:start wave at rest  $NLN $OUTDIRw/* .
fi

if  [[ $err -ne 0 ]] ; then 
  echo "Fatal Error: ICs are not properly set-up" 
  exit $err 
fi 

##############################################################
# Exit cleanly


exit 0
