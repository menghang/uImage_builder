#!/bin/bash

DEVICE=$1

IWD=`pwd`
cd $IWD/$DEVICE

mkdir initramfs
cp uImage initramfs/uImage
cd $IWD/$DEVICE/initramfs
tail -c +65 uImage | lzma -dc | tail -c +$((pos+1)) | cpio -i --no-absolute-filenames
#tail -c +129 uImage | lzma -dc | tail -c +$((pos+1)) | cpio -i --no-absolute-filenames
rm uImage
echo ' '
echo ' '
echo "initramfs extracted into $IWD/$DEVICE/initramfs"

