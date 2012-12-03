#!/bin/bash

# Copyright (C) 2011-2012 Pasquale Convertini    aka psquare (psquare.dev@gmail.com)
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

DEVICE=$1
WORKDIR=INITRAMFS

UIMAGE=uImage

FWD=`pwd`

cd $FWD/IMAGES/$WORKDIR
SWD=`pwd`

##////////////////////////////////////////////////////////////
# GO!
##////////////////////////////////////////////////////////////

echo '>>>>> Remove old files'
rm -rf $DEVICE
mkdir -p $DEVICE
#echo '>>>>> Build initramfs'
#cd $SWD/root
#find * | cpio -C 1 -R root:root -H newc -o > ../$WORKDIR/initramfs.new.cpio
cp $FWD/$DEVICE/${UIMAGE} $SWD/$DEVICE
cp $FWD/mkimage $SWD/$DEVICE
cd $SWD/$DEVICE

##////////////////////////////////////////////////////////////
# Checking for uImage magic word
# http://linux-arm.org/git?p=u-boot-armdev.git;a=blob;f=include/image.h
##////////////////////////////////////////////////////////////

echo '>>>>> Checking for uImage magic word ( 27051956 ) :'
MAGICWORD1=`dd if="${UIMAGE}" ibs=1 count=4 | hexdump -v -e '4/1 "%02X"'`
if [ '27051956' != "$MAGICWORD1" ]
	then
		echo "Not a uImage: $MAGICWORD1 != 27051956"
	exit 1
else
	echo "$UIMAGE acknowledged!"
fi

##////////////////////////////////////////////////////////////
# Remove header from uImage
##////////////////////////////////////////////////////////////

echo '>>>>> Remove header from uImage'
IMAGEOLDLZMA='Image.old.lzma'
SKIPBIT=64
dd if=${UIMAGE} bs=1 skip=$SKIPBIT of=${IMAGEOLDLZMA}

##////////////////////////////////////////////////////////////
# Extracting kernel from uImages
##////////////////////////////////////////////////////////////

echo '>>>>> Extracting kernel from uImages'
IMAGE='Image.old'
unlzma < ${IMAGEOLDLZMA} > ${IMAGE}
echo '>>>>> Kernel extracted!'

##////////////////////////////////////////////////////////////
#Extracting initramfs
# www.garykessler.net/library/file_sigs.html
# The end of the cpio archive is recognized with an empty file named 'TRAILER!!!' = '54 52 41 49 4C 45 52 21 21 21' (hexadecimal)
##////////////////////////////////////////////////////////////

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

##////////////////////////////////////////////////////////////
# Fix initramfs size
##////////////////////////////////////////////////////////////

#echo '>>>>> Fix initramfs size'
#CPIOOLDSIZE=`ls -l initramfs.old.cpio | awk '{ print $5 }'`
#CPIONEWSIZE=`ls -l initramfs.new.cpio | awk '{ print $5 }'`
#if [ "$CPIONEWSIZE" -gt "$CPIOOLDSIZE" ]
#	then
#		echo "Sorry, initramfs.new.cpio exceeds $((CPIONEWSIZE-CPIOOLDSIZE)) bytes!"
#		exit 1
#else
#	CPIOPADDING=$((CPIOOLDSIZE - CPIONEWSIZE))
#	echo "Add $CPIOPADDING bytes to initramfs.new.cpio"
#fi
#cp initramfs.new.cpio initramfs.newfixed.cpio
#dd if=/dev/zero bs=1 count=$CPIOPADDING >> initramfs.newfixed.cpio
#echo '>>>>> Size of initramfs fixed!'

##////////////////////////////////////////////////////////////
# Rebuilding kernel Image
##////////////////////////////////////////////////////////////

#echo '>>>>> Rebuilding kernel Image'
#IMAGENEW='Image.new'
#IMAGENEWLZMA='Image.new.lzma'
#dd if=${IMAGE} bs=1 count=$CPIOSTART of=${IMAGENEW}
#cat initramfs.newfixed.cpio >> ${IMAGENEW}
#dd if=${IMAGE} bs=1 skip=$CPIOEND >> ${IMAGENEW}
#echo ">>>>> Compressing kernel Image to LZMA"
#lzma < ${IMAGENEW} > ${IMAGENEWLZMA}

##////////////////////////////////////////////////////////////
# Building uImage
##////////////////////////////////////////////////////////////

#echo ">>>>> Making uImage"
#mv uImage uImage-orig
#./mkimage -A arm -O linux -T kernel -C lzma -a 80008000 -e 80008000 -d Image.new.lzma -n PsquareKernel uImage
#cp uImage boot.img

#echo '>>>>> New kernel ready! <<<<<'
echo '>>>>> ENJOY!!! :) <<<<<'
