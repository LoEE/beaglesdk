# Ubuntu Tools

Here are some tools for making the default Ubuntu 12.04 user account more comfortable for development work.

# Installation:

Install an SSH server:

    sudo apt-get install openssh-server

To add your ssh public key (and generate one if you don't have any) to the target
machine's `~/.ssh/authorized_keys` (don't forget to substitute the `hostname` part at the end)

    sh <(wget -q -O - https://raw.github.com/jpc/ubuntu-tools/master/send-ssh-key) hostname

To install the config files and scripts run:

    wget -q -O - https://raw.github.com/jpc/ubuntu-tools/master/skeleton.tar|tar -xp

And then:

    sudo scripts/environment-setup

This will install several useful packages, including `gcc` & co., `git`, `hg` and `svn`. It will
also reconfigure sudo so it will allow you to run any command as root without being asked for
a password (this lowers the overall security but it is ok for a single-user development VM).
Check the source code for details.

# Usage:

The config files provide aliases for `du`, `ls` and `df` so they show human readable file
sizes and some `.inputrc` magic so that:

1. You can search the shell command history by typing a prefix and pressing the up arrow.
   For example by typing `rsync ` you can cycle through all rsync invocations.

2. Ctrl-Left and Ctrl-Right should jump over words.

## scripts/

There are several helper scripts for mounting SD cards using the nbd (network
block-device) protocol. They can be used to give the remote machine access to you local
SD card reader (it also works with a local VM and gives better performance than USB forwarding).

# SSH configuration hints:

You can put these into ~/.ssh/config on your local machine to get some nicer behaviour from SSH:

    GSSAPIAuthentication no
    # Keep a control channel open to speed up subsequent connections:
    ControlMaster auto
    ControlPath ~/.ssh/%r@%h:%p
    ControlPersist 120
    # Send keep-alives and timeout the SSH session after 60 seconds
    # without waiting for a TCP timeout (which can easily take several minutes)
    ServerAliveInterval 30
    ServerAliveCountMax 2

Example of site-specific configuration for the `10.1.3.249` host (running SSH on port 2222)
visible from `edge` which in turn is visible from the public internet:

    Host iris
    Hostname 10.1.3.249
    User iris
    ProxyCommand ssh edge -T -a nc %h 2222
    ForwardAgent yes

And another one so we can substitute `edge` every time `jdoe@edge.example.com` is needed
in an `ssh` (or `git` or `rsync`) invocation.

    Host edge
    Hostname edge.example.com
    User jdoe
