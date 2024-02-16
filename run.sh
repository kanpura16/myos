#!/bin/sh

if [ "$1" = "debug" ]; then
    zig build -Ddebug=true
else
    zig build
fi

rm -f disk.img
qemu-img create -f raw disk.img 32M
mkfs.fat disk.img

mkdir -p mnt
sudo mount -o loop disk.img mnt
sudo mkdir -p mnt/efi/boot
sudo cp zig-out/bin/bootx64.efi mnt/efi/boot
sudo cp zig-out/bin/kernel.elf mnt
sudo umount mnt

if [ "$1" = "debug" ]; then
    qemu-system-x86_64 -m 2G -s -S -bios /usr/share/ovmf/OVMF.fd \
        -drive file=disk.img,if=ide,media=disk,index=0,format=raw -device qemu-xhci -device usb-kbd -monitor stdio --no-reboot --trace events=qemu_trace.txt
else
    qemu-system-x86_64 -m 2G -bios /usr/share/ovmf/OVMF.fd \
        -drive file=disk.img,if=ide,media=disk,index=0,format=raw -device qemu-xhci -device usb-kbd -monitor stdio --no-reboot --trace events=qemu_trace.txt
fi
