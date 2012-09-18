echo '4016046080/255/63/512'|bc
sudo sfdisk -D -H 255 -S 63 -C 488 /dev/sdc << EOF
,9,b,*
,,,-
EOF
sudo mkfs.vfat /dev/sdc1 
sudo mkfs.ext2 /dev/sdc2 
readelf -A output/build/linux-3.2.8/vmlinux
sudo umount /dev/sdc?
(sudo rm -rf /media/boot/*; sudo cp MLO u-boot.img uEnv.txt uImage /media/boot/)
(SRC=$(pwd); cd /media/root/ && sudo rm -rf * && pv -cN in $SRC/rootfs.tar|sudo tar x)
