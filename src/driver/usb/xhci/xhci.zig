const console = @import("../../../console.zig");
const pci = @import("../../../pci.zig");
const context = @import("context.zig");
const register = @import("register.zig");

pub fn initXhci() void {
    var xhc: *pci.Device = undefined;
    for (pci.devices) |device| {
        const class_code = pci.readClassCode(device.bus, device.device, device.function);
        if (class_code.base == 0x0c and class_code.sub == 0x3 and class_code.interface == 0x30) {
            xhc = @constCast(&device);
            break;
        }
    } else {
        console.print("xHC not found\n");
        while (true) asm volatile ("hlt");
    }

    const mmio_base: u64 = pci.readBar(xhc.bus, xhc.device, xhc.function) & 0xffff_ffff_ffff_fff0;
    const cap_reg: *register.CapabilityRegs = @ptrFromInt(mmio_base);
    const operational_reg: *register.OperationalRegs = @ptrFromInt(mmio_base + cap_reg.cap_len);
    const usb_status = &operational_reg.usb_status;
    const usb_cmd = &operational_reg.usb_cmd;

    while (usb_status.controller_not_ready == 1) asm volatile ("hlt");

    if (usb_status.host_controller_halted == 0) {
        usb_cmd.run_stop = 0;
    }

    while (usb_status.host_controller_halted == 0) asm volatile ("hlt");

    operational_reg.config.max_dev_slots = cap_reg.hcsparams1.max_slots;

    const scratchpad_buf_arr: [1024]*context.ScratchpadBufArrElem4kPageSize = undefined;
    _ = scratchpad_buf_arr;
    // TODO: hcsparams2.max scratchpad buf の数だけ scratchpad buf を確保し, scratchpad buf arr の各要素にそのアドレスを設定して dev context base addr arr[0] に scratchpad buf arr のアドレスを設定する

    usb_cmd.host_controller_reset = 1;
    while (usb_cmd.host_controller_reset == 1 or usb_status.controller_not_ready == 1) asm volatile ("hlt");
}
