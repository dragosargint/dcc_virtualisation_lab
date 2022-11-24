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
