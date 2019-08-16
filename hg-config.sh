#!/bin/bash
#
# usage: ./hg-config eeprom.bin
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $MYDIR/set-env.sh
ERASESIZE=$((128 * 1024))
cd $MYDIR

# first parameter must be the eeprom image and must be 128Mb (134217728 bytes)

if [ ! -e $1 ]
then
    echo "Usage: ./hg-config eeprom.bin"
    exit 1
fi
EPROMSIZE=`wc < $1`
if [ ! $EPROMSIZE -eq 134217728 ]
then
    echo "ERROR: $1 must be exaclty 128Mb (134,217,728 bytes)"
    exit 1
fi

# ---------------------------------------------------------------
# create directories in parent directory
# ---------------------------------------------------------------
for i in download firmware
do
    if [ -d "$MIPS4KCPARENT/$i" ]
    then
	echo "-----> directory $MIPS4KCPARENT/$i already exists"
    else
	echo "-----> creating dir: $MIPS4KCPARENT/$i"
	mkdir $MIPS4KCPARENT/$i
	if [ "$?" != "0" ]
	then
	    echo "-----> ERROR in mkdir, aborting"
	    exit 1
	fi
    fi
done

# ---------------------------------------------------------------
# check for curl sha1sum binwalk unzip
# ---------------------------------------------------------------
for i in curl sha1sum binwalk unzip dd
do which $i
   ret=$?
   if [ ! "$ret" = "0" ]
   then
       echo "-----> $i not present, aborting"
       echo "-----> please install it" 
       if [ "$i" = "jefferson" ]
       then
	   echo "-----> look at https://github.com/sviehb/jefferson"
       fi  
       exit 1
   else
       echo "-----> $i found"
   fi
done

# ---------------------------------------------------------------
# download buildroot, firmware and specific kernel file
# ---------------------------------------------------------------
DOWNFILE[0]="buildroot-2015.02.tar.gz"
DOWNURL[0]="https://buildroot.org/downloads/buildroot-2015.02.tar.gz"
DOWNCKSUM[0]="fad589eeda5eeff837ec21624cb5faff87efb496"

DOWNFILE[1]=`basename $1`
DOWNURL[1]="file://$1"
DOWNCKSUM[1]="ed6f25fca11cc3bf22b6ac36f7c17dc9e5db5c42"

for i in ${!DOWNFILE[*]}
do
    F=$MIPS4KCPARENT/download/${DOWNFILE[$i]}
    FCK=""
    URLCK=${DOWNCKSUM[$i]}
    if [ -e $F ]
    then
	FCK=`sha1sum $F | awk '{print $1}'`
	echo "-----> `basename $F` exits with checksum $FCK"
    fi
    if [ "$FCK" == "$URLCK" ]
    then
	echo "-----> `basename $F` already downloaded, not downloading"
    else
	echo "-----> Downloading ${DOWNURL[$i]} to $F"
	curl -o $F ${DOWNURL[$i]}
	if [ "$?" != "0" ]
	then
	   echo "-----> ERROR downloading ${DOWNURL[$i]}, aborting"
	   exit 1
	fi
	FCK=`sha1sum $F | awk '{print $1}'`
	if [ "$FCK" != "$URLCK" ]
	then
	    echo "-----> ERROR downloading ${DOWNURL[$i]}, bad checksum, aborting"
	    exit 1
	fi
    fi
done

# ---------------------------------------------------------------
# extract buildroot
# ---------------------------------------------------------------
BRDIR=`echo ${DOWNFILE[0]}|sed "s/.tar.gz//"`
if [ -d  "$MIPS4KCPARENT/$BRDIR" ]
then
    echo "-----> $MIPS4KCPARENT/$BRDIR"
    echo "----->       already exists, skip untarring. Remove it to force untarring ${DOWNFILE[0]}"
else
    echo "-----> untarring ${DOWNFILE[0]}"
    tar -C $MIPS4KCPARENT/ -xvf $MIPS4KCPARENT/download/${DOWNFILE[0]}
    if [ "$?" != "0" ]
    then
	echo "-----> ERROR untarring ${DOWNFILE[0]}, aborting"
	exit 1
    fi
    echo "-----> patching buildroot"
    pushd "$MIPS4KCPARENT/$BRDIR"
    for PATCH in $MYDIR/0*.patch
    do echo "applying patch: $PATCH"
	patch -N -p1 < $PATCH
    done
    popd
fi

# ---------------------------------------------------------------
# extract firmware
# ---------------------------------------------------------------
FIRMFILE=$MIPS4KCPARENT/download/${DOWNFILE[1]}
if [ -d $MIPSFIRM/root ]
then
    echo "-----> firmware file already extracted"
    echo "-----> to force re-extraction remove $MIPSFIRM/root and"
    echo "-----> remove $MIPSFIRM/boot"
else
    echo "-----> extracting firmware, requires some time"
    dd if=$FIRMFILE of=$MIPSFIRM/01-bootloader.bin  bs=1024 skip=0      count=1024 
    dd if=$FIRMFILE of=$MIPSFIRM/02-bootloader2.bin bs=1024 skip=1024   count=1024 
    dd if=$FIRMFILE of=$MIPSFIRM/03-config.bin      bs=1024 skip=2048   count=1024 
    dd if=$FIRMFILE of=$MIPSFIRM/04-env1.bin        bs=1024 skip=3072   count=2560 
    dd if=$FIRMFILE of=$MIPSFIRM/05-env2.bin        bs=1024 skip=5632   count=2560 
    dd if=$FIRMFILE of=$MIPSFIRM/06-kernel.bin      bs=1024 skip=8192   count=32768 
    dd if=$FIRMFILE of=$MIPSFIRM/07-kernel2.bin     bs=1024 skip=40960  count=32768 
    dd if=$FIRMFILE of=$MIPSFIRM/08-storage.bin     bs=1024 skip=73728  count=28672 
    dd if=$FIRMFILE of=$MIPSFIRM/09-storages.bin    bs=1024 skip=102400 count=28160
    echo "-----> extracting squasfs root file system image"
    IMG1LEN=`(echo -n "ibase=16;obase=A;"; hexdump -s 64 -n 4 -ve '/1 "%02X"' $MIPSFIRM/06-kernel.bin ;echo) | bc`
    IMG2LEN=`(echo -n "ibase=16;obase=A;"; hexdump -s 72 -n 4 -ve '/1 "%02X"' $MIPSFIRM/06-kernel.bin ;echo) | bc`

    echo "-----> extracting the U-Boot header, first 64 bytes"
    dd if=$MIPSFIRM/06-kernel.bin bs=1  skip=0                          count=64       of=$MIPSFIRM/u01-hdr.dat

    echo "-----> extract the image lenghts data segment, 24 bytes"
    dd if=$MIPSFIRM/06-kernel.bin bs=1  skip=64                         count=24       of=$MIPSFIRM/u02-len.dat

    echo "-----> extract the compressed kernel"
    dd if=$MIPSFIRM/06-kernel.bin bs=1  skip=88                         count=$IMG1LEN of=$MIPSFIRM/u03-kern.dat

    echo "-----> extracting the squashfs file system image"
    dd if=$MIPSFIRM/06-kernel.bin bs=1  skip=`echo "88 + $IMG1LEN"|bc`  count=$IMG2LEN of=$MIPSFIRM/u04-sqfs.dat

    echo "-----> extracting the squashfs file system"
    mkdir $MIPSFIRM/root
    fakeroot -s $MIPSFIRM/fakeroot.dat unsquashfs -d $MIPSFIRM/root $MIPSFIRM/u04-sqfs.dat
fi

cd $CURRWD


