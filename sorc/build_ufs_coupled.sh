#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

if [ $target = hera ]; then target=hera.intel ; fi
if [ $target = orion ]; then target=orion.intel ; fi
if [ $target = stampede ]; then target=stampede.intel ; fi

MOD_PATH=$cwd/ufs_coupled.fd/modulefiles

module purge 
module use $MOD_PATH 
module load ufs_${target}
cd ufs_coupled.fd/
if [[ -d build ]]; then rm -Rf build; fi
if [[ -d GOCART ]]; then
  module load ufs_aerosols_${target}
  CMAKE_FLAGS="-DAPP=ATMAERO" CCPP_SUITES="FV3_GFS_v16" ./build.sh
  ./build.sh
else
#ssun  CMAKE_FLAGS="-DAPP=S2SW -DDEBUG=Y" CCPP_SUITES="FV3_GFS_v16_coupled,FV3_GFS_v16,FV3_GFS_v16_coupled_gsd_chem" ./build.sh
  CMAKE_FLAGS="-DAPP=S2SW " CCPP_SUITES="FV3_GFS_v16_coupled,FV3_GFS_v16_coupled_gsd_chem,FV3_GFS_v16_coupled_clim_chem" ./build.sh
fi
