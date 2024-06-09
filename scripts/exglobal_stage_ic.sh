#!/usr/bin/env bash

source "${USHgfs}/preamble.sh"

# Locally scoped variables and functions
# shellcheck disable=SC2153
GDATE=$(date --utc -d "${PDY} ${cyc} - ${assim_freq} hours" +%Y%m%d%H)
gPDY="${GDATE:0:8}"
gcyc="${GDATE:8:2}"

MEMDIR_ARRAY=()
if [[ "${RUN:-}" = "gefs" ]]; then
  # Populate the member_dirs array based on the value of NMEM_ENS
  for ((ii = 0; ii <= "${NMEM_ENS:-0}"; ii++)); do
    MEMDIR_ARRAY+=("mem$(printf "%03d" "${ii}")")
  done
else
  MEMDIR_ARRAY+=("")
fi

# Initialize return code
err=0

error_message() {
  echo "FATAL ERROR: Unable to copy ${1} to ${2} (Error code ${3})"
}

###############################################################
  echo "CASE= $CASE"
  echo "LEVS= $LEVS"
  atmic=2 #cfsr,  1=default
  ocnic=3 #GLORe, 1=default
  ocnic=2 #oras5, 1=default
  if [[ $CASE = 'C96' ]]; then
    iceic=3
    iceic=2
  else
    iceic=1
  fi

for MEMDIR in "${MEMDIR_ARRAY[@]}"; do

  # Stage atmosphere initial conditions to ROTDIR
  if [[ ${EXP_WARM_START:-".false."} = ".true." ]]; then
    # Stage the FV3 restarts to ROTDIR (warm start)
    RUN=${rCDUMP} YMD=${gPDY} HH=${gcyc} declare_from_tmpl COM_ATMOS_RESTART_PREV:COM_ATMOS_RESTART_TMPL
    [[ ! -d "${COM_ATMOS_RESTART_PREV}" ]] && mkdir -p "${COM_ATMOS_RESTART_PREV}"
    for ftype in coupler.res fv_core.res.nc; do
      src="${BASE_CPLIC}/${CPL_ATMIC:-}/${PDY}${cyc}/${MEMDIR}/atmos/${PDY}.${cyc}0000.${ftype}"
      tgt="${COM_ATMOS_RESTART_PREV}/${PDY}.${cyc}0000.${ftype}"
      ${NCP} "${src}" "${tgt}"
      rc=$?
      ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
      err=$((err + rc))
    done
    for ftype in ca_data fv_core.res fv_srf_wnd.res fv_tracer.res phy_data sfc_data; do
      for ((tt = 1; tt <= ntiles; tt++)); do
        src="${BASE_CPLIC}/${CPL_ATMIC:-}/${PDY}${cyc}/${MEMDIR}/atmos/${PDY}.${cyc}0000.${ftype}.tile${tt}.nc"
        if (( tt > 6 )) ; then
            tgt="${COM_ATMOS_RESTART_PREV}/${PDY}.${cyc}0000.${ftype}.nest0$((tt-5)).tile${tt}.nc"
        else
            tgt="${COM_ATMOS_RESTART_PREV}/${PDY}.${cyc}0000.${ftype}.tile${tt}.nc"
        fi
        ${NCP} "${src}" "${tgt}"
        rc=$?
        ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
        err=$((err + rc))
      done
    done
  else
    # Stage the FV3 cold-start initial conditions to ROTDIR
    YMD=${PDY} HH=${cyc} declare_from_tmpl COM_ATMOS_INPUT
    [[ ! -d "${COM_ATMOS_INPUT}" ]] && mkdir -p "${COM_ATMOS_INPUT}"
    if [[ $atmic -eq 1 ]] ; then
     src="${BASE_CPLIC}/${CPL_ATMIC:-}/${PDY}${cyc}/${MEMDIR}/atmos/gfs_ctrl.nc"
     src="/scratch1/NCEPDEV/climate/role.ufscpara/IC/GEFS-NoahMP-aerosols-p8c/$CDATE/$CDUMP/${CASE}/INPUT/gfs_ctrl.nc"
    fi
    if [[ $atmic -eq 2 ]] ; then
     if [[ ${machine} = 'HERA' ]]; then
       src="/scratch1/BMC/gsd-fv3-dev/fv3ic/$CDATE/$CDUMP/${CASE}L${LEVS}/INPUT/gfs_ctrl.nc"
     else
       src="/work2/noaa/wrfruc/Shan.Sun/fv3ic/$CDATE/$CDUMP/${CASE}L${LEVS}/INPUT/gfs_ctrl.nc"
     fi
    fi
    tgt="${COM_ATMOS_INPUT}/gfs_ctrl.nc"
    ${NCP} "${src}" "${tgt}"
    rc=$?
    ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
    err=$((err + rc))
    for ftype in gfs_data sfc_data; do
      for ((tt = 1; tt <= ntiles; tt++)); do
        if [[ $atmic -eq 1 ]] ; then
          if [[ $CASE = 'C384' ]]; then
            src="${BASE_CPLIC}/${CPL_ATMIC:-}/${PDY}${cyc}/${MEMDIR}/atmos/${ftype}.tile${tt}.nc"
            src="/scratch1/NCEPDEV/climate/role.ufscpara/IC/GEFS-NoahMP-aerosols-p8c/$CDATE/$CDUMP/${CASE}/INPUT/${ftype}.tile${tt}.nc"
          fi
        fi
        if [[ $atmic -eq 2 ]] ; then
          if [[ ${machine} = 'HERA' ]]; then
            src1="/scratch1/BMC/gsd-fv3-dev/fv3ic/$CDATE/$CDUMP/${CASE}L128/INPUT/${ftype}.tile${tt}.nc"
            src2="/scratch1/BMC/gsd-fv3-dev/fv3ic/$CDATE/$CDUMP/${CASE}L${LEVS}/INPUT/${ftype}.tile${tt}.nc"
          else
            src1="/work2/noaa/wrfruc/Shan.Sun/fv3ic/$CDATE/$CDUMP/${CASE}L128/INPUT/${ftype}.tile${tt}.nc"
            src2="/work2/noaa/wrfruc/Shan.Sun/fv3ic/$CDATE/$CDUMP/${CASE}L${LEVS}/INPUT/${ftype}.tile${tt}.nc"
          fi
        fi
        if [[ ${ftype} = 'sfc_data' ]]; then 
          src=$src1
        else
          src=$src2
        fi
        tgt="${COM_ATMOS_INPUT}/${ftype}.tile${tt}.nc"
        ${NCP} "${src}" "${tgt}"
    #ss  if [[ ${ftype} = 'sfc_data' && ${atmic} = 1 ]]; then 
    #ss    ncrename -d xaxis_1,lon -d yaxis_1,lat -d zaxis_1,lsoil ${COM_ATMOS_INPUT}/${ftype}.tile${tt}.nc
    #ss  fi
        rc=$?
        ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
        err=$((err + rc))
      done
      if (( ntiles > 6 )); then
        ${NLN} "${COM_ATMOS_INPUT}/${ftype}.tile7.nc" "${COM_ATMOS_INPUT}/${ftype}.nest02.tile7.nc"
      fi
    done
  fi

  # Stage ocean initial conditions to ROTDIR (warm start)
  if [[ "${DO_OCN:-}" = "YES" ]]; then
    RUN=${rCDUMP} YMD=${gPDY} HH=${gcyc} declare_from_tmpl COM_OCEAN_RESTART_PREV:COM_OCEAN_RESTART_TMPL
    [[ ! -d "${COM_OCEAN_RESTART_PREV}" ]] && mkdir -p "${COM_OCEAN_RESTART_PREV}"
   if [[ $ocnic -eq 1 ]] ; then
    src="${BASE_CPLIC}/${CPL_OCNIC:-}/${PDY}${cyc}/${MEMDIR}/ocean/${PDY}.${cyc}0000.MOM.res.nc"
    tgt="${COM_OCEAN_RESTART_PREV}/${PDY}.${cyc}0000.MOM.res.nc"
    ${NCP} "${src}" "${tgt}"
    rc=$?
    ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
    err=$((err + rc))
    case "${OCNRES}" in
      "500" | "100")
        # Nothing more to do for these resolutions
        ;;
      "025" )
        for nn in $(seq 1 3); do
          src="${BASE_CPLIC}/${CPL_OCNIC:-}/${PDY}${cyc}/${MEMDIR}/ocean/${PDY}.${cyc}0000.MOM.res_${nn}.nc"
          tgt="${COM_OCEAN_RESTART_PREV}/${PDY}.${cyc}0000.MOM.res_${nn}.nc"
          ${NCP} "${src}" "${tgt}"
          rc=$?
          ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
          err=$((err + rc))
        done
        ;;
      *)
        echo "FATAL ERROR: Unsupported ocean resolution ${OCNRES}"
        rc=1
        err=$((err + rc))
        ;;
     esac
   fi

    if [[ $ocnic -eq 2 ]] ; then
      if [[ ${machine} = 'HERA' ]]; then
        src="/scratch2/BMC/gsd-fv3-test/Shan.Sun/oras5/$PDY/ORAS5.mx$OCNRES.ic.nc"
      else
        src="/work2/noaa/wrfruc/Shan.Sun/oras5/$PDY/ORAS5.mx$OCNRES.ic.nc"
      fi
      tgt="${COM_OCEAN_RESTART_PREV}/"
    fi

    if [[ $ocnic -eq 3 ]] ; then
      if [[ ${machine} = 'HERA' ]]; then
        src="/scratch1/BMC/gsd-fv3-dev/sun/GLORe/$PDY/MOM.res.nc"
      else
        src="/work2/noaa/wrfruc/Shan.Sun/GLORe/$PDY/MOM.res.nc"
      fi
      tgt="${COM_OCEAN_RESTART_PREV}/"
    fi

    ${NCP} "${src}" "${tgt}"
    rc=$?
    ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
    err=$((err + rc))

    # Ocean Perturbation Files
    # Extra zero on MEMDIR ensure we have a number even if the string is empty
    if (( 0${MEMDIR:3} > 0 )) && [[ "${USE_OCN_PERTURB_FILES:-false}" == "true" ]]; then
        src="${BASE_CPLIC}/${CPL_OCNIC:-}/${PDY}${cyc}/${MEMDIR}/ocean/${PDY}.${cyc}0000.mom6_increment.nc"
        tgt="${COM_OCEAN_RESTART_PREV}/${PDY}.${cyc}0000.mom6_increment.nc"
        ${NCP} "${src}" "${tgt}"
        rc=${?}
        ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
        err=$((err + rc))
    fi

    # TODO: Do mediator restarts exists in a ATMW configuration?
    # TODO: No mediator is presumably involved in an ATMA configuration
    if [[ ${EXP_WARM_START:-".false."} = ".true." ]]; then
      # Stage the mediator restarts to ROTDIR (warm start/restart the coupled model)
      RUN=${rCDUMP} YMD=${gPDY} HH=${gcyc} declare_from_tmpl COM_MED_RESTART_PREV:COM_MED_RESTART_TMPL
      [[ ! -d "${COM_MED_RESTART_PREV}" ]] && mkdir -p "${COM_MED_RESTART_PREV}"
      src="${BASE_CPLIC}/${CPL_MEDIC:-}/${PDY}${cyc}/${MEMDIR}/med/${PDY}.${cyc}0000.ufs.cpld.cpl.r.nc"
      tgt="${COM_MED_RESTART_PREV}/${PDY}.${cyc}0000.ufs.cpld.cpl.r.nc"
      if [[ -f "${src}" ]]; then
        ${NCP} "${src}" "${tgt}"
        rc=$?
        ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
        err=$((err + rc))
      else
        echo "WARNING: No mediator restarts available with warm_start=${EXP_WARM_START}"
      fi
    fi

  fi

  # Stage ice initial conditions to ROTDIR (warm start)
  if [[ "${DO_ICE:-}" = "YES" ]]; then
    RUN=${rCDUMP} YMD=${gPDY} HH=${gcyc} declare_from_tmpl COM_ICE_RESTART_PREV:COM_ICE_RESTART_TMPL
    [[ ! -d "${COM_ICE_RESTART_PREV}" ]] && mkdir -p "${COM_ICE_RESTART_PREV}"
    if [[ $iceic -eq 1 ]] ; then
      if [[ $CASE = 'C96' ]]; then
        src="/scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/CICE_ICs/cice5_model_1.00.cpc.res_${PDY}00.nc"
      else
        src="${BASE_CPLIC}/${CPL_ICEIC:-}/${PDY}${cyc}/${MEMDIR}/ice/${PDY}.${cyc}0000.cice_model.res.nc"
        src="/scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/CICE_ICs/cice5_model_0.25.res_${PDY}00.nc"
      fi
    fi
    if [[ $iceic -eq 2 ]] ; then
      if [[ ${machine} = 'HERA' ]]; then
        src="/scratch2/BMC/gsd-fv3-dev/FV3-MOM6-CICE5/oras5b_ice/oras5b_ice_${PDY}_mx${OCNRES}.nc"
      else
        src="/work2/noaa/wrfruc/Shan.Sun/oras5b_ice/oras5b_ice_${PDY}_mx${OCNRES}.nc"
      fi
    fi
    if [[ $iceic -eq 3 ]] ; then
      if [[ ${machine} = 'HERA' ]]; then
        src="/scratch1/BMC/gsd-fv3-dev/sun/GLORe/${PDY}/iced.${PDY}_mx${OCNRES}.nc"
      else
        src="/work2/noaa/wrfruc/Shan.Sun/GLORe/${PDY}/iced.${PDY}_mx${OCNRES}.nc"
      fi
    fi
    tgt="${COM_ICE_RESTART_PREV}/${PDY}.${cyc}0000.cice_model.res.nc"
    ${NCP} "${src}" "${tgt}"
    rc=$?
    ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
    err=$((err + rc))
  fi

  # Stage the WW3 initial conditions to ROTDIR (warm start; TODO: these should be placed in $RUN.$gPDY/$gcyc)
  if [[ "${DO_WAVE:-}" = "YES" ]]; then
    YMD=${PDY} HH=${cyc} declare_from_tmpl COM_WAVE_RESTART
    [[ ! -d "${COM_WAVE_RESTART}" ]] && mkdir -p "${COM_WAVE_RESTART}"
    for grdID in ${waveGRD}; do # TODO: check if this is a bash array; if so adjust
      src="${BASE_CPLIC}/${CPL_WAVIC:-}/${PDY}${cyc}/${MEMDIR}/wave/${PDY}.${cyc}0000.restart.${grdID}"
      tgt="${COM_WAVE_RESTART}/${PDY}.${cyc}0000.restart.${grdID}"
      ${NCP} "${src}" "${tgt}"
      rc=$?
      ((rc != 0)) && error_message "${src}" "${tgt}" "${rc}"
      err=$((err + rc))
    done
  fi

done # for MEMDIR in "${MEMDIR_ARRAY[@]}"; do

###############################################################
# Check for errors and exit if any of the above failed
if [[ "${err}" -ne 0 ]]; then
  echo "FATAL ERROR: Unable to copy ICs from ${BASE_CPLIC} to ${ROTDIR}; ABORT!"
  exit "${err}"
fi

##############################################################
# Exit cleanly
exit "${err}"
