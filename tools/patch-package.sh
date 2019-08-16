#!/bin/bash
#
# on many buildroot packages must be added the '-fPIC' to the CFLAGS option
# (gcc compiler flag) to successfully compile, this script simplify this process
# this scipt takes in input the list of packages to patch
#

export TOPATCH="file expat gdb libiconv gettext gmp libnfnetlink iptables ipsec-tools" 
# non necssario patchare: ipsec-tools json-c libssh2
export MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PARENTDIR="$( cd $MYDIR/.. && pwd )"
source $PARENTDIR/set-env.sh > /dev/null
export PKGDIR=$BRDIR/package
export PATCHDIR=$BR2EXT/patches
export TMPDIR=$(mktemp -d /tmp/brpatch.XXXX)    
mkdir -p $TMPDIR/a/package
mkdir -p $TMPDIR/b/package
export NPATCHED=0

if [ -z "$TOPATCH" ]
then
    echo "variable TOPATCH must not be empty"
    exit 1
fi


for PKG in $TOPATCH
do echo "generating patch for $PKG"
   export PKGNAME=`echo $PKG | tr '-' '_'`
   
   if [ ! -d $PKGDIR/$PKG ]
   then
       echo "WARNING package $PKG does not exist"
       continue
   fi
   if grep ' -fPIC' $PKGDIR/$PKG/$PKG.mk > /dev/null 
   then
       echo "WARNING package $PKG already patched"
       continue
   fi
   mkdir $TMPDIR/a/package/$PKG
   mkdir $TMPDIR/b/package/$PKG
   cp $PKGDIR/$PKG/$PKG.mk $TMPDIR/a/package/$PKG/
   echo "TARGET_CFLAGS += -fPIC"             >  $TMPDIR/b/package/$PKG/$PKG.mk
   echo ${PKGNAME^^}"_CONF_ENV = \\"        >> $TMPDIR/b/package/$PKG/$PKG.mk
   echo '        CFLAGS="$(TARGET_CFLAGS)"' >> $TMPDIR/b/package/$PKG/$PKG.mk
   cat $PKGDIR/$PKG/$PKG.mk                 >> $TMPDIR/b/package/$PKG/$PKG.mk
   ((NPATCHED=NPATCHED+1))
done

N=1;
printf -v NS "%04i" $N
echo "N: $N NS: $NS"
PATCHFILE=0001-add-fPIC.patch
while [ -e $PARENTDIR/$PATCHFILE ]
      do ((N=N+1))
      printf -v NS "%04i" $N
      echo "N: $N NS: $NS"
      PATCHFILE=$NS-add-fPIC.patch
done

if [ $NPATCHED -ne 0 ]
then
    pushd $TMPDIR > /dev/null
    diff -Naur a b > $PATCHFILE
    popd > /dev/null
    cp $TMPDIR/$PATCHFILE $PARENTDIR/$PATCHFILE
else
    echo "WARNING no patch file generated"
fi
echo "----------------------------------------"
echo "MYDIR:              $MYDIR"
echo "PARENTDIR:          $PARENTDIR"
echo "PKG:                $PKG"
echo "PKGNAME:            $PKGNAME"
echo "PKGDIR:             $PKGDIR"
echo "TMPDIR:             $TMPDIR"
echo "PATCHFILE:          $PATCHFILE" 
echo "----------------------------------------"

