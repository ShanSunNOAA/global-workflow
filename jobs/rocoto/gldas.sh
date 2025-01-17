#!/bin/ksh -x

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Execute the JJOB. GLDAS only runs once per day.

$HOMEgfs/jobs/JGDAS_GLDAS
status=$?

exit $status
