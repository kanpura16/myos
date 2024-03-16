const console = @import("../../../console.zig");
const memory = @import("../../../memory.zig");
const pci = @import("../../../pci.zig");
const reg = @import("register.zig");
const context = @import("context.zig");
const ring = @import("ring.zig");
const trb = @import("trb.zig");

pub fn initXhci() void {
    const xhc: pci.Device = blk: for (pci.devices) |device| {
        const class_code = pci.readClassCode(device.bus, device.device, device.function);
        if (class_code.base == 0x0c and class_code.sub == 0x03 and class_code.interface == 0x30) {
            break :blk device;
        }
    } else {
        console.print("\nError: xhci.initXhci: xHC not found\n");
        while (true) asm volatile ("hlt");
    };

    const mmio_base: u64 = pci.readBar(xhc.bus, xhc.device, xhc.function) & 0xffff_ffff_ffff_fff0;
    const cap_reg: *volatile reg.CapabilityReg = @ptrFromInt(mmio_base);
    const ope_reg: *volatile reg.OperationalReg = @ptrFromInt(mmio_base + cap_reg.cap_len);
    const runtime_reg: *volatile reg.RuntimeReg = @ptrFromInt(mmio_base + cap_reg.runtime_reg_off);
    const usb_status: *volatile reg.OperationalReg.UsbStatusReg = &ope_reg.usb_status;
    const usb_cmd: *volatile reg.OperationalReg.UsbCmdReg = &ope_reg.usb_cmd;

    while (usb_status.controller_not_ready == 1) asm volatile ("hlt");

    usb_cmd.run_stop = 0;
    while (usb_status.host_controller_halted == 0) asm volatile ("hlt");

    usb_cmd.host_controller_reset = 1;
    while (usb_cmd.host_controller_reset == 1 or usb_status.controller_not_ready == 1) asm volatile ("hlt");

    ope_reg.config.max_dev_slots = cap_reg.hcsparams1.max_slots;

    const num_scratchpad_buf = @as(u16, @intCast(cap_reg.hcsparams2.max_scratchpad_bufs_hi)) << 5 | cap_reg.hcsparams2.max_scratchpad_bufs_lo;
    if (num_scratchpad_buf > 0) {
        context.scratchpad_buf_arr = @ptrCast(memory.allocFrame(2));

        for (0..num_scratchpad_buf) |i| {
            context.scratchpad_buf_arr.*[i] = @ptrCast(memory.allocFrame(1));
        }
        context.dev_context_base_addr_arr[0] = @ptrCast(context.scratchpad_buf_arr);
    }
    ope_reg.dev_context_base_addr_arr_ptr = @intCast(@intFromPtr(&context.dev_context_base_addr_arr) >> 6);

    ope_reg.cmd_ring_ctrl.ring_cycle_state = 1;
    ope_reg.cmd_ring_ctrl.cmd_stop = 0;
    ope_reg.cmd_ring_ctrl.cmd_abort = 0;
    ope_reg.cmd_ring_ctrl.cmd_ring_ptr = @intCast(@intFromPtr(&ring.cmd_ring.trbs[0]) >> 6);

    ring.event_ring_segment_table = .{
        .{
            .ring_segment_ptr = @intCast(@intFromPtr(&ring.prim_event_ring.trbs[0]) >> 6),
            .ring_segment_size = ring.prim_event_ring.trbs.len,
        },
    };

    ring.prim_event_ring.int_reg_dequeue_ptr = @ptrCast(&runtime_reg.interrupt_reg_set1.event_ring_dequeue_ptr);
    runtime_reg.interrupt_reg_set1.event_ring_segment_table_size = ring.event_ring_segment_table.len;
    runtime_reg.interrupt_reg_set1.event_ring_dequeue_ptr = @intCast(@intFromPtr(&ring.prim_event_ring.trbs[0]) >> 4);
    runtime_reg.interrupt_reg_set1.event_ring_segment_table_ptr = @intCast(@intFromPtr(&ring.event_ring_segment_table) >> 6);

    usb_cmd.run_stop = 1;
    while (usb_status.host_controller_halted == 1) asm volatile ("hlt");
}
