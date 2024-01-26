const std = @import("std");

const boot_info = @import("boot_info.zig");
const font = @import("font.zig");
const graphics = @import("graphics.zig");

var cursor_x: u32 = 0;
var cursor_y: u32 = 0;

pub fn clearConsole() void {
    cursor_x = 0;
    cursor_y = 0;
    graphics.drawQuadrangle(0, 0, boot_info.frame_buf_conf.horizon_res, boot_info.frame_buf_conf.vertical_res, graphics.bg_color);
}

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    @memset(&buf, 0);
    const asciis = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    print(asciis);
}

pub fn print(asciis: []const u8) void {
    for (asciis) |ascii| {
        if (ascii == '\n') {
            newLine();
        } else if (ascii == '\t') {
            print("    ");
        } else if (cursor_x + font.char_width > boot_info.frame_buf_conf.horizon_res) {
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
    if (cursor_y + font.char_height * 2 <= boot_info.frame_buf_conf.vertical_res) {
        cursor_y += font.char_height;
    } else {
        // scroll the screen
        var y: u32 = 0;
        while (y < boot_info.frame_buf_conf.vertical_res - font.char_height) : (y += 1) {
            var x: u32 = 0;
            while (x < boot_info.frame_buf_conf.horizon_res) : (x += 1) {
                @memcpy(graphics.calcPixelAddr(x, y)[0..3], graphics.calcPixelAddr(x, y + font.char_height)[0..3]);
            }
        }

        graphics.drawQuadrangle(0, boot_info.frame_buf_conf.vertical_res - font.char_height, boot_info.frame_buf_conf.horizon_res, font.char_height, graphics.bg_color);
    }
}
