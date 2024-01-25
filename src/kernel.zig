const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const pci = @import("pci.zig");

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();

    pci.scanAllBuses();
    for (pci.devices) |device| {
        console.printf("{d}.{d}.{d} class_code: 0x{x}_{x}_{x} vendor: 0x{x}\n", .{
            device.bus,
            device.device,
            device.function,
            device.class_code.base,
            device.class_code.sub,
            device.class_code.interface,
            pci.readVendorID(device.bus, device.device, device.function),
        });
    }

    while (true) {
        asm volatile ("hlt");
    }
}
