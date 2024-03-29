const std = @import("std");

const karg = @import("kernel_arg.zig");
const font = @import("font.zig");
const graphics = @import("graphics.zig");

var cursor_x: u32 = 0;
var cursor_y: u32 = 0;

pub fn clearConsole() void {
    cursor_x = 0;
    cursor_y = 0;
    graphics.drawQuadrangle(0, 0, karg.frame_buf_conf.horizon_res, karg.frame_buf_conf.vertical_res, graphics.Color.bg_color);
}

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [2048]u8 = undefined;
    const asciis = std.fmt.bufPrint(&buf, fmt, args) catch "\nError: console.printf: BufPrintError\n";
    print(asciis);
}

pub fn print(asciis: []const u8) void {
    for (asciis) |ascii| {
        if (ascii == '\n') {
            newLine();
        } else if (ascii == '\t') {
            print("    ");
        } else if (cursor_x + font.char_width > karg.frame_buf_conf.horizon_res) {
            newLine();
            graphics.drawAscii(ascii, cursor_x, cursor_y);
            cursor_x += font.char_width;
        } else {
            graphics.drawAscii(ascii, cursor_x, cursor_y);
            cursor_x += font.char_width;
        }
    }
}

fn newLine() void {
    cursor_x = 0;
    const is_last_line = cursor_y + font.char_height * 2 > karg.frame_buf_conf.vertical_res;
    if (is_last_line) {
        scroll();
    } else {
        cursor_y += font.char_height;
    }
}

fn scroll() void {
    @setRuntimeSafety(false);
    var y: u32 = 0;
    while (y < karg.frame_buf_conf.vertical_res - font.char_height) : (y += font.char_height) {
        @memcpy(graphics.calcPixelAddr(0, y), graphics.calcPixelAddr(0, y + font.char_height)[0 .. karg.frame_buf_conf.pixels_per_row * font.char_height * 4]);
    }

    graphics.drawQuadrangle(0, karg.frame_buf_conf.vertical_res - font.char_height, karg.frame_buf_conf.horizon_res, font.char_height, graphics.Color.bg_color);
}
