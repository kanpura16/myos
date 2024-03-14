#!/bin/sh

if [ "$1" = "debug" ]; then
    zig build -Ddebug=true
else
    zig build
fi

qemu-img create -f raw disk.img 32M
mkfs.fat disk.img

mkdir -p mnt
sudo mount -o loop disk.img mnt
sudo mkdir -p mnt/efi/boot
sudo cp zig-out/bin/bootx64.efi mnt/efi/boot
sudo cp zig-out/bin/kernel.elf mnt
sudo umount mnt

if [ "$1" = "debug" ]; then
    qemu-system-x86_64 -m 2G -s -S \
    -drive file=/usr/share/ovmf/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
    -drive file=/usr/share/ovmf/OVMF_VARS.fd,if=pflash,format=raw \
    -drive file=disk.img,if=ide,media=disk,index=0,format=raw \
    -device qemu-xhci -device usb-kbd \
    -monitor stdio \
    --trace events=qemu_trace.txt
else
    qemu-system-x86_64 -m 2G \
    -drive file=/usr/share/ovmf/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
    -drive file=/usr/share/ovmf/OVMF_VARS.fd,if=pflash,format=raw \
    -drive file=disk.img,if=ide,media=disk,index=0,format=raw \
    -device qemu-xhci -device usb-kbd \
    -monitor stdio \
    --trace events=qemu_trace.txt
fi
