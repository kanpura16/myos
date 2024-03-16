const karg = @import("kernel_arg.zig");
const font = @import("font.zig");

pub const Color = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub const fg_color = .{ .red = 0x9E, .green = 0xCE, .blue = 0x6A };
    pub const bg_color = .{ .red = 16, .green = 16, .blue = 16 };
};

pub fn drawAsciis(asciis: []const u8, x: u32, y: u32) void {
    for (asciis, 0..) |ascii, i| {
        drawAscii(ascii, @intCast(x + i * font.char_width), y);
    }
}

pub fn drawAscii(ascii: u8, x: u32, y: u32) void {
    const font_data = font.getFontFromAscii(ascii);
    for (0..16) |font_y| {
        for (0..8) |font_x| {
            const bit: bool = (font_data[font_y] << @intCast(font_x)) >= 0b1000_0000;
            if (bit) {
                drawPixel(@intCast(x + font_x * 2), @intCast(y + font_y * 2), Color.fg_color);
                drawPixel(@intCast(x + font_x * 2 + 1), @intCast(y + font_y * 2), Color.fg_color);

                drawPixel(@intCast(x + font_x * 2), @intCast(y + font_y * 2 + 1), Color.fg_color);
                drawPixel(@intCast(x + font_x * 2 + 1), @intCast(y + font_y * 2 + 1), Color.fg_color);
            }
        }
    }
}

pub fn drawQuadrangle(x: u32, y: u32, size_x: u32, size_y: u32, color: Color) void {
    for (0..size_y) |py| {
        for (0..size_x) |px| {
            drawPixel(@intCast(x + px), @intCast(y + py), color);
        }
    }
}

pub fn drawColorfulBG() void {
    for (0..karg.frame_buf_conf.vertical_res) |y| {
        for (0..karg.frame_buf_conf.horizon_res) |x| {
            drawPixel(x, y, .{
                .red = @intCast(y * 3 % 256),
                .green = @intCast((x + y) % 256),
                .blue = @intCast(x * 3 % 256),
            });
        }
    }
}

pub inline fn calcPixelAddr(x: u32, y: u32) [*]volatile u8 {
    return @ptrCast(&karg.frame_buf_conf.frame_buf[(karg.frame_buf_conf.pixels_per_row * y + x) * 4]);
}

pub fn initGraphics(frame_buf_conf: karg.FrameBufConf) void {
    karg.frame_buf_conf = frame_buf_conf;
    drawPixel = if (frame_buf_conf.pixel_format == .RGB8BitPerColor) &drawRGBPixel else &drawBGRPixel;
}

var drawPixel: *const fn (u32, u32, Color) void = undefined;

fn drawRGBPixel(x: u32, y: u32, color: Color) void {
    var p: [*]volatile u8 = calcPixelAddr(x, y);
    p[0] = color.red;
    p[1] = color.green;
    p[2] = color.blue;
}

fn drawBGRPixel(x: u32, y: u32, color: Color) void {
    var p: [*]volatile u8 = calcPixelAddr(x, y);
    p[0] = color.blue;
    p[1] = color.green;
    p[2] = color.red;
}
