const SegmentDescriptor = packed struct {
    limit_low: u16 = 0,
    base_low: u16 = 0,
    base_middle: u8 = 0,
    segment_type: u4,
    desc_type: u1,
    privilege_level: u2,
    present: u1 = 1,
    limit_high: u4 = 0,
    available: u1 = 1,
    long_mode: u1,
    operation_size: u1,
    granularity: u1 = 0,
    base_high: u8 = 0,
};

var gdt: [2]SegmentDescriptor = undefined;

pub fn configureSegment() void {
    // code segment
    gdt[1] = .{
        .segment_type = 10,
        .desc_type = 1,
        .privilege_level = 0,
        .long_mode = 1,
        .operation_size = 0,
    };

    loadGdt(@sizeOf(@TypeOf(gdt)) - 1, @intFromPtr(&gdt));
    changeCodeSegment(1 << 3);
}

extern fn loadGdt(size: u16, addr: u64) void;
extern fn changeCodeSegment(cs: u16) void;

comptime {
    asm (
        \\loadGdt:
        \\  sub $10, %rsp
        \\  mov %di, (%rsp)
        \\  mov %rsi, 2(%rsp)
        \\  lgdt (%rsp)
        \\  add $10, %rsp
        \\  ret
        \\
        \\changeCodeSegment:
        \\  push %rdi
        \\  pushq $next
        \\  lretq
        \\next:
        \\  nop
        \\  ret
    );
}
