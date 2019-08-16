#!/bin/sh
#
# prepare the mod-kit folders layout and does some preliminary check
# This script has been checked ONLY with the Linkem image name
# "=01.01.02.090" with other image versions probably will not
# function correctly.
#
# in case of different firmware version this script can be used as a
# guide to do a similar job modifying what needs to be modified
#
# --------------------------------------------------------------------------------
MK_BASEDIR=$HOME/mod-kit                    # base dir of the mod-kit files

# --------------------------------------------------------------------------------
#
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
#
#
usage() {
    echo "usage: ./mod-kit-configure.sh [ -d basedir ] image-file"
    echo "   -d basedir (defautl $MK_BASEDIR)"
    echo "   -h this help"
    echo
    echo "   example:"
    echo "   ./mod-kit-configure.sh /path/to/06-kernel.bin"
    echo
    echo "   This command will prepare the mod-kit folders layout at"
    echo "   $MK_BASEDIR"
}

# ------ check image file
check_fwfile() {
    magic_number=`hexdump -s 0 -n 4 -ve '/1 "%02X"' $1`
    if [ "$magic_number" != "27051956" ]
    then
	echo "ERROR: Wrong U-Boot image file (wrong magic number)"
	exit 1
    fi
    
    remote_version=`hexdump -s 32 -n 13 -ve '/1 "%c"' $1`
    if [ "$remote_version" != "=01.01.02.090" ]
    then
	echo "ERROR: Wrong version (expecting =01.01.02.090 got $remote_version)"
	exit 2
    fi
}

# ------ process arguments
while getopts :d:h option
do
    case "${option}"
    in
	d) MK_BASEDIR="${OPTARG}";;
	h) usage
	   exit
	   ;;
	?) echo "ERROR: unexpected option"
	   usage
	   exit
	   ;;
    esac
done

shift $((OPTIND-1))


# ------ check input parameter (presence and firmware file existence)
echo "# ------ check input parameter (presence and firmware file existence)"


if [ "$1" = "" ] 
then
    usage
    exit
fi

FW_PATH=$1

if [ ! -e $FW_PATH ]
then
    echo $FW_PATH does not exists
    exit
fi
FW_FILE=`basename $FW_PATH`

check_fwfile $FW_PATH 


# ------ check for other needed commands
echo "# ------ check for other needed commands"

for i in mksquashfs unsquashfs crc32
do which $i
   ret=$?
   if [ ! "$ret" = "0" ]
   then
       echo "$i not present"
       echo "please install it" 
       exit 1
   else
       echo "#        $i found"
   fi
done


# ------ print main variables and create $MK_BASEDIR/conf.sh file
echo "# ------ main variables and create $MK_BASEDIR/conf.sh file"
echo "         MK_BASEDIR    $MK_BASEDIR"
echo "         FW_FILE       $FW_FILE"
echo "         SCRIPT        $SCRIPT"
echo "         SCRIPTPATH    $SCRIPTPATH"
echo "MK_BASEDIR=\"$MK_BASEDIR\""           > $SCRIPTPATH/conf.sh
echo "FW_FILE=\"$FW_FILE\""                >> $SCRIPTPATH/conf.sh 
echo

# ------ prepare folder layouts
echo "# ------ preparing folder layout at $MK_BASEDIR"
echo "#        $MK_BASEDIR/input         original firmware file and extracted data will go here"
echo "#        $MK_BASEDIR/input/root    original firmware root file system will go here"
echo "#        $MK_BASEDIR/root-patch    patches to each file will go here"
echo "#        $MK_BASEDIR/root-overlay  files here will be added/will overwrite files in the destination root"
echo "#        $MK_BASEDIR/output        modified firmware and output images will go here"
echo "#        $MK_BASEDIR/output/root   modified root file system will go here"
echo

for i in $MK_BASEDIR/input \
	 $MK_BASEDIR/input/root \
	 $MK_BASEDIR/root-patch \
	 $MK_BASEDIR/root-overlay \
	 $MK_BASEDIR/output \
	 $MK_BASEDIR/output/root
do if [ ! -d $i ]
   then
       echo "#    making dir $i"
       mkdir -p $i
   fi
done

# ------ copy files to mod-kit folder
echo "# ------ copying $FW_PATH --> $MK_BASEDIR/input"
cp $FW_PATH $MK_BASEDIR/input
echo "# ------ copying patch and overlay files to $MK_BASEDIR/root-patch"
rsync --exclude .gitignore -rav --delete $SCRIPTPATH/root-patch/   $MK_BASEDIR/root-patch/
rsync --exclude .gitignore -rav --delete $SCRIPTPATH/root-overlay/ $MK_BASEDIR/root-overlay/
cp -p $SCRIPTPATH/root-rm-files.txt     $MK_BASEDIR/
cp -p $SCRIPTPATH/pre-image-script.sh   $MK_BASEDIR/
