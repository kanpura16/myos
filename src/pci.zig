const console = @import("console.zig");

pub const Device = struct {
    bus: u8,
    device: u8,
    function: u8,
    class_code: ClassCode,

    const ClassCode = struct {
        base: u8,
        sub: u8,
        interface: u8,
    };
};

pub var devices: [32]Device = undefined;
var num_device: u8 = 0;

pub fn scanAllBuses() void {
    for (0..256) |i_bus| {
        inline for (0..32) |i_device| {
            for (0..8) |i_func| {
                if (readVendorId(@intCast(i_bus), @intCast(i_device), @intCast(i_func)) == 0xffff) continue;

                if (num_device >= devices.len) {
                    console.print("\nWarn: pci.addDevice: pci.devices array is full\n");
                    return;
                }

                devices[num_device] = .{
                    .bus = @intCast(i_bus),
                    .device = @intCast(i_device),
                    .function = @intCast(i_func),
                    .class_code = readClassCode(@intCast(i_bus), @intCast(i_device), @intCast(i_func)),
                };
                num_device += 1;
            }
        }
    }
}

pub fn readVendorId(bus: u8, device: u8, function: u8) u16 {
    return @intCast(readIOAddrSpace(makeIoPortAddr(bus, device, function, 0)) & 0xffff);
}

pub fn readClassCode(bus: u8, device: u8, function: u8) Device.ClassCode {
    const class_code: u32 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 8));
    return .{
        .base = @intCast(class_code >> 24 & 0xff),
        .sub = @intCast(class_code >> 16 & 0xff),
        .interface = @intCast(class_code >> 8 & 0xff),
    };
}

pub fn readBar(bus: u8, device: u8, function: u8) u64 {
    const bar_low: u32 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x10));
    const bar_high: u64 = readIOAddrSpace(makeIoPortAddr(bus, device, function, 0x14));
    return bar_high << 32 | bar_low;
}

fn makeIoPortAddr(bus: u32, device: u32, function: u32, comptime reg_offset: u8) u32 {
    return 1 << 31 | bus << 16 | device << 11 | function << 8 | (reg_offset & 0b1111_1100);
}

const config_addr_reg: u16 = 0xcf8;
const config_data_reg: u16 = 0xcfc;

fn readIOAddrSpace(addr: u32) u32 {
    ioWrite32(config_addr_reg, addr);
    return ioRead32(config_data_reg);
}

fn writeIOAddrSpace(addr: u32, data: u32) void {
    ioWrite32(config_addr_reg, addr);
    ioWrite32(config_data_reg, data);
}

extern fn ioRead32(addr: u16) u32;
extern fn ioWrite32(addr: u16, data: u32) void;

comptime {
    asm (
        \\ioRead32:
        \\  mov %di, %dx
        \\  in %dx, %eax
        \\  ret
        \\
        \\ioWrite32:
        \\  mov %di, %dx
        \\  mov %esi, %eax
        \\  out %eax, %dx
        \\  ret
    );
}
