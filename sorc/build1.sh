#!/bin/sh
set +x
#------------------------------------
# Exception handling is now included.
#
# USER DEFINED STUFF:
#
# USE_PREINST_LIBS: set to "true" to use preinstalled libraries.
#                   Anything other than "true"  will use libraries locally.
#------------------------------------

while getopts "c" option;
do
 case $option in
  c)
   echo "Received -c flag, build ufs-weather-model develop branch with CCPP physics"
   echo "setting coupled=yes and skipping builds not needed for prototype runs"
   RUN_CCPP="YES"
   COUPLED="YES" 
   ;;
 esac
done

export USE_PREINST_LIBS="true"

#------------------------------------
# END USER DEFINED STUFF
#------------------------------------

build_dir=`pwd`
logs_dir=$build_dir/logs
if [ ! -d $logs_dir  ]; then
  echo "Creating logs folder"
  mkdir $logs_dir
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  echo "Creating ../exec folder"
  mkdir ../exec
fi

#------------------------------------
# GET MACHINE
#------------------------------------
target=""
source ./machine-setup.sh > /dev/null 2>&1

#------------------------------------
# INCLUDE PARTIAL BUILD 
#------------------------------------
. ./partial_build.sh

#------------------------------------
# Exception Handling Init
#------------------------------------
ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}
err=0

#------------------------------------
# build forecast model 
#------------------------------------
$Build_fv3gfs && {
echo " .... Building forecast model .... "
if [ ${COUPLED:-"NO"} = "NO" ]; then 
export RUN_CCPP=${RUN_CCPP:-"NO"}
./build_fv3.sh > $logs_dir/build_fv3.log 2>&1
rc=$?
if [[ $rc -ne 0 ]] ; then
    echo "Fatal error in building fv3."
    echo "The log file is in $logs_dir/build_fv3.log"
fi
((err+=$rc))
else 
./build_ufs_coupled.sh > $logs_dir/build_ufs_coupled.log 2>&1
rc=$?
if [[ $rc -ne 0 ]] ; then
    echo "Fatal error in building ufs coupled forecast model."
    echo "The log file is in $logs_dir/build_ufs_coupled.log"
fi
((err+=$rc))
fi
}

#------------------------------------
# Exception Handling
#------------------------------------
[[ $err -ne 0 ]] && echo "FATAL BUILD ERROR: Please check the log file for detail, ABORT!"
$ERRSCRIPT || exit $err

echo;echo " .... Build system finished .... "

exit 0
