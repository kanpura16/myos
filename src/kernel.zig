const std = @import("std");

const boot_info = @import("boot_info.zig");
const console = @import("console.zig");
const graphics = @import("graphics.zig");

export fn kernelMain(frame_buf_conf: *const boot_info.FrameBufConf) noreturn {
    graphics.initGraphics(frame_buf_conf);
    console.clearConsole();

    var numcount: u64 = 0;
    var fcount: u64 = 0;
    var bcount: u64 = 0;
    var fbcount: u64 = 0;
    const start: u64 = 1;
    const end: u64 = 128;
    var i: u64 = start;
    while (i <= end) : (i += 1) {
        if (i % 15 == 0) {
            console.print("FizzBuzz\n");
            fbcount += 1;
        } else if (i % 5 == 0) {
            console.print("Buzz\n");
            bcount += 1;
        } else if (i % 3 == 0) {
            console.print("Fizz\n");
            fcount += 1;
        } else {
            console.printf("{d}\n", .{i});
            numcount += 1;
        }
    }
    console.printf("FizzBuzz {d} ~ {d}\n", .{ start, end });
    console.printf("Number   : {d}\n", .{numcount});
    console.printf("Fizz     : {d}\n", .{fcount});
    console.printf("Buzz     : {d}\n", .{bcount});
    console.printf("FizzBuzz : {d}\n", .{fbcount});

    while (true) {
        asm volatile ("hlt");
    }
}
