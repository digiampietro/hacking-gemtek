#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $MYDIR/../set-env.sh > /dev/null

echo "set breakpoint pending on"
for i in `$TOOLBIN/mipsel-linux-readelf --sym -D $1 \
         |grep FUNC \
         |grep UND  \
         |awk '{print $9}'`
do echo break $i
done
