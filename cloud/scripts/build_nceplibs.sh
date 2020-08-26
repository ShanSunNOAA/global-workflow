#!/bin/bash
set -exo pipefail

export COMP=${COMP:-gnu}

#install directory and compiler flag
INSTALL_DIR=/usr/local
SRC_DIR=/opt
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALL_DIR/lib

#use make
ln -sf /usr/bin/make /usr/bin/gmake

##############
# Compiler
##############

if [ "$COMP" = "intel" ]; then
   FC=ifort
   CC=icc
   FCOMP=mpiifort
else
   FC=gfortran
   CC=gcc
   FCOMP=mpif90
fi

#################################
## wgrib2
#################################
cd $SRC_DIR && rm -rf /usr/local/grib2 && \
   mkdir -p /usr/local/grib2 && \
   wget ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v2.0.8 -O wgrib2.tgz && \
   tar -xf wgrib2.tgz && \
   mv grib2/ /usr/local/grib2 && \
   cd /usr/local/grib2/grib2 && \
   FC=$FC CC=$CC make && FC=$FC CC=$CC make lib && rm -rf /usr/local/bin/wgrib2 && \
   ln -s /usr/local/grib2/grib2/wgrib2/wgrib2 /usr/local/bin/wgrib2 && \
   rm -rf wgrib2.tgz

#################################
## libjasper
#################################
cd $SRC_DIR && git clone https://github.com/mdadams/jasper.git && \
    cd jasper && \
    mkdir -p mybuild && \
    cmake -G "Unix Makefiles" -H./ -B./mybuild -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} && \
    cd mybuild && make clean all && make install && \
    cd ../.. && \
    rm -fr jasper

#######################################
## Old nceplibs
#######################################
VER=NCEPlibs-20190820
export JASPER_INC=/usr/local/include/jasper
export PNG_INC=/usr/include/x86_64-linux-gnu
export NETCDF=/usr/local
export NETCDF_INC=/usr/local/include
cd $SRC_DIR && \
    git clone https://github.com/NCAR/NCEPlibs.git && \
    mv NCEPlibs $VER && \
    cd $VER && \
    git checkout 500fa50e234fa34c7336b61ea41 -b nov5 && \
    mkdir $INSTALL_DIR/$VER && \
    yes | ./make_ncep_libs.sh -s linux -c ${COMP} -d ${INSTALL_DIR}/${VER} -a upp -o 0 && \
    cd .. && \
    rm -fr ${VER}

#############################################################
# Compile NCEP libraries needed for gfs. Clone the required 
# reposistories from https://vlab.ncep.noaa.gov
#############################################################

# g2tmpl
cd $SRC_DIR/NCEPLIBS-g2tmpl && libver='g2tmpl_v1.6.0' bash ./build_g2tmpl.sh gnu_general build && cd ../..

# gfsio
cd ${SRC_DIR}/NCEPLIBS-gfsio && bash ./build_gfsio.sh gnu_general build prefix=${PWD} && cd ../..

#bufr
cd ${SRC_DIR}/NCEPLIBS-bufr/src && COMP=${COMP} ./makebufrlib.sh && cd ../..

#bacio
cd ${SRC_DIR}/NCEPLIBS-bacio && ./make_bacio_lib.sh ${FC}.setup && cd ..

#ip 
cd ${SRC_DIR}/NCEPLIBS-ip && ./make_ip_lib.sh ${FC}.setup && cd ..

#landsfcutil
cd ${SRC_DIR}/NCEPLIBS-landsfcutil && ./make_landsfcutil_lib.sh ${FC}.setup && cd ..

#sfcio
cd ${SRC_DIR}/NCEPLIBS-sfcio && ./make_sfcio_lib.sh ${FC}.setup && cd ..

#sigio
cd ${SRC_DIR}/NCEPLIBS-sigio && ./make_sigio_lib.sh ${FC}.setup && cd ..

#nemsio
cd ${SRC_DIR}/NCEPLIBS-nemsio/src && VER="v2.2.4" FCOMP=${FCOMP} LIBDIR=../ make && cd ..

#nemsiogfs
cd ${SRC_DIR}/NCEPLIBS-nemsiogfs/src && \
   VER="v2.2.0" FCOMP=${FCOMP} FCFLAGS="-O3 -I${SRC_DIR}/NCEPLIBS-nemsio/nemsio_v2.2.4" LIBDIR=../ make && cd ..

#w3emc
cd ${SRC_DIR}/NCEPLIBS-w3emc && \
    SIGIO_INC4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/incmod/sigio_v2.1.0 \
    SIGIO_LIB4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/libsigio_v2.1.0.a \
    NEMSIO_INC=${SRC_DIR}/NCEPLIBS-nemsio/nemsio_v2.2.4 \
    NEMSIO_LIB=${SRC_DIR}/NCEPLIBS-nemsio/libnemsio_v2.2.4.a \
    ./make_w3emc_lib.sh ${FC}.setup && cd ..

#w3nco
cd ${SRC_DIR}/NCEPLIBS-w3nco && \
    SIGIO_INC4=${SRC_DIR}/NCEPLIBS-sigio/sigio_v2.1.0/incmod/sigio_v2.1.0 \
    COMP=${COMP} ./makelibw3_nco.sh  && cd ..

#sp 
cd ${SRC_DIR}/NCEPLIBS-sp && COMP=${COMP} ./makelibsp.sh_Linux && cd ..

#g2 
cd ${SRC_DIR}/NCEPLIBS-g2 && COMP=${COMP} source ./modulefiles/g2.linux \
	&& cd src && COMP=${COMP} bash ./makeg2lib_linux.sh && cd ..

#prod_util
cd ${SRC_DIR}/NCEPLIBS-prod_util/sorc && \
   cd fsync_file.cd && CC=${CC} make && cd .. && \
   cd mdate.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd ndate.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd nhour.fd && FC=${FC} W3NCO_LIB4=${SRC_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a make && cd .. && \
   cd ../../

# grib_util
(
GFS_LIBS_DIR=/opt
export W3NCO_LIBd=${GFS_LIBS_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_d.a
export IP_LIBd=${GFS_LIBS_DIR}/NCEPLIBS-ip/ip/v3.0.1/libip_v3.0.1_d.a
export SP_LIBd=${GFS_LIBS_DIR}/NCEPLIBS-sp/libsp_v2.0.2_d.a
export BACIO_LIB4=${GFS_LIBS_DIR}/NCEPLIBS-bacio/bacio_v2.1.0_4/libbacio_v2.1.0_4.a
export BACIO_LIB8=${GFS_LIBS_DIR}/NCEPLIBS-bacio/bacio_v2.1.0_8/libbacio_v2.1.0_8.a
export W3NCO_LIB4=${GFS_LIBS_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_4.a
export W3NCO_LIB8=${GFS_LIBS_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_8.a
export W3NCO_LIBd=${GFS_LIBS_DIR}/NCEPLIBS-w3nco/libw3nco_v2.0.6_d.a
export BUFR_LIB4=${GFS_LIBS_DIR}/NCEPLIBS-bufr/libbufr_v11.3.0_4_64.a
export G2_LIB4=${GFS_LIBS_DIR}/NCEPLIBS-g2/${COMP}/libg2_v3.1.0_4.a
export G2_LIBd=${GFS_LIBS_DIR}/NCEPLIBS-g2/${COMP}/libg2_v3.1.0_d.a
export G2_INC4=${GFS_LIBS_DIR}/NCEPLIBS-g2/${COMP}/include/g2_v3.1.0_4
export JASPER_LIB=-ljasper
export PNG_LIB=-lpng
export Z_LIB=-lz
cd /opt/NCEPLIBS-grib_util/sorc && bash ./install_all_grib_util_linux.sh  && cd ../..
)

##############
# CRTM
##############
#CRTM
git clone https://github.com/NOAA-EMC/JCSDA_CRTM.git
cd JCSDA_CRTM; git checkout release/REL-2.3.0; cd -
mv JCSDA_CRTM CRTM-2.3.0

#VER=2.3.0
#PP=crtm_v${VER}.tar.gz
#LNK="https://ftp.emc.ncep.noaa.gov/jcsda/CRTM/REL-${VER}/crtm_v${VER}.tar.gz"
#wget ${LNK}
#tar -xvf ${PP}
#mv REL-${VER} CRTM-${VER}
#rm -rf ${PP}

cd ${SRC_DIR}/CRTM-2.3.0 && \
    /bin/bash -c "source config-setup/${FC}.setup" && \
    ./configure \
       --disable-big-endian \
       --prefix=${PWD} && \
    make 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install

##############
# GEMPAK7
##############
cd $SRC_DIR && git clone https://github.com/Unidata/gempak.git GEMPAK7 && \
    cd GEMPAK7 && sed -i 's,^NAWIPS=.*,NAWIPS='"${SRC_DIR}"'\/GEMPAK7,g' Gemenviron.profile && \
    export NA_OS=linux64_gfortran && \
    . ./Gemenviron.profile && make everything && cd ..

#graphics
cd ${SRC_DIR}/NCEPLIBS-graphics/v2.0.0/src && \
   GFS_LIBS_DIR=/opt COMP=${COMP} ./compile_all_graphics_lib_wcoss.sh linux && cd ../../../

