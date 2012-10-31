This repository contains scripts and instruction for improving the command line user experience of Ubuntu 12.04.
Part of the stuff here is specific to embedded Linux development for the BeagleBoard.

## Prepare the server

The server is the Ubuntu machine you wish to use for compilation. You should start by installing
the openssh server and downloading improved config files (dot files).

    sudo apt-get install openssh-server
    wget -q -O - https://raw.github.com/LoEE/beaglesdk/master/skeleton.tar|tar -xp

The new config files:

1. provide aliases for `du`, `ls` and `df` so they show human readable file sizes;

2. add some `.inputrc` magic so that:

   * you can search the shell command history by typing a prefix and pressing the up arrow;
     for example by typing `rsync ` you can cycle through all your rsync invocations;
   * Ctrl-Left and Ctrl-Right can be used jump over whole words;

I also recomend installing some additional software and allowing `sudo` without a password. This
can be done using an included script:

    sudo scripts/environment-setup

## Prepare the client

The client is you everyday workstation/laptop (Linux or OS X works best). First let's improve it's
ssh client configuration. Add the following directives to `.ssh/config`:

    # GSSAPI probing can potentatially cause slowdowns and you are probably not going to use it
    # https://bugs.launchpad.net/ubuntu/+source/openssh/+bug/84899
    GSSAPIAuthentication no

    # Keep a control channel open to speed up subsequent connections:
    ControlMaster auto
    ControlPath ~/.ssh/%r@%h:%p
    ControlPersist 120   # this only works with OpenSSH 5.6 or newer

    # Send keep-alives and timeout the SSH session after 60 seconds
    # without waiting for a TCP timeout (which can easily take several minutes):
    ServerAliveInterval 30
    ServerAliveCountMax 2

It is also convenient to define alternative names for frequently used hosts (especially if the
server is running on a port other than 22 or your local username does not match the remote one).
This alias can be used everywhere an ssh hostname is expected (including `scp` and `rsync`
invocations)

    Host bsdk
    Hostname beaglesdk.example.com
    User bsdk

Sometimes you may need to make a indirect connection through an intermediary. Let's assume we
have access to an SSH host called `edge` and that `edge` can connect to 192.168.1.10 which
we would like to call `bsdk`:

    Host bsdk
    Hostname 192.168.1.10
    User bsdk
    Port 2222
    RemoteForward 2005 localhost:2005
    ProxyCommand ssh edge -T nc %h %p

To avoid having to reenter passwords on every command we will setup key-based authentication. Running
the following one-liner on your workstation will generate an ssh key pair (if you don't already have one)
and then add it to `~/.ssh/authorized_keys` file on the specified server (`bsdk` in this example):

    sh <(wget -q -O - https://raw.github.com/LoEE/beaglesdk/master/send-ssh-key) bsdk

## Working with SD cards

TODO: how to correctly partition and format an SD card

If your compilation server is in a remote location or you just cannot plug a USB card reader directly
into it you can export your local block device representing the SD card over SSH (this is also better and faster
than forwarding a USB card reader to a virtual machine). To do this you need to run a network block device
server (`nbd-server` program) on your local computer (replace /dev/rdisk1 with an appropriate device name):

    sudo nbd-server 2005 /dev/rdisk1

When you want to load the card with a new kernel and/or filesystem execute:

    sudo umount /dev/rdisk1* && ssh bsdk -t 'cd /opt/buildroot/output/images && ~/scripts/nbd-go "localhost 2005"'

This will leave you in the shell on the target server with the SD card mounted
in `/media/boot` and `/media/root`. You are already placed in the buildroot output
directory so you can directly copy the "kernel" files with:

    (sudo rm -rf /media/boot/*; sudo cp MLO u-boot.img uEnv.txt uImage /media/boot/)

If you also wish to replace the root filesystem contents on the card then run:

    (SRC=$(pwd); cd /media/root/ && sudo rm -rf * && pv -cN in $SRC/rootfs.tar|sudo tar x)

## Compiling a GCC toolchain

This step will compile binutils (the assembler and linker), GCC (the C and C++ compiler) and
glibc (the C library). It will create a toolchain optimized for the OMAP3 in the BeagleBoard with
hardfp ABI (it will pass floating point arguments to functions via FPU registers without copying
them to memory or moving to ARM integer registers).

    cd /opt && hg clone ssh://hg@bitbucket.org/jpc/crosstool-ng && cd crosstool-ng
    ./configure --prefix=$PWD
    make install
    bin/ct-ng arm-omaphf-linux-gnueabi
    bin/ct-ng menuconfig    # optional
    bin/ct-ng build

## Compiling buildroot

This will compile everything else that is needed to create a fully functional Linux image
for the BeagleBoard. You have to have a toolchain installed in `/opt/arm-omaphf-linux-gnueabi`
(which the GCC compilation step should have done).

    cd /opt && git clone https://github.com/LoEE/buildroot && cd buildroot
    make beagle_xm_hf_full_defconfig
    make menuconfig         # optional
    make

If you wish to force a recompilation of some package then remove its build diretory. For example
if you wish to recompile uboot then run:

    rm -rf output/build/uboot-2011.12/

Some changes (like changing the contents of `fs/skeleton` or updating the toolchain) always require
a full recompilation which can be done by removing the whole `output` directory.
