const config_addr_reg_addr: u16 = 0xcf8;
const config_data_reg_addr: u16 = 0xcfc;

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

extern fn IOOut32(addr: u16, data: u32) void;
extern fn IOIn32(addr: u16) u32;

fn writeIOAddrSpace(addr: u32, data: u32) void {
    IOOut32(config_addr_reg_addr, addr);
    IOOut32(config_data_reg_addr, data);
}

fn readIOAddrSpace(addr: u32) u32 {
    IOOut32(config_addr_reg_addr, addr);
    return IOIn32(config_data_reg_addr);
}
