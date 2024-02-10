const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const pci = @import("pci.zig");

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();
    pci.scanAllBuses();

    var xhc: *pci.Device = undefined;
    for (pci.devices) |device| {
        const class_code = pci.readClassCode(device.bus, device.device, device.function);
        if (class_code.base == 0x0c and class_code.sub == 0x3 and class_code.interface == 0x30) {
            xhc = @constCast(&device);
            break;
        }
    } else {
        console.print("xHC not found");
        while (true) asm volatile ("hlt");
    }

    console.printf("xHC BAR: 0x{x}\n", .{pci.readBar(xhc.bus, xhc.device, xhc.function)});
    console.printf("xHC MMIO base: 0x{x}\n", .{pci.readBar(xhc.bus, xhc.device, xhc.function) & 0xffff_ffff_ffff_fff0});

    while (true) asm volatile ("hlt");
}
