const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const pci = @import("pci.zig");
const xhci = @import("driver/usb/xhci/xhci.zig");

var kernel_stack: [1024 * 1024]u8 align(16) = undefined;

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    const stack_end_addr: u64 = @intFromPtr(&kernel_stack) + @sizeOf(@TypeOf(kernel_stack));
    asm volatile (
        \\mov %[stack_end_addr], %rsp
        \\mov %rsp, %rbp
        :
        : [stack_end_addr] "{rax}" (stack_end_addr),
        : "rsp", "rbp"
    );

    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();
    pci.scanAllBuses();
    xhci.initXhci();

    while (true) asm volatile ("hlt");
}
