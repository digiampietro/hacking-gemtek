#!/bin/sh
#
# This script will be executed before the new squashfs root file system image is
# created
#
# The sequence, to create the new root file system image is the following:
#
#   1. input/root (original root file system) is copied to
#      output/root (new root file system)
#
#   2. patches in root-patch are applied to output/root
#
#   3. files in root-overlay are copied to output/root
#
#   4. this script is executed
#
# This script can be used to embed time stamps in some files or to do
# other processing before the new root file system image is created.
# by default it removes the login link to shell_auth and replace it
# with a link to /bin/busybox (tha standard /bin/login)
# 
# the following environment variables are available:
#
#    MK_BASEDIR  contains the base directory for the mod-kit,
#                $MK_BASEDIR/output/root contains the new root file
#                system that can be manipulated before the boot image
#                is created
#
#    SCRIPTPATH  contains the directory where is the mod-kit-run.sh 
#

cd $MK_BASEDIR/output/root/bin
rm -f login
ln -s /bin/busybox login



