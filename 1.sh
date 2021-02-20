#!/bin/bash


# Export

export CLANG_PATH=/root/Clang-9.0.3:$CLANG_PATH
export PATH=/root/Clang-9.0.3/bin:$PATH
export LD_LIBRARY_PATH=$CLANG_PATH/lib:$CLANG_PATH/lib64:$LD_LIBRARY_PATH
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CODENAME=joyeus
export DEFCONFIG=akame_defconfig
export OUT_DIR=out
export ANYKERNEL_DIR=AnyKernel3
export ARCH=arm64
export CORES="-j6"
export CONFIG=".config"
export NKD=AkameKernel-joeuse
export CODENAME=joeuse
export UN=root

pwd=$PWD
DATE=$(date +'%d-%m-%Y')
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'



echo -e "$red\n ##----------------------------------------------------------------------------##$nocol\n"
echo -e "$blue\n     #### ##     ## ##     ##  #######  ########  ########    ###    ##       "
echo -e "      ##  ###   ### ###   ### ##     ## ##     ##    ##      ## ##   ##       "
echo -e "      ##  #### #### #### #### ##     ## ##     ##    ##     ##   ##  ##       "
echo -e "      ##  ## ### ## ## ### ## ##     ## ########     ##    ##     ## ##       "
echo -e "      ##  ##     ## ##     ## ##     ## ##   ##      ##    ######### ##       "
echo -e "      ##  ##     ## ##     ## ##     ## ##    ##     ##    ##     ## ##       "
echo -e "     #### ##     ## ##     ##  #######  ##     ##    ##    ##     ## ########$nocol"
echo -e "$red\n ##----------------------------------------------------------------------------##$nocol\n"




echo -e "$yellow\n ##============================================================================##"
echo -e " ##========================= Build Kernel From Source =========================##"
echo -e " ##============================================================================##$nocol\n"


sudo ccache make ${DEFCONFIG} \
	PATH=${PATH} \
	CC=${CC} \
	CLANG_TRIPLE=${CLANG_TRIPLE} \
	CROSS_COMPILE=${CROSS_COMPILE} \
	CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
	ARCH=${ARCH} \
	O=${OUT_DIR} \
	${CORES}

# LTO And LLD Optimizations
scripts/config --file ${OUT_DIR}/${CONFIG} \
        -d LTO \
        -d LTO_CLANG \
        -e TOOLS_SUPPORT_RELR \
        -e LD_BFD

sudo ccache make all \
        PATH=${PATH} \
        CC=${CC} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        ARCH=${ARCH} \
        O=${OUT_DIR} \
        ${CORES}

sudo ccache make dtbo.img \
        PATH=${PATH} \
        CC=${CC} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        ARCH=${ARCH} \
        O=${OUT_DIR} \
        ${CORES}

sudo make firmware_install modules_install \
        PATH=${PATH} \
        CC=${CC} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        ARCH=${ARCH} \
        O=${OUT_DIR} \
        ${CORES}



echo -e "$yellow\n ##============================================================================##"
echo -e " ##=========================== Build Kernel Headers ===========================##"
echo -e " ##============================================================================##$nocol\n"

sudo rm -rf /${UN}/kernel-headers/

sudo rm -rf /${UN}/tmp 

rm -rf /${UN}/kernel-headers-${CODENAME}.tar.xz

mkdir /${UN}/kernel-headers

cp -r * /${UN}/kernel-headers

cd /${UN}/kernel-headers/

sudo make ${DEFCONFIG} prepare \
	PATH=${PATH} \
        CC=${CC} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        ARCH=${ARCH} \
        ${CORES}

mkdir /${UN}/tmp 

cp -r arch/arm* Makefile out/scripts/mod/modpost out/scripts/genksyms/genksyms  include scripts drivers/misc /${UN}/tmp 

rm -rf * 

cp -r /${UN}/tmp/* $PWD 

mv modpost scripts/mod/

mv genksyms scripts/genksyms/

rm -rf /${UN}/tmp 

mkdir arch 

cp -r arm* arch 

rm -rf arm* 

mkdir drivers 

cp -r misc drivers 

rm -rf misc

cd /${UN}/kernel-headers 

chmod 777 *

tar czf kernel-headers-${CODENAME}.tar.xz *

mv kernel-headers-${CODENAME}.tar.xz /${UN}

cd /${UN}

ls



echo -e "$yellow\n ##============================================================================##"
echo -e " ##===================== Creating A Flashable *.zip Archive ===================##"
echo -e " ##============================================================================##$nocol\n"


cd /${UN}/${NKD}

rm -rf AnyKernel3

cp /${UN}/AnyKernel3 /${UN}/${NKD} -r


KERNEL_NAME=$(make kernelrelease O=out PATH=${PATH} \
        CC=${CC} \
        CLANG_TRIPLE=${CLANG_TRIPLE} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32} \
        ARCH=${ARCH} \
        ${CORES} | grep +)


mkdir -p ${ANYKERNEL_DIR}/modules/system/lib/modules/${KERNEL_NAME}/kernel
mkdir -p ${ANYKERNEL_DIR}/modules/vendor/firmware


cd /${UN}/${NKD}


cd out && cp $(find -name *.ko) --parents ../${ANYKERNEL_DIR}/modules/system/lib/modules/${KERNEL_NAME}/kernel
cp $(find -name *.bin) ../${ANYKERNEL_DIR}/modules/vendor/firmware
cp $(find -name *.fw) ../${ANYKERNEL_DIR}/modules/vendor/firmware
cp modules.* ../${ANYKERNEL_DIR}/modules/system/lib/modules/ && cd ..
#find -name '*.dtb' -exec cat {} + > dtb
cp $(find -name Image) ${ANYKERNEL_DIR}
cp $(find -name dtbo.img) ${ANYKERNEL_DIR}
cp $(find -name dtb) ${ANYKERNEL_DIR}
cd ${ANYKERNEL_DIR} && zip -r -9 AkameKernel.zip *
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$blue Kernel compiled on $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds$nocol"
