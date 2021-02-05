#!/bin/sh
set -xue

topdir=$(pwd)
echo $topdir

echo fv3gfs_ccpp_chem checkout ...
if [[ ! -d fv3gfs_ccpp_chem.fd ]] ; then
    rm -f ${topdir}/checkout-fv3gfs_ccpp_chem.log
   git clone --recursive --branch gsd/develop-chem https://github.com/shansun6/ufs-weather-model  fv3gfs_ccpp_chem.fd >> ${topdir}/checkout-fv3gfs_ccpp_chem.log 2>&1
   cd fv3gfs_ccpp_chem.fd
   git checkout 7c648ec36b67a22bb67f22a9c928e7735948f074
   git submodule sync
   git submodule update --init --recursive
   cd ${topdir}
   ln -fs fv3gfs_ccpp_chem.fd fv3gfs.fd
else
    echo 'Skip.  Directory fv3gfs_ccpp_chem.fd already exists.'
fi

echo gsi checkout ...
if [[ ! -d gsi.fd ]] ; then
    rm -f ${topdir}/checkout-gsi.log
    git clone --recursive https://github.com/NOAA-EMC/GSI.git gsi.fd >> ${topdir}/checkout-gsi.log 2>&1
    cd gsi.fd
    git checkout release/gfsda.v16.0.0
    git submodule update
    cd ${topdir}
    rsync -ax gsi.fd_chem/ gsi.fd/
else
    echo 'Skip.  Directory gsi.fd already exists.'
fi

echo gldas checkout ...
if [[ ! -d gldas.fd ]] ; then
    rm -f ${topdir}/checkout-gldas.log
    git clone https://github.com/NOAA-EMC/GLDAS  gldas.fd >> ${topdir}/checkout-gldas.fd.log 2>&1
    cd gldas.fd
    git checkout gldas_gfsv16_release.v1.2.0
    cd ${topdir}
else
    echo 'Skip.  Directory gldas.fd already exists.'
fi

echo ufs_utils checkout ...
if [[ ! -d ufs_utils.fd ]] ; then
    rm -f ${topdir}/checkout-ufs_utils.log
    git clone https://github.com/NOAA-EMC/UFS_UTILS.git ufs_utils.fd >> ${topdir}/checkout-ufs_utils.fd.log 2>&1
    cd ufs_utils.fd
    git checkout release/ops-gfsv16 
    cd ${topdir}
else
    echo 'Skip.  Directory ufs_utils.fd already exists.'
fi

echo prepchem_NC.fd checkout ...
if [[ ! -d prepchem_NC.fd ]] ; then
    rm -f ${topdir}/checkout-prepchem_NC.fd.log
    git clone  gerrit:GSD-prep-chem prepchem_NC.fd >> ${topdir}/checkout-prepchem_NC.fd.log 2>&1
    cd ${topdir}
else
    echo 'Skip.  Directory prepchem_NC.fd already exists.'
fi

#echo EMC_post checkout ...
#if [[ ! -d gfs_post.fd ]] ; then
#    rm -f ${topdir}/checkout-gfs_post.log
#    git clone https://github.com/NOAA-EMC/EMC_post.git gfs_post.fd >> ${topdir}/checkout-gfs_post.log 2>&1
#    cd gfs_post.fd
#    git checkout upp_gfsv16_release.v1.0.10
#    cd ${topdir}
#else
    echo 'Skip.  Directory gfs_post.fd already exists.'
#fi

echo EMC_gfs_wafs checkout ...
if [[ ! -d gfs_wafs.fd ]] ; then
    rm -f ${topdir}/checkout-gfs_wafs.log
    git clone --recursive https://github.com/NOAA-EMC/EMC_gfs_wafs.git gfs_wafs.fd >> ${topdir}/checkout-gfs_wafs.log 2>&1
    cd gfs_wafs.fd
    git checkout gfs_wafs.v5.0.11
    cd ${topdir}
else
    echo 'Skip.  Directory gfs_wafs.fd already exists.'
fi

echo EMC_verif-global checkout ...
if [[ ! -d verif-global.fd ]] ; then
    rm -f ${topdir}/checkout-verif-global.log
    git clone --recursive https://github.com/NOAA-EMC/EMC_verif-global.git verif-global.fd >> ${topdir}/checkout-verif-global.log 2>&1
    cd verif-global.fd
    git checkout verif_global_v1.9.0
    cd ${topdir}
else
    echo 'Skip. Directory verif-global.fd already exist.'
fi

exit 0
