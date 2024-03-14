const console = @import("../../../console.zig");
const memory = @import("../../../memory.zig");
const pci = @import("../../../pci.zig");
const context = @import("context.zig");
const ring = @import("ring.zig");
const CapReg = @import("register.zig").CapabilityRegs;
const OpeReg = @import("register.zig").OperationalRegs;

pub fn initXhci() void {
    const xhc: pci.Device = blk: for (pci.devices) |device| {
        const class_code = pci.readClassCode(device.bus, device.device, device.function);
        if (class_code.base == 0x0c and class_code.sub == 0x3 and class_code.interface == 0x30) {
            break :blk device;
        }
    } else {
        console.print("\nError: xhci.initXhci: xHC not found\n");
        while (true) asm volatile ("hlt");
    };

    const mmio_base: u64 = pci.readBar(xhc.bus, xhc.device, xhc.function) & 0xffff_ffff_ffff_fff0;
    const cap_reg: *volatile CapReg = @ptrFromInt(mmio_base);
    const ope_reg: *volatile OpeReg = @ptrFromInt(mmio_base + cap_reg.cap_len);
    const usb_status: *volatile OpeReg.UsbStatusReg = &ope_reg.usb_status;
    const usb_cmd: *volatile OpeReg.UsbCmdReg = &ope_reg.usb_cmd;

    while (usb_status.controller_not_ready == 1) asm volatile ("hlt");

    usb_cmd.run_stop = 0;

    ope_reg.config.max_dev_slots = cap_reg.hcsparams1.max_slots;

    const num_scratchpad_buf = @as(u16, @intCast(cap_reg.hcsparams2.max_scratchpad_bufs_hi)) << 5 | cap_reg.hcsparams2.max_scratchpad_bufs_lo;
    if (num_scratchpad_buf > 0) {
        context.scratchpad_buf_arr = @ptrCast(memory.allocFrame(2));

        for (0..num_scratchpad_buf) |i| {
            context.scratchpad_buf_arr.*[i] = @ptrCast(memory.allocFrame(1));
        }
        context.dev_context_base_addr_arr[0] = @ptrCast(context.scratchpad_buf_arr);
    }
    ope_reg.dev_context_base_addr_arr_ptr = &context.dev_context_base_addr_arr;

    ope_reg.cmd_ring_ctrl.ring_cycle_state = 1;
    ope_reg.cmd_ring_ctrl.cmd_stop = 0;
    ope_reg.cmd_ring_ctrl.cmd_abort = 0;
    ope_reg.cmd_ring_ctrl.cmd_ring_ptr = @intCast(@intFromPtr(&ring.cmd_ring.trb[0]) >> 6);

    usb_cmd.host_controller_reset = 1;
    while (usb_status.controller_not_ready == 1 or usb_cmd.host_controller_reset == 1) asm volatile ("hlt");
}
