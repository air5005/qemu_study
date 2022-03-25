#!/bin/bash

rm -rf ./rootfs
rm -rf ./diskfs
rm -rf ./disk.raw*

mkdir rootfs
cp ../busybox-1.35.0/_install/*  rootfs/ -raf

mkdir -p rootfs/proc/
mkdir -p rootfs/sys/
mkdir -p rootfs/tmp/
mkdir -p rootfs/root/
mkdir -p rootfs/var/
mkdir -p rootfs/mnt/

cp etc rootfs/ -arf
mkdir -p rootfs/lib64

cp -arf /lib64/* rootfs/lib64/

rm rootfs/lib64/*.a
strip rootfs/lib64/*

mkdir -p rootfs/dev/
mknod rootfs/dev/tty1 c 4 1
mknod rootfs/dev/tty2 c 4 2
mknod rootfs/dev/tty3 c 4 3
mknod rootfs/dev/tty4 c 4 4
mknod rootfs/dev/console c 5 1
mknod rootfs/dev/null c 1 3

qemu-img create -f raw disk.raw 5G
mkfs -t ext4 ./disk.raw
mkdir -p diskfs
mount -o loop ./disk.raw ./diskfs
cp -raf rootfs/*  diskfs/
umount diskfs
