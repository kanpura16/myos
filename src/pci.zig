const console = @import("console.zig");

pub const Device = struct {
    bus: u8,
    device: u8,
    function: u8,
    class_code: ClassCode,
};

const ClassCode = struct {
    base: u8,
    sub: u8,
    interface: u8,
};

pub var devices: [32]Device = undefined;
var num_device: u8 = 0;

pub fn scanAllBuses() void {
    if (isSingleFuncDev(0, 0, 0)) {
        scanBus(0);
    } else {
        var function: u8 = 0;
        while (function < 8) : (function += 1) {
            if (readVendorId(0, 0, function) == 0xffff) continue;
            scanBus(function);
        }
    }
}

fn scanBus(bus: u8) void {
    var device: u8 = 0;
    while (device < 32) : (device += 1) {
        if (readVendorId(bus, device, 0) == 0xffff) continue;
        scanDevice(bus, device);
    }
}

fn scanDevice(bus: u8, device: u8) void {
    if (isSingleFuncDev(bus, device, 0)) {
        addDevice(.{ .bus = bus, .device = device, .function = 0, .class_code = readClassCode(bus, device, 0) });
        scanFunction(bus, device, 0);
    } else {
        var function: u8 = 0;
        while (function < 8) : (function += 1) {
            if (readVendorId(bus, device, function) == 0xffff) continue;

            addDevice(.{ .bus = bus, .device = device, .function = function, .class_code = readClassCode(bus, device, function) });
            scanFunction(bus, device, function);
        }
    }
}

fn scanFunction(bus: u8, device: u8, function: u8) void {
    const class_code = readClassCode(bus, device, function);
    if (class_code.base == 6 and class_code.sub == 4) {
        // PCI-to-PCI bridge
        return scanBus(readSecondaryBus(bus, device, function));
    }
}

fn addDevice(device: Device) void {
    if (num_device >= devices.len) {
        console.print("pci.addDevice(): pci.devices is full");
        return;
    }

    devices[num_device] = device;
    num_device += 1;
}

pub fn readVendorId(bus: u8, device: u8, function: u8) u16 {
    return @intCast(readIOAddrSpace(makeIoPortAddr(bus, device, function, 0)) & 0xffff);
}

pub fn readClassCode(bus: u8, device: u8, function: u8) ClassCode {
    const class_code: u32 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 8));
    return .{
        .base = @intCast(class_code >> 24 & 0xff),
        .sub = @intCast(class_code >> 16 & 0xff),
        .interface = @intCast(class_code >> 8 & 0xff),
    };
}

pub fn readBar(bus: u8, device: u8, function: u8) u64 {
    const bar0: u64 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x10));
    const bar1: u64 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x14));
    return bar1 << 32 | bar0;
}

fn readHeaderType(bus: u8, device: u8, function: u8) u8 {
    return @intCast(readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x0c)) >> 16 & 0xff);
}

fn isSingleFuncDev(bus: u8, device: u8, function: u8) bool {
    return (readHeaderType(bus, device, function) & 0b1000_0000) == 0;
}

fn readSecondaryBus(bus: u8, device: u8, function: u8) u8 {
    return @intCast(readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x18)) >> 8 & 0xff);
}

fn makeIoPortAddr(bus: u8, device: u8, function: u8, reg_offset: u8) u32 {
    return 1 << 31 | @as(u32, @intCast(bus)) << 16 | @as(u32, @intCast(device)) << 11 | @as(u32, @intCast(function)) << 8 | (reg_offset & 0b1111_1100);
}

const config_addr_reg: u16 = 0xcf8;
const config_data_reg: u16 = 0xcfc;

fn writeIOAddrSpace(addr: u32, data: u32) void {
    ioWrite32(config_addr_reg, addr);
    ioWrite32(config_data_reg, data);
}

fn readIOAddrSpace(addr: u32) u32 {
    ioWrite32(config_addr_reg, addr);
    return ioRead32(config_data_reg);
}

extern fn ioWrite32(addr: u16, data: u32) void;
extern fn ioRead32(addr: u16) u32;

comptime {
    asm (
        \\ioWrite32:
        \\  mov %di, %dx
        \\  mov %esi, %eax
        \\  out %eax, %dx
        \\  ret
        \\
        \\ioRead32:
        \\  mov %di, %dx
        \\  in %dx, %eax
        \\  ret
    );
}
