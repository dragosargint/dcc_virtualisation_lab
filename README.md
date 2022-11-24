# Virtualization
## Introduction
In this lab we will use QEMU and KVM to build virtual machines.
QEMU is a userland type 2 (i.e runs upon a host OS) hypervisor for performing hardware virtualization, allowing code written for a given processor to be executed on another (i.e ARM on x86, or PPC on ARM).
Though QEMU can run on its own and emulate all of the virtual machine’s resources, as all the emulation is performed in software it is extremely slow.
KVM is a Linux kernel module.
It is a type 1 hypervisor that is a full virtualization solution for Linux on x86 hardware containing virtualization extensions (Intel VT or AMD-V).
But what is full virtualization, you may ask?
When a CPU is emulated (vCPU) by the hypervisor, the hypervisor has to translate the instructions meant for the vCPU to the physical CPU.
As you can imagine this has a massive performance impact.
To overcome this, modern processors support virtualization extensions, such as Intel VT-x and AMD-V.
These technologies provide the ability for a slice of the physical CPU to be directly mapped to the vCPU.
Therefore the instructions meant for the vCPU can be directly executed on the physical CPU slice.

## Setup
1. Clone this repository
```
git clone https://github.com/dragosargint/dcc_virtualisation_lab.git
```
2. Navigate into the cloned repo and download the following [filesystem](https://drive.google.com/file/d/1VcHDw1JEH-u3soOEJye1DxHCJgMbC-6c/view?usp=share_link)
3. TODO: Install deps

## Build a simple QEMU + KVM Virtual Machine
Let's see what we need to build a virtual machine.
First of all, we need a kernel image.
Secondly, we need a filesystem that contains the libraries part of the operating system.
And of course, we need a way to interact with the VM, so we can test it.
We have all these things at our disposal.
For this exercise, we will use the `alpine-bzImage` kernel image, which is simply the Linux kernel code compiled and linked in a compressed image.
And as a filesystem, we will use `simple_alpine_rootfs1.ext4`.
This file is formatted with the ext4 filesystem layout.
The directory hierarchy and libraries for an Alpine distribution are already installed on it.

In order to start our virtual machine, we will have to give a series of parameters to Qemu.
First of all we are going to use the KVM accelerator and we are going to enable the KVM features for our guest cpu:
```
-enable-kvm -cpu host
```
Second of all, we need to specify the amount of memory the guest is allowed to use. We will set it to 256MB:
```
-m 256M
```
Afterwards we can add I/O devices.
A good thing to bear in mind throughout the lab is that Qemu always uses 2 parts to emulate a device.
There's the guest (VM) hardware, which we are "emulating", and there's a backend in the host.
These two parts need to be linked together like in the following picture:

![qemu_two_parts](./images/qemu_two_parts.png)

Let's use the `virtio-blk-pci` device for the Guest and let's use our `simple_alpine_rootfs1.ext4` as a backend for the host.
The arguments should be:
```
-device virtio-blk-pci,drive=id0 -blockdev file,node-name=id0,filename=simple_alpine_rootfs1.ext4
```
By using this command the VM will see a block device (i.e. Hard Disk). But there is no Hard Disk, in the back there's just a file.
The string `id0` is how we link the block device to the backend (i.e. our ext4 formatted file).

Let's also add a serial console to our guest:
```
-device isa-serial,chardev=serial0 -chardev socket,id=serial0,path=serial.socket,server,nowait
```
As earlier, the string `serial0` is the way we link our guest serial device to our backend in the host.
In this case the backed in the host will be an UNIX socket with the name `serial.socket`.
If you're not familiar with UNIX sockets imagine them as a pipe through which data can flow in both direction.

Let's put all the pieces toghether and start the VM.
Complete the `TODO` in `runqemu_single_vm.sh` with the following command:
```
qemu-system-x86_64 \
        -nodefaults \
        -nographic \
        -enable-kvm \
        -cpu host \
        -m 256M \
        -kernel "alpine-bzImage" \
        -device virtio-blk-pci,drive=id0 -blockdev file,node-name=id0,filename=simple_alpine_rootfs1.ext4 \
        -device isa-serial,chardev=serial0 -chardev socket,id=serial0,path=serial.socket,server,nowait \
        -append "root=/dev/vda loglevel=15 console=hvc0"
```
The `-nodefaults` and `-nographic` arguments tells qemu NOT to add any default devices like a screen.
Run the script
```
./runqemu_single_vm.sh
```
In another terminal, to see if everything went well, use the following command to see if the qemu process is running:
```
pgrep qemu
```
Now if you removed the `-nodefaults` and `-nographic` arguments, qemu might open a display for you and you can use that terminal to login with the credentials:
```
username: student
password: student
```
But this is not so intersting, after all we defined our own socket to connect to the VM.
Let's connect to the serial console using the unix socket.
You can use the `connect_to_socket.sh` script as follows:
```
 ./connect_to_socket.sh /path/to/socket
```
You must press a key to get the login prompt, and you can login with the student credentials, or with the root credentials directly:
```
username: root
password: toor
```
When getting a shell play around with some comands:
```
ls /
ip a s
```
When running the `ip` command you can see that we have only the loopback interface.
That's because we didn't specify any network device, and we will do that in the next exercise.

To close the unix socket, from another terminal run:
```
pkill socat
```
To kill the vm you can `CTRL+C` where you run `./run_qemu_single_vm` or, from another terminal, use:
```
pkill qemu
```

# TODO: Add a network device to the VM
So far we managed to start a VM and connect to it through the serial console.
Let's add a network device to it.
For the guest part, we will use an e1000 device, that is a network card that uses the e1000 driver.
For the host part we will use a `tap` interface.
See the image below:

![qemu_nic](./images/qemu_nic.drawio.png)

Let's first create the backend (i.e. the `tap` interface).
To create a tap interface in Linux:
```
sudo ip tuntap add tap0 mode tap
sudo ip link set tap0 up
```
Let's also assign an ip address to it:
```
ip addr add 10.0.0.1/24 dev tap0
```
Now let's see how we can configure the guest device:
```
-device e1000,netdev=hostnet0,id=net0,mac=52:54:00:8b:99:de -netdev tap,ifname=tap0,id=hostnet0
```
As you can see we setup an e1000 device in the guest and we linked it to our host tap interface `tap0`.
We did that by specifing the string `hostnet0` (it can be any string as long as it is the same on both parts)
We also specified a mac address for the interface.
This is not mandatory as qemu could pick one up for us.
But when we are running multiple VMs we can end up with two VMs having the same mac address on their interfaces, and then
we cannot make them comunicate.
So, it's better if we specify it.

Let's go ahead and modify our `run_qemu_single_vm.sh` script to add the network interface:
```
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
```
Run it and connect to the serial console as we did before.
Use the `ip a s` command to list the interfaces, you should see something like this:

![ip_a_s](./images/ip_a_s.png)

Note that the mac address of the `eth0` interface is indeed what we specified.
Now let's set this interface up and assign an IP address to it:
```
ip link set eth0 up
ip addr add 10.0.0.10/24 dev eth0
```
If everything went well we should be able to ping our tap from inside the guest:
```
ping 10.0.0.1
```
And to ping the guest from the host:
```
ping 10.0.0.10
```
Now let's start an http server on the guest and `curl` it from the host.
Int the `/root` directory there's an `index.html` file.
In the guest run:
```
python3 -m http.server --directory /root
```
And wait a little bit until it says something like:
```
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) 
```
From the host run:
```
curl 10.0.0.10:8000
```

# TODO: Test e1000 driver vs virtio (add some scripts)

# TODO: GDB into the VM to see some intersting stuff (what's intersting to see?)

# TODO: UNIKRAFT VMs


## References
https://www.packetcoders.io/what-is-the-difference-between-qemu-and-kvm/
https://archive.fosdem.org/2018/schedule/event/vai_qemu_jungle/attachments/slides/2539/export/events/attachments/vai_qemu_jungle/slides/2539/qemu_cli_jungle.pdf