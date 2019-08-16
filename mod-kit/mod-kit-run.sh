#!/bin/sh
#
# this script source conf.sh, on same directory, and then generates a new boot image file
# from the linkem image version =01.01.02.090
#
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
ERASESIZE=$((128 * 1024))
. $SCRIPTPATH/conf.sh
export MK_BASEDIR
export SCRIPTPATH
FW_NEW_FILE=`echo "$FW_FILE"|sed 's/\.bin$/-mod.bin/'`
if [ "$FW_NEW_FILE" = "$FW_FILE" ]
then
    FW_NEW_FILE="$FW_FILE-mod.bin"
fi

usage () {
    echo "usage: ./mod-kit-run.sh [ -c ] [ -h ] [-p password]"
    echo "       -c             clean all generated files from a previous run"
    echo "       -p password    set password for root, default 'no.wordpass'"
    echo "       -h             print this help"
}

setrootpass () {
    ENCRPASS=`mkpasswd -m md5 -S $SALT -s "$ROOTPASS"`
    ESCENCRPASS=`echo ${ENCRPASS} | sed  's/[\/&]/\\&/g'`
    echo "# ------ modifying root password"
    echo "         ROOTPASS      $ROOTPASS"
    echo "         SALT          $SALT"
    echo "         ENCRPASS      $ENCRPASS"
    echo "         ESCENCRPASS   $ESCENCRPASS"
    sed -i "s/^root:[^:]\+:0:0:root:/root:$ESCENCRPASS:0:0:root:/" $MK_BASEDIR/output/root/etc/passwd.orig
}

while getopts :cp:h option
do
    case "${option}"
    in
	c) OPMODE="CLEAN";;
	p) ROOTPASS="${OPTARG}"
	   SALT=`cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 8 | head -n 1`
	   ;;
	h) usage
	   exit
	   ;;
	?) echo "unexpected option"
	   usage
	   exit
	   ;;
    esac
done

shift $((OPTIND-1))

if [ "$1" != "" ]
then
    echo "unexpected argument"
    usage
    exit
fi


# ------ print main variables and create $MK_BASEDIR/conf.sh file
echo "------ main variables and create $MK_BASEDIR/conf.sh file"
echo "       MK_BASEDIR    $MK_BASEDIR"
echo "       FW_FILE       $FW_FILE"
echo "       FW_NEW_FILE   $FW_NEW_FILE"
echo "       SCRIPT        $SCRIPT"
echo "       SCRIPTPATH    $SCRIPTPATH"
echo "       ERASESIZE     $ERASESIZE"
echo "       FW_NEW_FILE   $FW_NEW_FILE"
echo "       OPMODE        $OPMODE"
echo

if [ "$OPMODE" = "CLEAN" ]
then
    echo "# ------ cleanup file generated in a previous run"
    rm -f  $MK_BASEDIR/fakeroot.dat
    rm -f  $MK_BASEDIR/input/*dat
    rm -f  $MK_BASEDIR/output/*bin
    rm -f  $MK_BASEDIR/output/*dat    
    rm -f  $MK_BASEDIR/output/*log
    rm -f  $MK_BASEDIR/output/*bin.xdelta    
    rm -rf $MK_BASEDIR/input/root/*
    rm -rf $MK_BASEDIR/output/root/*
    echo "#        cleanup done"
    exit
fi


# ------ extract u-boot header, u-boot lengths, u-boot kernel image, u-boot squashfs image
UHDRLEN=64           # U-Boot Header byte size
ULEN=24              # U-Boot Image lengths byte size
IMG1LEN=`(echo -n "ibase=16;obase=A;"; hexdump -s 64 -n 4 -ve '/1 "%02X"' $MK_BASEDIR/input/$FW_FILE ;echo) | bc`
IMG2LEN=`(echo -n "ibase=16;obase=A;"; hexdump -s 72 -n 4 -ve '/1 "%02X"' $MK_BASEDIR/input/$FW_FILE ;echo) | bc`
DATALEN=`echo $ULEN + $IMG1LEN + $IMG2LEN|bc`
HDRCRC32=`hexdump -s 4  -n 4 -ve '/1 "%02X"' $MK_BASEDIR/input/$FW_FILE`
DATACRC32=`hexdump -s 24 -n 4 -ve '/1 "%02X"' $MK_BASEDIR/input/$FW_FILE`
IMGFULLLEN="$(wc -c <"$MK_BASEDIR/input/$FW_FILE")"

echo "       IMG1LEN:         $IMG1LEN"
echo "       IMG2LEN:        $IMG2LEN"
echo "       DATALEN:        $DATALEN"
echo "       HDRCRC32:       $HDRCRC32"
echo "       DATACRC32:      $DATACRC32"
echo "       IMGFULLLEN:     $IMGFULLLEN"

echo "------ extract uboot header, lenghts, kernel, squashfs"
dd if=$MK_BASEDIR/input/$FW_FILE bs=1  skip=0                          count=64       of=$MK_BASEDIR/input/u01-hdr.dat

dd if=$MK_BASEDIR/input/$FW_FILE bs=1  skip=64                         count=24       of=$MK_BASEDIR/input/u02-len.dat   
if [ ! -e $MK_BASEDIR/input/u03-kern.dat ]
then
   dd if=$MK_BASEDIR/input/$FW_FILE bs=1  skip=88                         count=$IMG1LEN of=$MK_BASEDIR/input/u03-kern.dat
fi
if [ ! -e $MK_BASEDIR/input/u04-sqfs.dat ]
then
    dd if=$MK_BASEDIR/input/$FW_FILE bs=1  skip=`echo "88 + $IMG1LEN"|bc`  count=$IMG2LEN of=$MK_BASEDIR/input/u04-sqfs.dat
fi

echo "# ------ extract squashfs file system"
if [ -d $MK_BASEDIR/input/root ]
then
    rm -rf $MK_BASEDIR/input/root
fi

fakeroot -s $MK_BASEDIR/fakeroot.dat unsquashfs -d $MK_BASEDIR/input/root $MK_BASEDIR/input/u04-sqfs.dat

# ------ copy original root file system to new root file system
echo "# ------ copy original root file system to new root file system"
fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat rsync -rav --delete $MK_BASEDIR/input/root/ $MK_BASEDIR/output/root/

# ------ apply patches to new root file system
for i in `find $MK_BASEDIR/root-patch -name \*.patch -type f`
do echo "          applying $i"
   F=`echo $i|sed 's/root-patch/output\/root/'|sed 's/\.patch$//'`
   echo "          to       $F"
   fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat patch $F $i
done


# ------ apply overlay to new root file system
echo "# ------ apply overlay to new root file system"
fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat rsync --exclude=.gitignore -rav $MK_BASEDIR/root-overlay/ $MK_BASEDIR/output/root/

# ------ remove files/directories listed in root-rm-files.txt
echo "# ------ remove files/directories listed in root-rm-files.txt"
cat $MK_BASEDIR/root-rm-files.txt | grep -v '^#' | \
while read -r line
do
    if [ "$line" != "" ]
    then
	lastc=`echo -n $line | tail -c 1`
	if [ "$lastc" = "/" ]
	then
	    echo "         removing dir: $MK_BASEDIR/output/root/$line"
	    if [ -d "$MK_BASEDIR/output/root/$line" ] && fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat rm -rf "$MK_BASEDIR/output/root/$line"
	    then
		echo "         removed dir: $MK_BASEDIR/output/root/$line"
	    else		
		echo "UNRECOVERABLE ERROR in removing directory $MK_BASEDIR/output/root/$line"
		exit 1
	    fi
	else
	    echo "         removing file: $MK_BASEDIR/output/root/$line"
	    if [ -e "$MK_BASEDIR/output/root/$line" ] && fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat rm -f "$MK_BASEDIR/output/root/$line"
	    then
		echo "         removed file: $MK_BASEDIR/output/root/$line"
	    else
		echo "UNRECOVERABLE ERROR: cannot remove file $MK_BASEDIR/output/root/$line"
		exit 1
	    fi
	fi
    fi
done 

if [ "$?" != "0" ]
then
    exit 1
fi

# ------ execute the pre-image-script.sh
echo "# ------ executing the pre-image-script.sh"
if [ -x $MK_BASEDIR/pre-image-script.sh ] && fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat $MK_BASEDIR/pre-image-script.sh
then
    echo "#        executed the pre-image-script.sh"
else
    echo "UNRECOVERABLE ERROR in executing the pre-image-script.sh"
    exit 1
fi


# ------ create new root file system image
echo "------ create new root file system image"
fakeroot -i $MK_BASEDIR/fakeroot.dat -s $MK_BASEDIR/fakeroot.dat  mksquashfs $MK_BASEDIR/output/root/ $MK_BASEDIR/output/u04-sqfs.dat \
	   -comp         xz \
	   -b            131072 \
	   -no-xattrs        \
	   -noappend
	   
NEWIMG2LEN="$(wc -c <"$MK_BASEDIR/output/u04-sqfs.dat")"
NEWIMG2LENHEX=`echo "ibase=10;obase=16;$NEWIMG2LEN" | bc`
NEWIMG2LENHEX=`printf "%08s" $NEWIMG2LENHEX|tr ' ' '0'`
echo "         NEWIMG2LEN      $NEWIMG2LEN"
echo "         NEWIMG2LENHEX   $NEWIMG2LENHEX"

echo "------ copy u03-kern form input to output"
cp $MK_BASEDIR/input/u03-kern.dat $MK_BASEDIR/output/u03-kern.dat

echo "------ copy u02-len.dat from input to output and adjust squash fs length"
cp $MK_BASEDIR/input/u02-len.dat $MK_BASEDIR/output/u02-len.dat
echo -n $NEWIMG2LENHEX | xxd -r -p | dd of=$MK_BASEDIR/output/u02-len.dat conv=notrunc bs=1 count=4 seek=8

echo "------ generate u00-data.dat to calculate data CRC for U-Boot Header"
cat $MK_BASEDIR/output/u02-len.dat $MK_BASEDIR/output/u03-kern.dat $MK_BASEDIR/output/u04-sqfs.dat > $MK_BASEDIR/output/u00-data.dat
NEWDATACRC32=`crc32 $MK_BASEDIR/output/u00-data.dat|tr '[a-z]' '[A-Z]'`
NEWDATALEN="$(wc -c <"$MK_BASEDIR/output/u00-data.dat")"
NEWDATALENHEX=`echo "ibase=10;obase=16;$NEWDATALEN" | bc`
NEWDATALENHEX=`printf "%08s" $NEWDATALENHEX|tr ' ' '0'`
echo "         NEWDATALEN      $NEWDATALEN"
echo "         NEWDATALENHEX   $NEWDATALENHEX"
echo "         NEWDATACRC32    $NEWDATACRC32"

echo "------ copy U-Boot Header and recalculate CRC"
cp $MK_BASEDIR/input/u01-hdr.dat $MK_BASEDIR/output/u01-hdr.dat
# set to zero uboot header crc
dd if=/dev/zero of=$MK_BASEDIR/output/u01-hdr.dat conv=notrunc bs=1 count=4 seek=4
# set data len in uboot header
echo -n $NEWDATALENHEX | xxd -r -p | dd of=$MK_BASEDIR/output/u01-hdr.dat conv=notrunc bs=1 count=4 seek=12
# set data crc in uboot header
echo -n $NEWDATACRC32 | xxd -r -p | dd of=$MK_BASEDIR/output/u01-hdr.dat conv=notrunc bs=1 count=4 seek=24
# set header crc in uboot header
NEWHDRCRC32=`crc32 $MK_BASEDIR/output/u01-hdr.dat | tr '[a-z]' '[A-Z]'`
echo -n $NEWHDRCRC32 | xxd -r -p | dd of=$MK_BASEDIR/output/u01-hdr.dat conv=notrunc bs=1 count=4 seek=4
echo "         NEWHDRCRC32   $NEWHDRCRC32"

echo "------ build the new image $MK_BASEDIR/output/$FW_NEW_FILE"
cat $MK_BASEDIR/output/u01-hdr.dat $MK_BASEDIR/output/u00-data.dat > $MK_BASEDIR/output/$FW_NEW_FILE

echo "------ pad the new image to $IMGFULLLEN size"
IMGCURRLEN="$(wc -c <"$MK_BASEDIR/output/$FW_NEW_FILE")"
PADSIZE=$(($IMGFULLLEN - $IMGCURRLEN))
PAD1024=`echo "$PADSIZE / 1024" | bc`
echo "         IMGCURRLEN   $IMGCURRLEN"
echo "         PADSIZE      $PADSIZE"
echo "         PAD1024      $PAD1024"

echo "------ first step to create pad file"
tr '\000' '\377' < /dev/zero | dd of=$MK_BASEDIR/output/u99-pad.dat  bs=1024 count=$PAD1024

PADCURLEN="$(wc -c <"$MK_BASEDIR/output/u99-pad.dat")"
PADSIZE2=$(($PADSIZE - $PADCURLEN))
echo "         PADCURLEN    $PADCURLEN"
echo "         PADSIZE2     $PADSIZE2"

tr '\000' '\377' < /dev/zero | dd of=$MK_BASEDIR/output/u99-pad.dat bs=1 count=$PADSIZE2 seek=$PADCURLEN conv=notrunc
cp $MK_BASEDIR/output/$FW_NEW_FILE $MK_BASEDIR/output/$FW_NEW_FILE.dat

#tr '\000' '\377' < /dev/zero | dd of=$MK_BASEDIR/output/$FW_NEW_FILE bs=1 count=$PADSIZE seek=$IMGCURRLEN conv=notrunc

cat $MK_BASEDIR/output/$FW_NEW_FILE.dat $MK_BASEDIR/output/u99-pad.dat > $MK_BASEDIR/output/$FW_NEW_FILE
rm $MK_BASEDIR/output/$FW_NEW_FILE.dat

