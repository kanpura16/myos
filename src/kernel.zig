const std = @import("std");

const karg = @import("kernel_arg.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");
const memory = @import("memory.zig");
const segment = @import("segment.zig");
const paging = @import("paging.zig");
const pci = @import("pci.zig");
const xhci = @import("driver/usb/xhci/xhci.zig");

var kernel_stack: [1024 * 1024]u8 align(16) = undefined;

export fn kernelEntry(frame_buf_conf: *const karg.FrameBufConf, memory_map: *const karg.MemoryMap) callconv(.SysV) noreturn {
    const stack_end_addr: u64 = @intFromPtr(&kernel_stack) + @sizeOf(@TypeOf(kernel_stack));
    asm volatile (
        \\mov %[stack_end_addr], %rsp
        \\mov %rsp, %rbp
        :
        : [stack_end_addr] "{r8}" (stack_end_addr),
    );

    kernelMain(frame_buf_conf.*, memory_map.*);
}

fn kernelMain(frame_buf_conf: karg.FrameBufConf, memory_map: karg.MemoryMap) noreturn {
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();

    memory.initAllocator(memory_map);
    paging.makeIdentityMaping();
    segment.configureSegment();

    pci.scanAllBuses();
    xhci.runXhci();

    console.print("hlt");
    while (true) asm volatile ("hlt");
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    console.print("\nUndefined behavior is detected: ");
    console.print(msg);
    if (stack_trace != null) {
        console.printf("\ninst addr: 0x{x}", .{stack_trace.?.instruction_addresses});
    }
    if (ret_addr != null) {
        console.printf("\nret addr: 0x{x}", .{ret_addr.?});
    }
    while (true) asm volatile ("hlt");
}
