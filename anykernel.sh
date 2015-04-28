#!/bin/bash
echo "Cleaning old files"
rm -f ../opo-AnyKernel2/dtb
rm -f ../opo-AnyKernel2/zImage
rm -f ../output/Tyr*.zip
echo "Making oneplus one kernel"
DATE_START=$(date +"%s")

make clean && make mrproper

VER=115
export KBUILD_BUILD_VERSION=$VER
export ARCH=arm
export SUBARCH=arm
make Tyr_defconfig
make -j8
echo "End of compiling kernel!"

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

../ramdisk_one_plus_one/dtbToolCM -2 -o ../opo-AnyKernel2/dtb -s 2048 -p ../one_plus_one/scripts/dtc/ ../one_plus_one/arch/arm/boot/
cp arch/arm/boot/zImage ../opo-AnyKernel2/zImage
cd ../opo-AnyKernel2/
zipfile="TyrV$VER.zip"
zip -r -9 $zipfile *
mv TyrV*.zip ../output/
