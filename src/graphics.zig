const boot_info = @import("boot_info.zig");
const font = @import("font.zig");

const Color = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub const fg_color = Color{ .red = 0x9E, .green = 0xCE, .blue = 0x6A };
pub const bg_color = Color{ .red = 16, .green = 16, .blue = 16 };

var drawPixel: *const fn (u32, u32, Color) void = undefined;

pub fn initGraphics(frame_buf_conf: *const boot_info.FrameBufConf) void {
    boot_info.frame_buf_conf = frame_buf_conf;
    drawPixel = if (frame_buf_conf.pixel_format == .RGB8BitPerColor) &drawRGBPixel else &drawBGRPixel;
}

pub fn drawAsciis(asciis: []const u8, x: u32, y: u32) void {
    for (asciis, 0..) |ascii, i| {
        drawAscii(ascii, @intCast(x + i * font.char_width), y);
    }
}

pub fn drawAscii(ascii: u8, x: u32, y: u32) void {
    const font_data = font.getFontFromAscii(ascii);
    var py: u8 = 0;
    while (py < 16) : (py += 1) {
        var px: u8 = 0;
        while (px < 8) : (px += 1) {
            if ((font_data[py] << @intCast(px)) >= 0b1000_0000) {
                drawPixel(x + px * 2, y + py * 2, fg_color);
                drawPixel(x + px * 2 + 1, y + py * 2, fg_color);

                drawPixel(x + px * 2, y + py * 2 + 1, fg_color);
                drawPixel(x + px * 2 + 1, y + py * 2 + 1, fg_color);
            }
        }
    }
}

pub fn drawQuadrangle(x: u32, y: u32, size_x: u32, size_y: u32, color: Color) void {
    var py: u32 = 0;
    while (py < size_y) : (py += 1) {
        var px: u32 = 0;
        while (px < size_x) : (px += 1) {
            drawPixel(x + px, y + py, color);
        }
    }
}

pub fn drawColorfulBG() void {
    var y: u32 = 0;
    while (y < boot_info.frame_buf_conf.vertical_res) : (y += 1) {
        var x: u32 = 0;
        while (x < boot_info.frame_buf_conf.horizon_res) : (x += 1) {
            drawPixel(x, y, .{
                .red = @intCast(y * 3 % 256),
                .green = @intCast((x + y) % 256),
                .blue = @intCast(x * 3 % 256),
            });
        }
    }
}

pub fn calcPixelAddr(x: u32, y: u32) [*]u8 {
    return @ptrCast(&boot_info.frame_buf_conf.frame_buf[(boot_info.frame_buf_conf.pixels_per_row * y + x) * 4]);
}

fn drawRGBPixel(x: u32, y: u32, color: Color) void {
    var p: [*]u8 = calcPixelAddr(x, y);
    p[0] = color.red;
    p[1] = color.green;
    p[2] = color.blue;
}

fn drawBGRPixel(x: u32, y: u32, color: Color) void {
    var p: [*]u8 = calcPixelAddr(x, y);
    p[0] = color.blue;
    p[1] = color.green;
    p[2] = color.red;
}
