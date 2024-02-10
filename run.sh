#!/bin/sh

if [ "$1" = "debug" ]; then
    zig build -Ddebug=true
else
    zig build
fi

rm -f disk.img
qemu-img create -f raw disk.img 16M
mkfs.fat disk.img

mkdir -p mnt
sudo mount -o loop disk.img mnt
sudo mkdir -p mnt/efi/boot
sudo cp zig-out/bin/bootx64.efi mnt/efi/boot
sudo cp zig-out/bin/kernel.elf mnt
sudo umount mnt

if [ "$1" = "debug" ]; then
    qemu-system-x86_64 -m 1G -s -S -bios /usr/share/ovmf/OVMF.fd \
        -drive file=disk.img,if=ide,media=disk,index=0,format=raw -device qemu-xhci -monitor stdio --no-reboot
else
    qemu-system-x86_64 -m 1G -bios /usr/share/ovmf/OVMF.fd \
        -drive file=disk.img,if=ide,media=disk,index=0,format=raw -device qemu-xhci -monitor stdio --no-reboot
fi
