const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const pci = @import("pci.zig");

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();

    while (true) {
        asm volatile ("hlt");
    }
}
