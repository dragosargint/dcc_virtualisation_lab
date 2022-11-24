ZIMAGE="alpine-bzImage"
FS1="simple_alpine_rootfs1.ext4"
FS2="simple_alpine_rootfs2.ext4"

#QEMU_OPTS1="""-kernel $ZIMAGE \
#        -device virtio-serial \
#        -cpu host \
#        -enable-kvm \
#        -chardev pty,id=virtiocon0 -device virtconsole,chardev=virtiocon0 \
#	-netdev tap,id=tap0,ifname=tap0,script=no,downscript=no -device e1000,netdev=tap0,id=net0,mac=aa:fc:00:00:00:11 \
#        -netdev tap,id=tap1,ifname=tap1,script=no,downscript=no -net nic,netdev=tap1,model=i82559er \
#        -drive file=$FS1,if=virtio,format=raw \
#        --append "root=/dev/vda loglevel=15 console=hvc0" \
#        --display none -s -m 256"""
#
#QEMU_OPTS2="""-kernel $ZIMAGE \
#        -device virtio-serial \
#        -cpu host \
#        -enable-kvm \
#        -chardev pty,id=virtiocon0 -device virtconsole,chardev=virtiocon0 \
#	-netdev tap,id=tap2,ifname=tap2,script=no,downscript=no -device e1000,netdev=tap2,id=net2,mac=aa:fc:00:00:00:22 \
#	-netdev tap,id=tap3,ifname=tap3,script=no,downscript=no -net nic,netdev=tap3,model=i82559er \
#        -drive file=$FS2,if=virtio,format=raw \
#        --append "root=/dev/vda loglevel=15 console=hvc0" \
#        --display none -s -m 256"""
#
QEMU_OPTS1="""-kernel $ZIMAGE \
	-cpu host \
        -device isa-serial,chardev=serial0 -chardev socket,id=serial0,path=vm1,server,nowait 
	-enable-kvm \
	-device virtio-blk-pci,drive=id0 --blockdev file,node-name=id0,filename=simple_alpine_rootfs1.ext4 \
        --append "root=/dev/vda loglevel=15 console=hvc0" \
        --display none -m 256"""

	#-chardev socket,id=char0,path=vm1,server,nowait -serial chardev:char0 \
        #-drive file=$FS1,if=virtio,format=raw \
	#-netdev tap,ifname=tap0,id=hostnet0 -device e1000,netdev=hostnet0,id=net0,mac=52:54:00:8b:99:dc
QEMU_OPTS2="""-kernel $ZIMAGE \
        -device virtio-serial \
        -cpu host \
        -enable-kvm \
        -chardev pty,id=virtiocon0 -device virtconsole,chardev=virtiocon0 \
	-netdev tap,ifname=tap2,id=hostnet2 -device e1000,netdev=hostnet2,id=net2,mac=52:54:00:8b:99:de
        -drive file=$FS2,if=virtio,format=raw \
        --append "root=/dev/vda loglevel=15 console=hvc0" \
        --display none -s -m 256"""



qemu-system-x86_64 $QEMU_OPTS1 &
#qemu-system-x86_64 $QEMU_OPTS2 &

