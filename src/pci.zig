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
};

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
