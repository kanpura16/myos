pub var frame_buf_conf: FrameBufConf = undefined;

pub const FrameBufConf = struct {
    frame_buf: [*]volatile u8,
    horizon_res: u32,
    vertical_res: u32,
    pixels_per_row: u32,
    pixel_format: PixelFormat,
};

const PixelFormat = enum {
    RGB8BitPerColor,
    BGR8BitPerColor,
};