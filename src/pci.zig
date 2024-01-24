const Device = struct {
    bus: u8,
    device: u5,
    function: u3,
    class_code: ClassCode,
};

const ClassCode = struct {
    base: u8,
    sub: u8,
    interface: u8,
};

fn readVendorID(bus: u8, device: u8, function: u8) u16 {
    return @intCast(readIOAddrSpace(makeIOPortAddr(bus, device, function, 0)) & 0xffff);
}

fn readHeaderType(bus: u8, device: u8, function: u8) u8 {
    return @intCast(readIOAddrSpace(makeIOPortAddr(bus, device, function, 0x0c)) >> 16 & 0xffff);
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
    // fn IOOut32(addr: u16, data: u32) void;
        \\IOOut32:
        // %dx = addr;
        \\  mov %di, %dx
        // %eax = data;
        \\  mov %esi, %eax
        \\  out %eax, %dx

        // fn IOIn32(addr: u16) u32;
        \\IOIn32:
        // %dx = addr
        \\  mov %di, %dx
        \\  in %dx, %eax
        // return %eax
        \\  ret
    );
}
