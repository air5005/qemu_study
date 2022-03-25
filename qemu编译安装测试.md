# 发行版本直接命令安装
Arch: `pacman -S qemu`
Debian/Ubuntu: `apt-get install qemu`
Fedora: `dnf install @virtualization`
Gentoo: `emerge --ask app-emulation/qemu`
RHEL/CentOS: `yum install qemu-kvm`
```
# qemu-system-x86_64命令无法找到，没有这个命令需要链接下，举个例子：
ln -s /usr/libexec/qemu-kvm /usr/local/bin/qemu-system-x86_64
```
SUSE: `zypper install qemu`

# 编译环境

## ubuntu环境下需要安装

```shell
sudo apt-get install -y git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev
sudo apt-get install -y git-email
sudo apt-get install -y libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev
sudo apt-get install -y libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev
sudo apt-get install -y libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev
sudo apt-get install -y librbd-dev librdmacm-dev
sudo apt-get install -y libsasl2-dev libsdl1.2-dev libseccomp-dev libsnappy-dev libssh2-1-dev
sudo apt-get install -y libvde-dev libvdeplug-dev libvte-2.90-dev libxen-dev liblzo2-dev
sudo apt-get install -y valgrind xfslibs-dev 
sudo apt-get install -y libnfs-dev libiscsi-dev
```

# 获取源代码
```shell
git clone git://git.qemu-project.org/qemu.git
```

# 简单构建和测试
## 编译原生调试版本
```shell
cd qemu
mkdir -p bin/debug/native
cd bin/debug/native
../../../configure --enable-debug
make
cd ../../..
```

## 编译遇到的问题
1. ERROR: Could not detect Ninja v1.8.2 or newer
如果发行系统安装的ninja小于 1.8.2,可以使用下面方法安装
```
wget https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip
sudo unzip ninja-linux.zip -d /usr/local/bin/
sudo update-alternatives --install /usr/bin/ninja ninja /usr/local/bin/ninja 1 --force
/usr/bin/ninja --version
```

## 测试
```shell
ych@:/mnt/d/git_code/qemu/bin/debug/native$ sudo ./x86_64-softmmu/qemu-system-x86_64 -L  pc-bios -nographic
SeaBIOS (version rel-1.16.0-0-gd239552ce722-prebuilt.qemu.org)

iPXE (http://ipxe.org) 00:03.0 CA00 PCI2.10 PnP PMM+07F91260+07EF1260 CA00

Booting from Hard Disk...
Boot failed: could not read the boot disk

Booting from Floppy...
Boot failed: could not read the boot disk

Booting from DVD/CD...
Boot failed: Could not read from CDROM (code 0003)
Booting from ROM...
iPXE (PCI 00:03.0) starting execution...ok
iPXE initialising devices...ok

iPXE 1.20.1+ (g4bd0) -- Open Source Network Boot Firmware -- http://ipxe.org
Features: DNS HTTP iSCSI TFTP AoE ELF MBOOT PXE bzImage Menu PXEXT

net0: 52:54:00:12:34:56 using 82540em on 0000:00:03.0 (open)
  [Link:up, TX:0 TXE:0 RX:0 RXE:0]
Configuring (net0 52:54:00:12:34:56)...... ok
net0: 10.0.2.15/255.255.255.0 gw 10.0.2.2
Nothing to boot: No such file or directory (http://ipxe.org/2d03e13b)
No more network devices

No bootable device.
```
此测试运行启动 PC BIOS 的 QEMU 系统仿真。

# 相关链接
[官网地址](https://www.qemu.org/)
[编译使用官网地址](https://wiki.qemu.org/Hosts/Linux)
https://wiki.qemu.org/Documentation