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
WORKDIR=NEWRECOVERY

UIMAGER=uImage_recovery

FWD=`pwd`

cd $FWD/IMAGES/NEWKERNEL/$DEVICE
SWD=`pwd`

##////////////////////////////////////////////////////////////
# GO!
##////////////////////////////////////////////////////////////

echo '>>>>> Remove old files'
rm -rf $WORKDIR
mkdir -p $WORKDIR
echo '>>>>> Build initramfs'
cd $SWD/root_recovery
find * | cpio -C 1 -R root:root -H newc -o > ../$WORKDIR/initramfs_rec.new.cpio
cp $FWD/$DEVICE/${UIMAGER} $SWD/$WORKDIR
cp $FWD/mkimage $SWD/$WORKDIR
cd $SWD/$WORKDIR

##////////////////////////////////////////////////////////////
# Checking for uImage_recovery magic word
# http://linux-arm.org/git?p=u-boot-armdev.git;a=blob;f=include/image.h
##////////////////////////////////////////////////////////////

echo '>>>>> Checking for uImage magic word ( 27051956 ) :'
MAGICWORD2=`dd if=${UIMAGER} ibs=1 count=4 | hexdump -v -e '4/1 "%02X"'`
if [ '27051956' != "$MAGICWORD2" ]
	then
		echo "Not a uImage: $MAGICWORD2 != 27051956"
	exit 1
else
	echo "$UIMAGER acknowledged!"
fi

##////////////////////////////////////////////////////////////
# Remove header from uImage_recovery
##////////////////////////////////////////////////////////////

echo '>>>>> Remove header from uImage_recovery'
IMAGEOLDLZMAR='Image_rec.old.lzma'
SKIPBIT=64
dd if=${UIMAGER} bs=1 skip=$SKIPBIT of=${IMAGEOLDLZMAR}

##////////////////////////////////////////////////////////////
# Extracting kernel from uImage_recovery
##////////////////////////////////////////////////////////////

echo '>>>>> Extracting kernel from uImage_recovery'
IMAGER='Image_rec.old'
unlzma < ${IMAGEOLDLZMAR} > ${IMAGER}
echo '>>>>> Kernel extracted!'

##////////////////////////////////////////////////////////////
#Extracting initramfs
# www.garykessler.net/library/file_sigs.html
# The end of the cpio archive is recognized with an empty file named 'TRAILER!!!' = '54 52 41 49 4C 45 52 21 21 21' (hexadecimal)
##////////////////////////////////////////////////////////////

echo '>>>>> Extracting recovery-initramfs from recovery-kernel'
CPIOSTARTR=`grep -a -b -m 1 -o '070701' ${IMAGER} | head -1 | cut -f 1 -d :`
CPIOENDR=`grep -a -b -m 1 -o -P '\x54\x52\x41\x49\x4C\x45\x52\x21\x21\x21\x00\x00\x00\x00' ${IMAGER} | head -1 | cut -f 1 -d :`
CPIOENDR=$((CPIOENDR + 11 + 3))
CPIOSIZER=$((CPIOENDR - CPIOSTARTR))
if [ "$CPIOSIZER" -le '0' ]
	then
		echo 'initramfs_rec.cpio not found'
		exit
fi
dd if=${IMAGER} bs=1 skip=$CPIOSTARTR count=$CPIOSIZER > initramfs_rec.old.cpio
OLDINITRAMFSDIRR='initramfs_rec-old'
mkdir -p $OLDINITRAMFSDIRR
cd $OLDINITRAMFSDIRR
cpio -v -i --no-absolute-filenames < ../initramfs_rec.old.cpio
cd ..

##////////////////////////////////////////////////////////////
# Fix initramfs size
##////////////////////////////////////////////////////////////

echo '>>>>> Fix initramfs size'
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

##////////////////////////////////////////////////////////////
# Rebuilding kernel Image
##////////////////////////////////////////////////////////////

echo '>>>>> Rebuilding kernel Image'
IMAGENEWR='Image_rec.new'
IMAGENEWLZMAR='Image_rec.new.lzma'
dd if=${IMAGER} bs=1 count=$CPIOSTARTR of=${IMAGENEWR}
cat initramfs_rec.newfixed.cpio >> ${IMAGENEWR}
dd if=${IMAGER} bs=1 skip=$CPIOENDR >> ${IMAGENEWR}
echo ">>>>> Compressing recovery kernel Image to LZMA"
lzma < ${IMAGENEWR} > ${IMAGENEWLZMAR}

##////////////////////////////////////////////////////////////
# Building uImage_recovery
##////////////////////////////////////////////////////////////

echo ">>>>> Making uImage_recovery"
(cat << EOF) > $SWD/$WORKDIR/amltxtscript
fatload mmc 0 82000000 uImage_recovery
bootm 82000000
EOF

mv uImage_recovery uImage_recovery-orig
./mkimage -A arm -O linux -T kernel -C lzma -a 80008000 -e 80008000 -d Image_rec.new.lzma -n MoonShadowl uImage_recovery
echo ">>>>> Making aml_autoscript"
./mkimage -A arm -O linux -T script -C none -d amltxtscript -n MoonShadow aml_autoscript

echo '>>>>> New recovery ready! <<<<<'
echo '>>>>> ENJOY!!! :) <<<<<'

