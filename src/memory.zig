const karg = @import("kernel_arg.zig");
const console = @import("console.zig");

var frame_bitmap: [1024 * 1024 * 1]bool = undefined;

pub fn allocFrame(num_frames: usize) [*]allowzero align(4096) u8 {
    if (num_frames == 0) {
        console.print("\nError: memory.allocFrame: 0 byte allocation request\n");
        while (true) asm volatile ("hlt");
    }

    outer: for (frame_bitmap, 0..) |avail, i_bitmap| {
        if (i_bitmap + num_frames > frame_bitmap.len) {
            console.printf("\nError: memory.allocFrame: {} frames not found\n", .{num_frames});
            while (true) asm volatile ("hlt");
        }

        if (avail == false) continue;

        for (0..num_frames) |i| {
            if (frame_bitmap[i_bitmap + i] == false) continue :outer;
        }

        for (0..num_frames) |j| {
            frame_bitmap[i_bitmap + j] = false;
            const frame: *allowzero [4096]u8 = @ptrFromInt((i_bitmap + j) * 4096);
            @memset(frame, 0);
        }

        return @ptrFromInt(i_bitmap * 4096);
    }

    console.printf("\nError: memory.allocFrame: {} frames not found\n", .{num_frames});
    while (true) asm volatile ("hlt");
}

pub fn freeFrame(frame_addr: [*]allowzero align(4096) u8, num_frames: usize) void {
    for (0..num_frames) |i| {
        frame_bitmap[@intFromPtr(frame_addr) / 4096 + i] = true;
    }
}

pub fn initAllocator(memory_map: karg.MemoryMap) void {
    var i_memmap: usize = @intFromPtr(memory_map.map);
    while (i_memmap < @intFromPtr(memory_map.map) + memory_map.map_size) : (i_memmap += memory_map.desc_size) {
        const desc: *const karg.MemoryDescriptor = @ptrFromInt(i_memmap);
        if (desc.type != .ConventionalMemory and desc.type != .BootServicesCode and desc.type != .BootServicesData) continue;

        for (0..desc.num_pages) |i_page| {
            frame_bitmap[desc.physical_start / 4096 + i_page] = true;
        }
    }
}
