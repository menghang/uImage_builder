#!/bin/sh

#
# Copyright (C) 2011 Pasquale Convertini    aka psquare (psquare.dev@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# http://www.gnu.org/licenses/gpl-2.0.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#
DEVICE=aml8726m
WORKDIR=REBUILD
#
UIMAGE=uImage
UIMAGER=uImage_recovery
#
#####-----
#
##////////////////////////////////////////////////////////////
# GO!
##////////////////////////////////////////////////////////////
#
FWD=`pwd`
cd $FWD/../../../../out/target/product/$DEVICE
echo '>>>>> Remove old files'
rm -rf $WORKDIR
mkdir -p $WORKDIR
echo '>>>>> Build initramfs'
cd $FWD/../../../../out/target/product/$DEVICE/root
find * | cpio -C 1 -R root:root -H newc -o > ../$WORKDIR/initramfs.new.cpio
cp ../ramdisk-recovery.cpio ../$WORKDIR/initramfs_rec.new.cpio
cp $FWD/${UIMAGE} $FWD/../../../../out/target/product/$DEVICE/$WORKDIR
cp $FWD/${UIMAGER} $FWD/../../../../out/target/product/$DEVICE/$WORKDIR
cp $FWD/mkimage $FWD/../../../../out/target/product/$DEVICE/$WORKDIR
cp $FWD/amltxtscript $FWD/../../../../out/target/product/$DEVICE/$WORKDIR
cd $FWD/../../../../out/target/product/$DEVICE/$WORKDIR
SWD=`pwd`
#
##////////////////////////////////////////////////////////////
# Checking for uImage magic word
# http://linux-arm.org/git?p=u-boot-armdev.git;a=blob;f=include/image.h
##////////////////////////////////////////////////////////////
#
echo ">>>>> Checking for uImage magic word ( 27051956 ) :"
MAGICWORD1=`dd if="${UIMAGE}" ibs=1 count=4 | hexdump -v -e '4/1 "%02X"'`
if [ '27051956' != "$MAGICWORD1" ]
	then
		echo "Not a uImage: $MAGICWORD1 != 27051956"
	exit 1
else
	echo "$UIMAGE acknowledged!"
fi
#
##
#
MAGICWORD2=`dd if=${UIMAGER} ibs=1 count=4 | hexdump -v -e '4/1 "%02X"'`
if [ '27051956' != "$MAGICWORD2" ]
	then
		echo "Not a uImage: $MAGICWORD2 != 27051956"
	exit 1
else
	echo "$UIMAGER acknowledged!"
fi
#
##////////////////////////////////////////////////////////////
# Remove header from uImage
##////////////////////////////////////////////////////////////
#
echo '>>>>> Remove header from uImage'
IMAGEOLDLZMA='Image.old.lzma'
dd if=${UIMAGE} bs=1 skip=64 of=${IMAGEOLDLZMA}
#
##
#
echo '>>>>> Remove header from uImage_recovery'
IMAGEOLDLZMAR='Image_rec.old.lzma'
dd if=${UIMAGER} bs=1 skip=64 of=${IMAGEOLDLZMAR}
#
##////////////////////////////////////////////////////////////
# Extracting kernel from uImages
##////////////////////////////////////////////////////////////
#
echo '>>>>> Extracting kernel from uImages'
IMAGE='Image.old'
unlzma < ${IMAGEOLDLZMA} > ${IMAGE}
#
IMAGER='Image_rec.old'
unlzma < ${IMAGEOLDLZMAR} > ${IMAGER}
echo '>>>>> Kernel extracted!'
#
##////////////////////////////////////////////////////////////
# Extracting config from kernel
##////////////////////////////////////////////////////////////
#
#echo "Extracting config from kernel"
#PRECONFIG=`grep -a -b -m 1 -o -P '\x1F\x8B\x08' ${IMAGE} | cut -f 1 -d :`
#dd if=${IMAGE} bs=1 skip=$PRECONFIG | gunzip > config
#
##////////////////////////////////////////////////////////////
#Extracting initramfs
# www.garykessler.net/library/file_sigs.html
# The end of the cpio archive is recognized with an empty file named 'TRAILER!!!' = '54 52 41 49 4C 45 52 21 21 21' (hexadecimal)
##////////////////////////////////////////////////////////////
#
echo '>>>>> Extracting initramfs from kernel'
CPIOSTART=`grep -a -b -m 1 -o '070701' ${IMAGE} | head -1 | cut -f 1 -d :`
CPIOEND=`grep -a -b -m 1 -o -P '\x54\x52\x41\x49\x4C\x45\x52\x21\x21\x21\x00\x00\x00\x00' ${IMAGE} | head -1 | cut -f 1 -d :`
CPIOEND=$((CPIOEND + 11 + 3))
CPIOSIZE=$((CPIOEND - CPIOSTART))
if [ "$CPIOSIZE" -le '0' ]
	then
		echo 'initramfs.cpio not found'
		exit
fi
dd if=${IMAGE} bs=1 skip=$CPIOSTART count=$CPIOSIZE > initramfs.old.cpio
OLDINITRAMFSDIR='initramfs-old'
mkdir -p $OLDINITRAMFSDIR
cd $OLDINITRAMFSDIR
cpio -v -i --no-absolute-filenames < ../initramfs.old.cpio
cd ..
#
##
#
echo '>>>>> Extracting recovery-initramfs from recovery-kernel'
CPIOSTARTR=`grep -a -b -m 1 -o '070701' ${IMAGER} | head -1 | cut -f 1 -d :`
CPIOENDR=`grep -a -b -m 1 -o -P '\x54\x52\x41\x49\x4C\x45\x52\x21\x21\x21\x00\x00\x00\x00' ${IMAGER} | head -1 | cut -f 1 -d :`
CPIOENDR=$((CPIOENDR + 11 + 3))
CPIOSIZER=$((CPIOENDR - CPIOSTARTR))
OLDINITRAMFSDIRR='initramfs_rec-old'
if [ "$CPIOSIZER" -le '0' ]
	then
		echo 'initramfs_rec.cpio not found'
		exit
fi
dd if=${IMAGER} bs=1 skip=$CPIOSTARTR count=$CPIOSIZER > initramfs_rec.old.cpio
mkdir -p $OLDINITRAMFSDIRR
cd $OLDINITRAMFSDIRR
cpio -v -i --no-absolute-filenames < ../initramfs_rec.old.cpio
cd ..
#
##////////////////////////////////////////////////////////////
# Fix initramfs size
##////////////////////////////////////////////////////////////
#
echo '>>>>> Fix initramfs size'
CPIOOLDSIZE=`ls -l initramfs.old.cpio | awk '{ print $5 }'`
CPIONEWSIZE=`ls -l initramfs.new.cpio | awk '{ print $5 }'`
if [ "$CPIONEWSIZE" -gt "$CPIOOLDSIZE" ]
	then
		echo "Sorry, initramfs.new.cpio exceeds $((CPIONEWSIZE-CPIOOLDSIZE)) bytes!"
		exit 1
else
	CPIOPADDING=$((CPIOOLDSIZE - CPIONEWSIZE))
	echo "Add $CPIOPADDING bytes to initramfs.new.cpio"
fi
cp initramfs.new.cpio initramfs.newfixed.cpio
dd if=/dev/zero bs=1 count=$CPIOPADDING >> initramfs.newfixed.cpio
echo '>>>>> Size of initramfs fixed!'
#
##
#
CPIOOLDSIZER=`ls -l initramfs_rec.old.cpio | awk '{ print $5 }'`
CPIONEWSIZER=`ls -l initramfs_rec.new.cpio | awk '{ print $5 }'`
if [ "$CPIONEWSIZER" -gt "$CPIOOLDSIZER" ]
	then
		echo "Sorry, initramfs_rec.new.cpio exceeds $((CPIONEWSIZER-CPIOOLDSIZER)) bytes!"
		exit 1
else
	CPIOPADDINGR=$((CPIOOLDSIZER - CPIONEWSIZER))
	echo "Add $CPIOPADDINGR bytes to initramfs_rec.new.cpio"
fi
cp initramfs_rec.new.cpio initramfs_rec.newfixed.cpio
dd if=/dev/zero bs=1 count=$CPIOPADDINGR >> initramfs_rec.newfixed.cpio
echo '>>>>> Size of recovery initramfs fixed!'
#
##////////////////////////////////////////////////////////////
# Rebuilding kernel Image
##////////////////////////////////////////////////////////////
#
IMAGENEW='Image.new'
IMAGENEWLZMA='Image.new.lzma'
dd if=${IMAGE} bs=1 count=$CPIOSTART of=${IMAGENEW}
cat initramfs.newfixed.cpio >> ${IMAGENEW}
dd if=${IMAGE} bs=1 skip=$CPIOEND >> ${IMAGENEW}
echo ">>>>> Compressing kernel Image to LZMA"
lzma < ${IMAGENEW} > ${IMAGENEWLZMA}
#
##
#
# Image.new != Image_rec.new #!!!
IMAGENEWR='Image_rec.new'
IMAGENEWLZMAR='Image_rec.new.lzma'
dd if=${IMAGER} bs=1 count=$CPIOSTARTR of=${IMAGENEWR}
cat initramfs_rec.newfixed.cpio >> ${IMAGENEWR}
dd if=${IMAGER} bs=1 skip=$CPIOENDR >> ${IMAGENEWR}
echo ">>>>> Compressing recovery kernel Image to LZMA"
lzma < ${IMAGENEWR} > ${IMAGENEWLZMAR}
#
##////////////////////////////////////////////////////////////
# Building uImage
##////////////////////////////////////////////////////////////
#
echo ">>>>> Making uImage"
mv uImage uImage-orig
./mkimage -A arm -O linux -T kernel -C lzma -a 80008000 -e 80008000 -d Image.new.lzma -n P2kernel uImage
cp uImage boot.img
echo ">>>>> Making uImage_recovery"
mv uImage_recovery uImage_recovery-orig
./mkimage -A arm -O linux -T kernel -C lzma -a 80008000 -e 80008000 -d Image_rec.new.lzma -n P2kernel uImage_recovery
echo ">>>>> Making aml_autoscript"
./mkimage -A arm -O linux -T script -C none -d amltxtscript -n P2kernel aml_autoscript
#
echo '>>>>> New kernel/recovery ready! <<<<<'
echo '>>>>> ENJOY!!! :) <<<<<'

