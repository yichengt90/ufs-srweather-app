#!/bin/bash

# usage instructions
usage () {
cat << EOF_USAGE
Usage: $0 --platform=PLATFORM --account=ACCOUNT [OPTIONS]...

OPTIONS
  -h, --help
      show this help guide
  -p, --platform=PLATFORM
      name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | wcoss_dell_p3 | wcoss2)
  --account=ACCOUNT
      account on hpc machine
  --compiler=COMPILER
      compiler to use; default depends on platform
      (e.g. intel | gnu | cray | gccgfortran)
  --case=CASE
      weather model case study
      (e.g. 2019_BARRY)
  --grid=GRID_NAME
      grid name
      (e.g. RRFS_CONUS_25km)
  --fcst_hr=FCST_HRS
      FCST HR (default: 3)
  --ccpp=CCPP_SUITE
      CCPP suite
  --exp-dir=EXP_DIR
      build directory
  -v, --verbose
      build with verbose output

NOTE: This script is for internal developer use only;
See User's Guide for detailed build instructions

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  MACHINE=${PLATFORM}
  ACCOUNT=${ACCOUNT}
  SRW_DIR=${SRW_DIR}
  BUILD_DIR=${BUILD_DIR}
  WORKFLOW_DIR=${WORKFLOW_DIR}
  EXP_DIR=${EXP_DIR}
  EXP_NAME=${EXP_NAME}
  CASE=${CASE}
  COMPILER=${COMPILER}
  CCPP_SUITE=${CCPP_SUITE}
  GRID_NAME=${GRID_NAME}
  FCST_HRS=${FCST_HRS} 
  VERBOSE=${VERBOSE}

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
LCL_PID=$$
HTF_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
MACHINE_SETUP=${SRW_DIR}/src/UFS_UTILS/sorc/machine-setup.sh
BUILD_DIR="$(dirname "$HTF_DIR")"
SRW_DIR="$(dirname "$BUILD_DIR")"
WORKFLOW_DIR="${SRW_DIR}/regional_workflow/ush"
COMPILER=""
CASE="2019_BARRY"
GRID_NAME="RRFS_CONUS_25km"
CCPP_SUITE="FV3_GFS_v16"
EXP_DIR="${HTF_DIR}/test_srw"
EXP_NAME="${CASE}_${GRID_NAME}_${CCPP_SUITE}"
ACCOUNT=""
VERBOSE=false

# process required arguments
if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
  usage
  exit 0
fi

# process optional arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --platform=?*|-p=?*) PLATFORM=${1#*=} ;;
    --platform|--platform=|-p|-p=) usage_error "$1 requires argument." ;;
    --account=?*) ACCOUNT=${1#*=} ;;
    --account|--account=) usage_error "$1 requires argument." ;;
    --compiler=?*|-c=?*) COMPILER=${1#*=} ;;
    --compiler|--compiler=|-c|-c=) usage_error "$1 requires argument." ;;
    --case=?*) CASE=${1#*=} ;;
    --case|--case=) usage_error "$1 requires argument." ;;
    --ccpp=?*) CCPP_SUITE=${1#*=} ;;
    --ccpp|--ccpp=) usage_error "$1 requires argument." ;;
    --grid=?*) GRID_NAME=${1#*=} ;;
    --grid|--grid=) usage_error "$1 requires argument." ;;
    --fcst_hr=?*) FCST_HRS=${1#*=} ;;
    --fcst_hr|--fcst_hr=) usage_error "$1 requires argument." ;;
    --exp-dir=?*) EXP_DIR=${1#*=} ;;
    --exp-dir|--exp-dir=) usage_error "$1 requires argument." ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break
  esac
  shift
done

# Ensure uppercase / lowercase ============================================
CASE="${CASE^^}"
PLATFORM="${PLATFORM,,}"
ACCOUNT="${ACCOUNT,,}"
COMPILER="${COMPILER,,}"

# check if PLATFORM is set
if [ -z $PLATFORM ] || [ -z $ACCOUNT ]; then
  printf "\nERROR: Please set PLATFORM and ACCOUNT.\n\n"
  usage
  exit 0
fi

# set PLATFORM (MACHINE)
MACHINE="${PLATFORM}"
printf "PLATFORM(MACHINE)=${PLATFORM}\n" >&2

set -eu

# automatically determine compiler
if [ -z "${COMPILER}" ] ; then
  case ${PLATFORM} in
    jet|hera|gaea) COMPILER=intel ;;
    orion) COMPILER=intel ;;
    wcoss_dell_p3) COMPILER=intel ;;
    wcoss2) COMPILER=intel ;;
    cheyenne) COMPILER=intel ;;
    macos,singularity) COMPILER=gnu ;;
    odin,noaacloud) COMPILER=intel ;;
    *)
      COMPILER=intel
      printf "WARNING: Setting default COMPILER=intel for new platform ${PLATFORM}\n" >&2;
      ;;
  esac
fi

printf "COMPILER=${COMPILER}\n" >&2

echo $HTF_DIR
echo $BUILD_DIR
echo $SRW_DIR

# set MODULE_FILE for this platform/compiler combination
MODULE_FILE="build_${PLATFORM}_${COMPILER}"
if [ ! -f "${SRW_DIR}/modulefiles/${MODULE_FILE}" ]; then
  printf "ERROR: module file does not exist for platform/compiler\n" >&2
  printf "  MODULE_FILE=${MODULE_FILE}\n" >&2
  printf "  PLATFORM=${PLATFORM}\n" >&2
  printf "  COMPILER=${COMPILER}\n\n" >&2
  printf "Please make sure PLATFORM and COMPILER are set correctly\n" >&2
  usage >&2
  exit 64
fi

printf "MODULE_FILE=${MODULE_FILE}\n" >&2

# Before we go on load modules, we first need to activate Lmod for some systems
source ${SRW_DIR}/etc/lmod-setup.sh $MACHINE

# source the module file for this platform/compiler combination, then load workflow 
printf "... Load MODULE_FILE and create BUILD directory ...\n"
module use ${SRW_DIR}/modulefiles
module load ${MODULE_FILE}
module load "wflow_${PLATFORM}"
conda activate regional_workflow

# check if exp_dir is existed or not
if [ -d "${EXP_DIR}/${EXP_NAME}" ]; then
  # interactive selection
  printf "EXP directory (${EXP_DIR}/${EXP_NAME}) already exists\n"
  printf "Please choose what to do:\n\n"
  printf "[R]emove the existing directory\n"
  printf "[C]ontinue using in the existing directory\n"
  printf "[Q]uit this script\n"
  read -p "Choose an option (R/C/Q):" choice
  case ${choice} in
    [Rr]* ) rm -rf ${EXP_DIR}/${EXP_NAME}; break ;;
    [Cc]* ) break ;;
    [Qq]* ) exit ;;
    * ) printf "Invalid option selected.\n" ;;
  esac
fi

# prepare config.sh based on the selected case
source ${HTF_DIR}/atparse.bash

case $CASE in

  2019_BARRY)
    echo "Selected case is $CASE"
    # case-specific vars
    LBC_INTVL_HR=3
    FIRST_CYCLE=20190712
    LAST_CYCLE=20190712
    CYCLE_HR=00
    MODEL_NAME=${GRID_NAME}_${CCPP_SUITE}
    LAYOUTX=10
    LAYOUTY=6
    FMT="nemsio"
    MDL_BASEDIR=${HTF_DIR}/input-data/model_data/BARRY
    #EXP_DIR="${HTF_DIR}/${CASE}_${GRID_NAME}_${CCPP_SUITE}"
    #EXP_NAME="$(basename "$EXP_DIR")"
    # check if ic and lbcs data are existed
    if [ -f "$MDL_BASEDIR/gfs.t${CYCLE_HR}z.atmanl.nemsio" ]; then
       echo "$CASE IC data existed" 
    else
       echo "get IC data for $CASE!"
       mkdir -p $MDL_BASEDIR
       cd $MDL_BASEDIR
       wget -c https://ufs-case-studies.s3.amazonaws.com/${FIRST_CYCLE}${CYCLE_HR}.gfs.nemsio.tar.gz
       tar -zxvf ${FIRST_CYCLE}${CYCLE_HR}.gfs.nemsio.tar.gz
       mv gfs.atmanl.nemsio gfs.t${CYCLE_HR}z.atmanl.nemsio
       mv gfs.sfcanl.nemsio gfs.t${CYCLE_HR}z.sfcanl.nemsio
       rm ${FIRST_CYCLE}${CYCLE_HR}.gfs.nemsio.tar.gz
       cd $HTF_DIR
    fi    
    it=$(printf "%03d" $LBC_INTVL_HR)
    if [ -f "$MDL_BASEDIR/gfs.t${CYCLE_HR}z.atmf${it}.nemsio" ]; then
       echo "$CASE LBCs data existed"
    else
       echo "get $CASE LBCS data for Barry case"
       mkdir -p $MDL_BASEDIR
       cd $MDL_BASEDIR
       START=$((LBC_INTVL_HR))
       END=$((FCST_HRS))
       INTVL=$((LBC_INTVL_HR))
       for i in $(eval echo "{$START..$END..$INTVL}")
       do
         it=$(printf "%03d" $i)
         echo $it
         wget -c https://ufs-case-studies.s3.amazonaws.com/2019071200_bc.atmf$it.nemsio.tar.gz
         tar -zxvf 2019071200_bc.atmf$it.nemsio.tar.gz
         mv gfs.atmf${it}.nemsio gfs.t${CYCLE_HR}z.atmf${it}.nemsio
         rm 2019071200_bc.atmf$it.nemsio.tar.gz
       done
       cd $HTF_DIR
    fi
    
    ;;


  *)
    echo -n "unknown"
    exit 0
    ;;
esac

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

#set up workflow
atparse < ${HTF_DIR}/template/config.sh.tmp > config.sh
mv config.sh $WORKFLOW_DIR
cd $WORKFLOW_DIR
echo $PWD
./generate_FV3LAM_wflow.sh

#
#GFDL trk tool
#export LIB_Z_PATH=/contrib/hpc-modules/intel-18.0.5.274/zlib/1.2.11/lib
#export LIB_PNG_PATH=/contrib/hpc-modules/intel-18.0.5.274/png/1.6.35/lib64
#export LIB_JASPER_PATH=/contrib/hpc-modules/intel-18.0.5.274/jasper/2.0.25/lib64
# build gfdl tracker
#cd $EXP_DIR
#wget --no-check-certificate https://dtcenter.org/sites/default/files/community-code/gfdl/standalone_gfdl-vortextracker_v3.9a.tar.gz
#tar -zxvf standalone_gfdl-vortextracker_v3.9a.tar.gz
#rm -rf standalone_gfdl-vortextracker_v3.9a.tar.gz
#cd standalone_gfdl-vortextracker_v3.9a
#sed -i "142s/image.inmem_=1;/\/\/image.inmem_=1;/" ./libs/src/g2/enc_jpeg2000.c
#echo "2" | ./configure
#./compile 2>&1 | tee tracker.log

#
#START=$((0))
#END=$((FCST_HRS))
#INTVL=$((LBC_INTVL_HR))
#for i in $(eval echo "{$START..$END..$INTVL}")
#do
#  it=$(printf "%03d" $i)
#  ttt=$(($i*60))
#  it2=$(printf "%05d" $ttt)
#  wgrib2 ../${FIRST_CYCLE}${CYCLE_HR}/postprd/rrfs.t00z.prslev.f${it}.${GRID_NAME,,}.grib2 -set_grib_type same -new_grid_winds earth -new_grid_interpolation bilinear -if ':(CSNOW|CRAIN|CFRZR|CICEP|ICSEV):' -new_grid_interpolation neighbor -fi -set_bitmap 1 -set_grib_max_bits 16 -if ':(APCP|ACPCP|PRATE|CPRAT):' -set_grib_max_bits 25 -fi -if ':(APCP|ACPCP|PRATE|CPRAT|DZDT):' -new_grid_interpolation budget -fi -new_grid latlon 0:1440:0.25 90:721:-0.25 gfs.SRW.AL022019.${FIRST_CYCLE}${CYCLE_HR}.f${it2}

#  ./trk_exec/grb2index.exe gfs.SRW.AL022019.${FIRST_CYCLE}${CYCLE_HR}.f${it2} gfs.SRW.AL022019.${FIRST_CYCLE}${CYCLE_HR}.f${it2}.ix
#done

#
#cp ${HTF_DIR}/data/input.nml ./
#cp ${HTF_DIR}/data/fort.15 ./
#cp ${HTF_DIR}/data/tcvit_rsmc_storms.txt ./
#cp ${HTF_DIR}/data/trk_plot.py ./
#cp ${HTF_DIR}/data/bal022019_post.dat ./
#./trk_exec/gettrk.exe < input.nml

#
#python3 trk_plot.py

exit 0
