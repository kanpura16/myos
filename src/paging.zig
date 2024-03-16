const memory = @import("memory.zig");

var pml4_table: [4]u64 align(4096) = undefined;
var pdp_table: [4][512]u64 align(4096) = undefined;
var page_dir: *align(4096) [4][512][512]u64 = undefined;

pub fn makeIdentityMaping() void {
    page_dir = @ptrCast(memory.allocFrame(4 * 512));

    for (0..pml4_table.len) |i_pml4| {
        pml4_table[i_pml4] = @intFromPtr(&pdp_table[i_pml4]) | 0b11;

        for (0..pdp_table[0].len) |i_pdpt| {
            pdp_table[i_pml4][i_pdpt] = @intFromPtr(&page_dir[i_pml4][i_pdpt]) | 0b11;

            for (0..page_dir[0][0].len) |i_pd| {
                page_dir[i_pml4][i_pdpt][i_pd] = (1024 * 1024 * 1024 * 512) * i_pml4 + (1024 * 1024 * 1024) * i_pdpt + (1024 * 1024 * 2) * i_pd | 0b1000_0011;
            }
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
