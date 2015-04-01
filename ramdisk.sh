#!/bin/bash
echo "Cleaning old files"
rm -f ../one_plus_one/zip/Tyr*
rm -f ../one_plus_one/zip/boot.img
rm -f ../ram*/image-new*
rm -f ../ram*/ramdisk-new.cpio*
rm -f ../ram*/spl*/boot.img-dtb
rm -f ../ram*/spl*/boot.img-zImage
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
