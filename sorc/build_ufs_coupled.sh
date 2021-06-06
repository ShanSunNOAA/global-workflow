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

MOD_PATH=$cwd/ufs_coupled.fd/modulefiles/$target

module purge 
module use $MOD_PATH 
module load fv3 
cd ufs_coupled.fd/
if [[ -d build ]]; then rm -Rf build; fi
##CMAKE_FLAGS="-DAPP=S2SW -DDEBUG=Y" CCPP_SUITES="FV3_GFS_v16_coupled_gsd_chem" ./build.sh 
CMAKE_FLAGS="-DAPP=S2SW" CCPP_SUITES="FV3_GFS_v16_coupled,FV3_GFS_v16_coupled_gsd_chem" ./build.sh 
