#!/bin/bash


if [[ $(id -u) != 0 ]]; then
	echo "Error: Please run this script as root"
	exit
fi

if [[ ! -f simple_alpine_rootfs1.ext4 ]]; then
	echo "Error: Could not find simple_alpine_rootfs1.ext4"
	echo "Error: Please download it from this link https://drive.google.com/file/d/1VcHDw1JEH-u3soOEJye1DxHCJgMbC-6c/view and place it in this directory" 
	exit
fi

# TODO: Add qemu command here
qemu-system-x86_64 \
        -nodefaults \
        -nographic \
        -enable-kvm \
        -cpu host \
        -m 256M \
        -kernel "alpine-bzImage" \
        -device virtio-blk-pci,drive=id0 -blockdev file,node-name=id0,filename=simple_alpine_rootfs1.ext4 \
        -device isa-serial,chardev=serial0 -chardev socket,id=serial0,path=serial.socket,server,nowait \
        -device e1000,netdev=hostnet0,id=net0,mac=52:54:00:8b:99:de -netdev tap,ifname=tap0,id=hostnet0 \
        -append "root=/dev/vda loglevel=15 console=hvc0"
