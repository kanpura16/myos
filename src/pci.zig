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

const IOPortAddr = packed struct {
    enable: u1 = 1,
    _reservation1: u7 = 0,
    bus: u8,
    device: u5,
    function: u3,
    reg_offset: u6,
    _reservation2: u2 = 0,

    pub fn toInt(self: @This()) u32 {
        return @as(u32, @intCast(self.enable)) << 31 | @as(u32, @intCast(self.bus)) << 16 | @as(u32, @intCast(self.device)) << 11 | @as(u32, @intCast(self.function)) << 8 | @as(u32, @intCast(self.reg_offset)) << 2;
    }
};

const config_addr_reg_addr: u16 = 0xcf8;
const config_data_reg_addr: u16 = 0xcfc;

pub fn readVendorID(addr: IOPortAddr) u16 {
    return @intCast(readIOAddrSpace(addr) & 0xffff);
}

fn writeIOAddrSpace(addr: IOPortAddr, data: u32) void {
    IOOut32(config_addr_reg_addr, addr.toInt());
    IOOut32(config_data_reg_addr, data);
}

fn readIOAddrSpace(addr: IOPortAddr) u32 {
    IOOut32(config_addr_reg_addr, addr.toInt());
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
