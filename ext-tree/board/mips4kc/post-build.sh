#!/bin/bash
echo "parameters: $*"    > /tmp/post-build.log
echo "MIPS4KCDIR:        $MIPS4KCDIR" >> /tmp/post-build.log
echo "BR2EXT:            $BR2EXT"    >> /tmp/post-build.log
echo "BRDIR:             $BRDIR"     >> /tmp/post-build.log
echo "BRIMAGES:          $BRIMAGES"  >> /tmp/post-build.log
echo "MIPSROOT:          $MIPSROOT"   >> /tmp/post-build.log
echo "MIPSFIRM:          $MIPSFIRM"   >> /tmp/post-build.log
ls $1 >> /tmp/post-build.log

DSTROOT="$1"
echo "DSTROOT:           $DSTROOT"   >> /tmp/post-build.log
#--------------------------------------------------------------------
# configure eth0 up with dhcp
#--------------------------------------------------------------------                                                                             
if grep eth0 $1/etc/network/interfaces >> /tmp/post-build.log
then
    echo "eth0 already configured" >> /tmp/post-build.log
else
    echo "configuring eth0 in interfaces" >> /tmp/post-build.log
    echo >> $DSTROOT/etc/network/interfaces
    echo "auto eth0" >> $1/etc/network/interfaces
    echo "iface eth0 inet dhcp" >> $1/etc/network/interfaces
    echo "  wait-delay 15" >> $1/etc/network/interfaces
fi
#--------------------------------------------------------------------
# copy Gemtek root file system
#--------------------------------------------------------------------
rsync -rav --delete $MIPSROOT/ $DSTROOT/mips-root/ >> /tmp/post-build.log 2>&1
#--------------------------------------------------------------------
# copy MIPS 5592 firmware files and scripts
#--------------------------------------------------------------------
mkdir $DSTROOT/mips-firm >> /tmp/post-build.log 2>&1
cp $MIPSFIRM/0*.bin                     $DSTROOT/mips-firm/ >> /tmp/post-build.log 2>&1
cp $MIPS4KCDIR/qemu-run/set-nandsim.sh  $DSTROOT/mips-firm/ >> /tmp/post-build.log 2>&1

