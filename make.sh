#!/bin/bash
echo "Cleaning old files"
rm -f ../output/Tyr*
rm -f ../output/boot.img
rm -f ../ram*/image-new*
rm -f ../ram*/ramdisk-new.cpio*
rm -f ../ram*/spl*/boot.img-dtb
rm -f ../ram*/spl*/boot.img-zImage
echo "Making oneplus one kernel"
DATE_START=$(date +"%s")

make clean && make mrproper
export PATH=/home/stefan/kernel/arm-cortex_a15-linux-gnueabihf-linaro_4.9.3-2015.03/bin/:$PATH

make ARCH=arm Tyr_defconfig
make -j 5 ARCH=arm SUBARCH=arm CROSS_COMPILE=/home/stefan/kernel/arm-cortex_a15-linux-gnueabihf-linaro_4.9.3-2015.03/bin/arm-cortex_a15-linux-gnueabihf- HOSTCC=clang CC=clang

echo "End of compiling kernel!"

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

if [ $# -gt 0 ]; then
echo $1 > .version
fi

../ramdisk_one_plus_one/dtbToolCM -2 -o ../ramdisk_one_plus_one/split_img/boot.img-dtb -s 2048 -p ../one_plus_one/scripts/dtc/ ../one_plus_one/arch/arm/boot/
cp arch/arm/boot/zImage ../ramdisk_one_plus_one/split_img/boot.img-zImage
cd ../ramdisk_one_plus_one/
./repackimg.sh
cd ../one_plus_one/
zipfile="TyrV.zip"
echo "making zip file"
cp ../ramdisk_one_plus_one/image-new.img ../output/boot.img
cd ../output/
rm -f *.zip
zip -r -9 $zipfile *
rm -f /tmp/*.zip
cp *.zip /tmp

