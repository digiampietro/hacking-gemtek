#!/bin/bash
export MIPS4KCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export MIPS4KCPARENT="$( cd $MIPS4KCDIR/.. && pwd )"
export BR2EXT="$MIPS4KCDIR/ext-tree"
export BRDIR="$( cd $MIPS4KCDIR/../buildroot-2* && pwd )"
export BRIMAGES=$BRDIR/output/images
export MIPSFIRM=$MIPS4KCPARENT/firmware
export MIPSROOT=$MIPSFIRM/root
export SYSROOT=$BRDIR/output/target
export TOOLBIN=$BRDIR/output/host/usr/bin

echo "MIPS4KCDIR:       $MIPS4KCDIR"
echo "MIPS4KCPARENT:    $MIPS4KCPARENT"
echo "BR2EXT:           $BR2EXT"
echo "BRDIR:            $BRDIR"
echo "BRIMAGES:         $BRIMAGES"
echo "MIPSFIRM:         $MIPSFIRM"
echo "MIPSROOT:         $MIPSROOT"
echo "SYSROOT:          $SYSROOT"
echo "TOOLBIN:          $TOOLBIN"


