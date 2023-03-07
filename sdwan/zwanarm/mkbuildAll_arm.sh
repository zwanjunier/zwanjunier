#!/bin/bash

#This script is to be run in build system 
#Location of this script should be QABUILD PATH variable

TAG="$1"
HW="bpir64 u7622 cwan801 bpi-r3 sg220"
MAJOR=`echo $TAG | awk -F- '{print $1}'`
MINOR=`echo $TAG | awk -F$MAJOR- '{print $2}'`
QABUILD="/QABUILD"
BIP="10.200.3.79"
ARM_DIR=$QABUILD/zwan-arm
CPE_DIR=$QABUILD/zwan-cpe

ping -c 3 -i 1 -W 3 ${BIP} &>/dev/null
RETURN_BPIP=$?
if [ $RETURN_BPIP -ne 0 ] ; then
   echo "ARM device  $RETURN_BPIP is not reachable, check it is a reachable ip"
   exit 2
fi

RELEASE_IMG_PATH=/home/release-images
mdY=`date +%b%d-%Y-%H%M%S`
LOG_FILE=/QABUILD/build.arm64.log.$mdY

for H in $HW; do
if [ -d $RELEASE_IMG_PATH/$TAG/$H ] ; then
    echo "build exist for $HW at /home/release-images/$TAG/$H"
    exit 1
fi
done


Help()
{   
  echo "SCRIPT FOR RELEASE IMAGES."
   echo "Syntax: mkbuildAll_arm.sh 1.1-1.0_1000"
   echo "options:"
   echo "-h  Print this Help."
   echo
}

while getopts ":h" option; do
    case $option in
      h)
         Help
         exit 2
   esac
done

if [ "$TAG" == "" ]; then
    echo "TAG can not be empty"
    Help
    exit 1
fi


clone_src(){
    cd $QABUILD
    GIT_SSL_NO_VERIFY=true git clone -b dev https://builduser:builduser@172.16.120.65/sdwan/zwan-arm.git
    cd $ARM_DIR
    git checkout dev
    git -c credential.helper='!f() { echo "username=builduser"; echo "password=builduser"; }; f' pull
    git checkout $TAG
    cd -
}

check_setup(){
    is_release=`cat $ARM_DIR/prjenv.inc  | grep BUILD_TYPE=Release | wc -l`
    if [ "${is_release}" -ne "1" ];then
        echo "In prjenv.inc, build type is not release" 
        exit 1
    fi
}

clean_arm_build_path(){
    cd $ARM_DIR
    git clean -f
    cd -
}

make_build_arm()
{
    cd $ARM_DIR
    rm -rf ./build
    for hw in $HW; do
            mkdir -p $RELEASE_IMG_PATH/$TAG/$hw
            echo "BUILD CREATION FOR $HW STARTED"
            echo "-----------------------------------------------------------------"
            echo "creating build.bin for $hw"
            echo "-----------------------------------------------------------------"
            if [ -f build_$hw.sh ]; then 
                bash -x build_$hw.sh $MAJOR $MINOR $BIP $TAG 2>> $LOG_FILE
                echo "-----------------------------------------------------------------"
                echo "creating Image for $hw"
            fi
            mk_image_for_hw $hw
            echo "-----------------------------------------------------------------"
            echo "BUILD CREATION FOR $HW COMPLETED"
            echo "-----------------------------------------------------------------"
    done
    cd -
}

cp_bpi_c801(){
    cp -rf $RELEASE_IMG_PATH/$TAG/bpir64/* $RELEASE_IMG_PATH/$TAG/cwan801
    rm -rf $RELEASE_IMG_PATH/$TAG/cwan801/*.img
    cd $RELEASE_IMG_PATH/$TAG/cwan801/
    build_file=`ls build-*.bin`
    cwan_name=build-cwan801`ls build-*.bin | awk -F build-bpir64 '{print $2}'`
    mv $build_file $cwan_name
    cd -
}

cp_bpi_u7622(){
    cp -rf $RELEASE_IMG_PATH/$TAG/bpir64/* $RELEASE_IMG_PATH/$TAG/u7622
    rm -rf $RELEASE_IMG_PATH/$TAG/u7622/*.img
    cd $RELEASE_IMG_PATH/$TAG/u7622/
    build_file=`ls build-*.bin`
    u7622_name=build-u7622`ls build-*.bin | awk -F build-bpir64 '{print $2}'`
    mv $build_file $u7622_name
    cd -
}

mk_image_for_hw(){
    hw=$1
    mmcdev=0
    case "$hw" in
        "bpir64")
            size="7456"
            ;;
        "ebu3720")
            size="7457"
            mmcdev=0
        ;;
        "sg220")
            size="3776"
            mmcdev=1
        ;;
        "cwan801")
            size="14910"
        ;;
        "u7622")
            size="7456"
            ;;
        "bpi-r3")
            size="7456"
            ;;
        *)
            exit 1
        ;;
    esac

    if [ "$hw" = "cwan801" ]; then
        cp_bpi_c801
    elif [ "$hw" = "u7622" ]; then
        cp_bpi_u7622
    fi
    if [ "$hw" = "bpi-r3" ]; then
        cp $ARM_DIR/flasher/flash_* $RELEASE_IMG_PATH/$TAG/$hw/
    fi

    cp $ARM_DIR/flasher/flasher.sh $RELEASE_IMG_PATH/$TAG/$hw/
    cp $ARM_DIR/flasher/splitter.sh $RELEASE_IMG_PATH/$TAG/$hw/
    cp $ARM_DIR/flasher/${hw}.uEnv $RELEASE_IMG_PATH/$TAG/$hw/
        
    cd $RELEASE_IMG_PATH/$TAG/$hw/
    build_file=`ls build-*.bin`
    image_file=image-`ls build-*.bin | awk -F.bin '{print $1}' | awk -Fbuild- '{print $2}'`.img
    bash -x flasher.sh $image_file 0 $build_file $size $hw 2>> $LOG_FILE
    
    if [ "$hw" = "sg220" -o "$hw" = "ebu3720" ]; then 
        bash -x splitter.sh $image_file ${hw}-${TAG}_flasher $mmcdev ${hw}.uEnv 2>> $LOG_FILE
        if  [ "$hw" = "sg220" ]; then 
            cp $ARM_DIR/flasher/sg_mkimage $RELEASE_IMG_PATH/$TAG/$hw/
        else 
            cp $ARM_DIR/flasher/ebu_mkimage $RELEASE_IMG_PATH/$TAG/$hw/
        fi 
    fi
    cd -
}


clean_arm_build_path
clone_src
check_setup
make_build_arm
