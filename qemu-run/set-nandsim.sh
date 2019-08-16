#!/bin/sh
#
# the following line simulate a NAND Flash with 128MBbytes, 2048 bytes per page, 128Kb erasesize
# see http://www.linux-mtd.infradead.org/faq/nand.html
# 9 partitions are created, as in the Gemtek router, parameters in parts represents partition length
# in multiple of 128Kb
#
#modprobe nandsim first_id_byte=0x20 second_id_byte=0xa1 third_id_byte=0x00 fourth_id_byte=0x15 parts=8,8,8,20,20,256,256,224,220
modprobe nandsim first_id_byte=0xc8 second_id_byte=0xd1 third_id_byte=0x80 fourth_id_byte=0x95 fifth_id_byte=0x42 parts=8,8,8,20,20,256,256,224,220
#
flash_erase /dev/mtd0 0   8   #   1,024   Bootloader
flash_erase /dev/mtd1 0   8   #   1,024   Bootloader2
flash_erase /dev/mtd2 0   8   #   1,024   Config
flash_erase /dev/mtd3 0  20   #   2,560   Env1
flash_erase /dev/mtd4 0  20   #   2,560   Env2
flash_erase /dev/mtd5 0 256   #  32,768   Kernel
flash_erase /dev/mtd6 0 256   #  32,768   Kernel2
flash_erase /dev/mtd7 0 224   #  28,672   Storage1
flash_erase /dev/mtd8 0 220   #  28,160   Storage2
#
nandwrite /dev/mtd0 01-bootloader.bin
nandwrite /dev/mtd1 02-bootloader2.bin
nandwrite /dev/mtd2 03-config.bin
nandwrite /dev/mtd3 04-env1.bin
nandwrite /dev/mtd4 05-env2.bin
nandwrite /dev/mtd5 06-kernel.bin
nandwrite /dev/mtd6 07-kernel2.bin
nandwrite /dev/mtd7 08-storage.bin
nandwrite /dev/mtd8 09-storages.bin
#
echo "export PATH=$PATH:/mips-root/bin:/mips-root/sbin:/mips-root/usr/bin:/mips-root/usr/sbin"
echo "export LD_LIBRARY_PATH=/lib:/usr/lib:/mips-root/lib:/mips-root/usr/lib"
