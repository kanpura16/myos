const console = @import("console.zig");

const Device = struct {
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
    if (isSingleFunctionDevice(readHeaderType(0, 0, 0))) {
        scanBus(0);
    } else {
        var function: u8 = 0;
        while (function < 8) : (function += 1) {
            if (readVendorID(0, 0, function) == 0xffff) continue;
            scanBus(function);
        }
    }
}

fn scanBus(bus: u8) void {
    var device: u8 = 0;
    while (device < 32) : (device += 1) {
        scanDevice(bus, device);
    }
}

fn scanDevice(bus: u8, device: u8) void {
    var function: u8 = 0;
    if (readVendorID(bus, device, function) == 0xffff) return;
    addDevice(.{ .bus = bus, .device = device, .function = function, .class_code = readClassCode(bus, device, function) });
    scanFunction(bus, device, function);

    if (!isSingleFunctionDevice(readHeaderType(bus, device, function))) {
        while (function < 8) : (function += 1) {
            if (readVendorID(bus, device, function) == 0xffff) continue;
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
    if (num_device == devices.len) {
        console.print("pci.addDevice(): pci.devices is full");
    }

    devices[num_device] = device;
    num_device += 1;
}

pub fn readVendorID(bus: u8, device: u8, function: u8) u16 {
    return @intCast(readIOAddrSpace(makeIOPortAddr(bus, device, function, 0)) & 0xffff);
}

fn readHeaderType(bus: u8, device: u8, function: u8) u8 {
    return @intCast(readIOAddrSpace(makeIOPortAddr(bus, device, function, 0x0c)) >> 16 & 0xff);
}

fn readClassCode(bus: u8, device: u8, function: u8) ClassCode {
    const class_code: u32 = readIOAddrSpace(makeIOPortAddr(bus, device, function, 8));
    return .{
        .base = @intCast(class_code >> 24 & 0xff),
        .sub = @intCast(class_code >> 16 & 0xff),
        .interface = @intCast(class_code >> 8 & 0xff),
    };
}

fn readSecondaryBus(bus: u8, device: u8, function: u8) u8 {
    return @intCast(readIOAddrSpace(makeIOPortAddr(bus, device, function, 0x18)) >> 8 & 0xff);
}

fn isSingleFunctionDevice(header_type: u8) bool {
    return (header_type & 0b1000_0000) == 0;
}

fn makeIOPortAddr(bus: u8, device: u8, function: u8, reg_offset: u8) u32 {
    return 1 << 31 | @as(u32, @intCast(bus)) << 16 | @as(u32, @intCast(device)) << 11 | @as(u32, @intCast(function)) << 8 | (reg_offset & 0b1111_1100);
}

const config_addr_reg_addr: u16 = 0xcf8;
const config_data_reg_addr: u16 = 0xcfc;

fn writeIOAddrSpace(addr: u32, data: u32) void {
    IOOut32(config_addr_reg_addr, addr);
    IOOut32(config_data_reg_addr, data);
}

fn readIOAddrSpace(addr: u32) u32 {
    IOOut32(config_addr_reg_addr, addr);
    return IOIn32(config_data_reg_addr);
}

extern fn IOOut32(addr: u16, data: u32) void;
extern fn IOIn32(addr: u16) u32;

comptime {
    asm (
        \\IOOut32:
        // %dx = addr;
        \\  mov %di, %dx
        // %eax = data;
        \\  mov %esi, %eax
        \\  out %eax, %dx
        \\
        \\IOIn32:
        // %dx = addr
        \\  mov %di, %dx
        \\  in %dx, %eax
        // return %eax
        \\  ret
    );
}
