#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $MYDIR/../set-env.sh  > /dev/null

#cd $TOOLBIN
$TOOLBIN/mipsel-linux-gdb --ex="target remote :9000"  \
                          --ex="set sysroot $SYSROOT" \
	  	          --ex="directory $MYDIR"     \
		          --ex="directory $TOOLBIN"   \
                          $*

