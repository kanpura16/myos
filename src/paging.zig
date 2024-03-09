var pml4_table: [512]u64 align(4096) = undefined;
var pdp_table: [512]u64 align(4096) = undefined;
var page_dir: [512][512]u64 align(4096) = undefined;

pub fn makeIdentityMaping() void {
    for (&pml4_table) |*pml4| {
        pml4.* = @intFromPtr(&pdp_table[0]) | 0b11;
    }

    for (0..pdp_table.len) |i_pdpt| {
        pdp_table[i_pdpt] = @intFromPtr(&page_dir[i_pdpt]) | 0b11;

        for (0..page_dir[0].len) |i_pd| {
            page_dir[i_pdpt][i_pd] = (1024 * 1024 * 1024) * i_pdpt + (1024 * 1024 * 2) * i_pd | 0b1000_0011;
        }
    }

    setCr3(@intFromPtr(&pml4_table[0]));
}

extern fn setCr3(addr: u64) void;

comptime {
    asm (
        \\setCr3:
        \\  mov %rdi, %cr3
        \\  ret
    );
}
