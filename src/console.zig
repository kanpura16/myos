const std = @import("std");

const boot_info = @import("boot_info.zig");
const graphics = @import("graphics.zig");

var cursor_x: u32 = 0;
var cursor_y: u32 = 0;

pub fn print(asciis: []const u8) void {
    for (asciis) |ascii| {
        if (ascii == '\n') {
            newLine();
        } else {
            graphics.drawAscii(ascii, cursor_x, cursor_y);
            cursor_x += 8;
        }
    }
}

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    @memset(&buf, 0);
    const asciis = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    print(asciis);
}

pub fn clearConsole() void {
    cursor_x = 0;
    cursor_y = 0;
    graphics.drawQuadrangle(0, 0, boot_info.frame_buf_conf.horizon_res, boot_info.frame_buf_conf.vertical_res, graphics.bg_color);
}

fn newLine() void {
    cursor_x = 0;
    if (cursor_y + 16 * 2 <= boot_info.frame_buf_conf.vertical_res) {
        cursor_y += 16;
    } else {
        // scroll the screen
        const source: [*]u8 = @ptrCast(&boot_info.frame_buf_conf.frame_buf[4 * (boot_info.frame_buf_conf.pixels_per_row * 16)]);
        const len = 4 * (boot_info.frame_buf_conf.pixels_per_row * (boot_info.frame_buf_conf.vertical_res - 16));
        for (boot_info.frame_buf_conf.frame_buf[0..len], source) |*d, s| d.* = s;

        graphics.drawQuadrangle(0, boot_info.frame_buf_conf.vertical_res - 16, boot_info.frame_buf_conf.horizon_res, 16, graphics.bg_color);
    }
}
