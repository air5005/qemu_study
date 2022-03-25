# 用Qemu搭建x86_64学习环境

## 软件环境
Linux内核版本: Linux-5.16
Busybox版本: busybox-1.35.0
host: CentOS Linux release 8.3.2011

## linux内核编译
### 安装内核编译依赖软件
```
yum install -y flex bison ncurses-devel
```

### 编译命令
```
make O=out_x86_64 x86_64_defconfig
make O=out_x86_64 menuconfig
make O=out_x86_64 bzImage -j4
```

1. 由于下面要用到ramdisk的启动方式，需要在kernel配置中支持：
```
General setup > Initial RAM filesystem and RAM disk (initramfs/initrd) support
Device Drivers > Block devices > RAM block device support > (65536) Default RAM disk size (kbytes)
```
这里我们给ramdisk设置的默认大小是64MB,如果ramdisk越大,这里需要相应调整大一些,否则gzip解压rootfs会失败,
无法mount

2. 如果使用了内核的hotplug，需要打开这个配置
```
Device Drivers > Generic Driver Options > Support for uevent helper
```

## 编译busybox
```
make menuconfig
make -j4 
make install
```

```
make menuconfig
Settings > Build Options > Build static binary (no shared libs)   
```
  
编译busybox遇到的问题
```
/usr/bin/ld: cannot find -lm
/usr/bin/ld: cannot find -lresolv
collect2: error: ld returned 1 exit status
Note: if build needs additional libraries, put them in CONFIG_EXTRA_LDLIBS.
Example: CONFIG_EXTRA_LDLIBS="pthread dl tirpc audit pam"
make: *** [Makefile:719: busybox_unstripped] Error 1
```
需要安装 glibc static包,我这边是自己下载rpm包后直接安装的(下载命令在文本最后),具体命令
rpm -ivh glibc-static-2.28-164.el8.x86_64.rpm --nodeps
rpm -ivh libstdc++-8.5.0-3.el8.x86_64.rpm --nodeps

# 制作rootfs
```
#!/bin/bash
rm -rf ./rootfs
rm -rf ./tmpfs
rm -rf ./ramdisk*
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
cp -arf /lib/x86_64-linux-gnu/* rootfs/lib64/
rm rootfs/lib/*.a
strip rootfs/lib/*
mkdir -p rootfs/dev/
mknod rootfs/dev/tty1 c 4 1
mknod rootfs/dev/tty2 c 4 2
mknod rootfs/dev/tty3 c 4 3
mknod rootfs/dev/tty4 c 4 4
mknod rootfs/dev/console c 5 1
mknod rootfs/dev/null c 1 3
dd if=/dev/zero of=ramdisk bs=1G count=10
mkfs.ext4 -F ramdisk
mkdir -p tmpfs
mount -t ext4 ramdisk ./tmpfs/  -o loop
cp -raf rootfs/*  tmpfs/
umount tmpfs
gzip --best -c ramdisk > ramdisk.gz
```

# qemu启动内核
## 没带网络启动
```
qemu-system-x86_64 -smp 2 -m 2048M -kernel ./linux/out_x86_64/arch/x86_64/boot/bzImage -nographic -append "root=/dev/ram0 rw rootfstype=ext4 console=ttyS0 init=/linuxrc" -initrd ./rootfs/ramdisk.gz 
```
## 带tap网络启动
1. 内核需要配置tun/tap
Device Drivers > Networking support > [Y] Universal TUN/TAP device driver support
2. qemu启动命令增加 net nic tap
```
qemu-system-x86_64 -smp 2 -m 2048M -kernel ./linux/out_x86_64/arch/x86_64/boot/bzImage -nographic -append "root=/dev/ram0 rw rootfstype=ext4 console=ttyS0 init=/linuxrc" -initrd ./rootfs/ramdisk.gz -net nic -net tap,ifname=tap0,script=no,downscript=no
```
这样子启动的话，qemu会在宿主机和虚拟机两者之间创建一对tap口，这里的命令
-net nic : 给虚拟机增加一个网卡
-net tap,ifname=tap0,script=no,downscript=no : 网卡类型为tap
我们可以在宿主机看到一个虚拟tap网卡 tap0，同时可以看到虚拟机多了一个eth0网口，他们之间就是tap网口

3. 在宿主机创建一个虚拟br
```
ip link add br0 type bridge
ip link set br0 up
ifconfig br0 192.168.1.1/24
```
4. 把tap0挂到br0上面
```
ip link set tap0 master br0
ip link set tap0 up
```
5. 虚拟机里面的eth0配和br0同网段的ip就可以直接ping通了,配置默认路由到 br0，则可以直接访问外网
```
ifconfig eth0 192.168.1.2/24
route add default gw 192.168.1.1 dev eth0

[root@x86_64 ]# ping 192.168.1.1
PING 192.168.1.1 (192.168.1.1): 56 data bytes
64 bytes from 192.168.1.1: seq=0 ttl=64 time=1.576 ms
64 bytes from 192.168.1.1: seq=1 ttl=64 time=1.121 ms
64 bytes from 192.168.1.1: seq=2 ttl=64 time=1.277 ms
```

# 使用硬盘方式启动
1. 制作硬盘的rootfs,还是使用busybox为init
```
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
```
2. 启动命令
```
qemu-system-x86_64 -smp 2 -m 2048M -kernel ./linux/out_x86_64/arch/x86_64/boot/bzImage -nographic -drive format=raw,file=./rootfs/disk.raw -append "root=/dev/sda rw rootfstype=ext4 console=ttyS0 init=/linuxrc" -net nic -net tap,ifname=tap0,script=no,downscript=no
```

# 相关链接
git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
https://busybox.net/downloads/busybox-1.35.0.tar.bz2
https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libstdc++-8.5.0-3.el8.x86_64.rpm
https://vault.centos.org/centos/8/PowerTools/x86_64/os/Packages/glibc-static-2.28-164.el8.x86_64.rpm
