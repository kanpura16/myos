const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const segment = @import("segment.zig");
const pci = @import("pci.zig");
const xhci = @import("driver/usb/xhci/xhci.zig");

var kernel_stack: [1024 * 1024]u8 align(16) = undefined;

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    const stack_end_addr: u64 = @intFromPtr(&kernel_stack) + @sizeOf(@TypeOf(kernel_stack));
    changeStack(stack_end_addr);

    segment.initSegment();
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();
    pci.scanAllBuses();
    xhci.initXhci();

    while (true) asm volatile ("hlt");
}

extern fn changeStack(u64) void;

comptime {
    asm (
        \\changeStack:
        \\  mov (%rsp), %rax
        \\  mov %rdi, %rsp
        \\  mov %rsp, %rbp
        \\  push %rax
        \\  ret
    );
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    console.print(msg);
    if (stack_trace != null) {
        console.printf("\ninst addr: 0x{x}", .{stack_trace.?.instruction_addresses});
    }
    if (ret_addr != null) {
        console.printf("\nret addr: 0x{x}", .{ret_addr.?});
    }
    while (true) asm volatile ("hlt");
}
