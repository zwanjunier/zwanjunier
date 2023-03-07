#!/bin/bash

#This script is to be run in build system 
#Location of this script should be QABUILD PATH variable

TAG="$1"
MAJOR=`echo $TAG | awk -F- '{print $1}'`
MINOR=`echo $TAG | awk -F$MAJOR- '{print $2}'`
QABUILD="/QABUILD"
CPE_DIR=$QABUILD/zwan-cpe

RELEASE_IMG_PATH=/home/release-images
mdY=`date +%b%d-%Y-%H%M%S`
LOG_FILE=/QABUILD/build.x86.log.$mdY

Help()
{   
  echo "SCRIPT FOR RELEASE IMAGES."
   echo "Syntax: mkbuildAll_x86.sh TAG"
   echo "eg: mkbuildAll_x86.sh 1.1-01.1014"
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
    GIT_SSL_NO_VERIFY=true git clone -b development https://builduser:builduser@172.16.120.65/sdwan/zwan-cpe.git
    cd $CPE_DIR
    git checkout development
    git -c credential.helper='!f() { echo "username=builduser"; echo "password=builduser"; }; f' pull
    git checkout $TAG
    cd -
}

make_build_x86()
{
   # rm -rf ./build
    cd $CPE_DIR/build
    rm -rf bin images cpe-base-*.qcow2.xz mnt PRODUCT_ID tmp
    cd -
    
    cd $CPE_DIR
    bash -x verifiedboot/keygen/gen_dev_keys.sh 2>> $LOG_FILE
    #bash -x verifiedboot/keygen/gen_gpg_key.sh 2>> $LOG_FILE
    bash -x build_ver_boot_img.sh $MAJOR $MINOR 2>> $LOG_FILE
    cd -
}

cp_X86_release() {
    cp $CPE_DIR/vcpe_qcow2_to_x86_verboot_raw_img.sh   $RELEASE_IMG_PATH/$TAG/x86/ 
    cd $CPE_DIR/build
    cp cpe-base-$TAG* cpe-base-sec.xml  $RELEASE_IMG_PATH/$TAG/x86/
    cd -
}

clean_build_path(){
    cd $CPE_DIR
    git clean -f
    cd -
}


clean_build_path
clone_src
make_build_x86
cp_X86_release
