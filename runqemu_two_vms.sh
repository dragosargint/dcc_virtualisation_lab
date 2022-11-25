#!/bin/bash
ZIMAGE="alpine-bzImage"
FS1="simple_alpine_rootfs1.ext4"
FS2="simple_alpine_rootfs2.ext4"
SERIAL1="serial_vm1.socket"
SERIAL2="serial_vm2.socket"
BR0_IP=10.0.0.1
BR1_IP=10.0.1.1
NW_MASK=24

if [[ $(id -u) != 0 ]]; then
        echo "Error: Please run this script as root"
        exit
fi

if [[ ! -f $FS1 ]]; then
        echo "Error: Could not find simple_alpine_rootfs1.ext4"
        echo "Error: Please download it from this link https://drive.google.com/drive/u/0/folders/1PqBOCx8IYmYaW6X46S6dB_lqeWRNMIJe place it in this directory" 
        exit
fi

if [[ ! -f $FS2 ]]; then
	cp $FS1 $FS2
fi

# creates tap0,tap1,tap2,tap3
create_taps()
{
	for i in $(seq 0 3)
	do
		tap="tap${i}"	
		echo "Creating $tap"
		ip tuntap add $tap mode tap
		ip link set $tap up
	done
}

#deletes tap0,tap1,tap2,tap3 if they exist
delete_taps()
{
	for i in $(seq 0 3)
	do
		tap="tap${i}"
		if ip a s dev $tap &> /dev/null; then
			echo "Deleting $tap"
			ip link delete $tap
		fi
	done
	echo ""
}

#deletes br0 and br1
delete_bridges()
{
	if ip a s dev br0 &> /dev/null; then
		echo "Deleting br0"
		ip link set br0 down
		brctl delbr br0
	fi
	if ip a s dev br1 &> /dev/null; then
		echo "Deleting br1"
		ip link set br1 down
		brctl delbr br1
	fi
}

#creates bridges br0, br1 and adds tap0,tap2 to br0 and tap1,tap3 to br1
create_bridges_and_add_taps()
{
	brctl addbr br0
	brctl addif br0 tap0
	brctl addif br0 tap2
	ip link set br0 up
	ip addr add $BR0_IP/$NW_MASK dev br0
	echo "Created br0"
	echo -e "\t Add tap0 and tap2 to br0"

	brctl addbr br1
	brctl addif br1 tap1
	brctl addif br1 tap3
	ip link set br1 up
	ip addr add $BR1_IP/$NW_MASK dev br1
	echo "Created br1"
	echo -e "\t Add tap1 and tap3 to br0"


}

delete_bridges
delete_taps
create_taps
create_bridges_and_add_taps


QEMU_OPTS1="""
        -nodefaults \
        -nographic \
        -enable-kvm \
        -cpu host \
        -m 256M \
        -kernel $ZIMAGE \
        -device virtio-blk-pci,drive=id0 -blockdev file,node-name=id0,filename=$FS1 \
        -device isa-serial,chardev=serial0 -chardev socket,id=serial0,path=$SERIAL1,server,nowait \
        -device e1000,netdev=hostnet0,id=net0,mac=52:54:00:8b:99:de -netdev tap,ifname=tap0,id=hostnet0 \
	-device virtio-net-pci,netdev=hostnet1,id=net1,mac=52:54:00:8b:99:df -netdev tap,ifname=tap1,id=hostnet1 \
        -append "root=/dev/vda loglevel=15 console=hvc0i"
"""

QEMU_OPTS2="""
        -nodefaults \
        -nographic \
        -enable-kvm \
        -cpu host \
        -m 256M \
        -kernel $ZIMAGE \
        -device virtio-blk-pci,drive=id1 -blockdev file,node-name=id1,filename=$FS2 \
        -device isa-serial,chardev=serial1 -chardev socket,id=serial1,path=$SERIAL2,server,nowait \
        -device e1000,netdev=hostnet2,id=net2,mac=52:54:00:8b:99:ce -netdev tap,ifname=tap2,id=hostnet2 \
	-device virtio-net-pci,netdev=hostnet3,id=net3,mac=52:54:00:8b:99:cf -netdev tap,ifname=tap3,id=hostnet3 \
        -append "root=/dev/vda loglevel=15 console=hvc0i"
"""


fn()
{
	echo ""
	echo "CTRL-C received allow me to do some cleaning"
	delete_bridges
	delete_taps

}
trap fn SIGINT

qemu-system-x86_64 $QEMU_OPTS1 &
qemu-system-x86_64 $QEMU_OPTS2 &
wait
