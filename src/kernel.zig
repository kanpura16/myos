const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const pci = @import("pci.zig");
const xhci = @import("driver/usb/xhci/xhci.zig");

var kernel_stack: [1024 * 1024 + 1]u8 align(16) = undefined;

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    asm volatile (
        \\lea 0x100000(%[kernel_stack]), %rsp
        \\mov %rsp, %rbp
        :
        : [kernel_stack] "{rax}" (&kernel_stack),
        : "rsp", "rbp"
    );

    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();
    pci.scanAllBuses();
    xhci.initXhci();

    while (true) asm volatile ("hlt");
}
