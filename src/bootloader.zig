const std = @import("std");
const elf = std.elf;
const uefi = std.os.uefi;

const boot_info = @import("boot_info.zig");

var con_out: *uefi.protocol.SimpleTextOutput = undefined;

pub fn main() uefi.Status {
    const bs = uefi.system_table.boot_services orelse return .Unsupported;
    var status: uefi.Status = undefined;

    con_out = uefi.system_table.con_out orelse return .Unsupported;
    status = con_out.clearScreen();
    if (status != .Success) {
        printf("failed to clear screen: {}\r\n", .{status});
        return status;
    }

    // read kernel file
    var loaded_image: *uefi.protocol.LoadedImage = undefined;
    status = bs.handleProtocol(uefi.handle, &uefi.protocol.LoadedImage.guid, @ptrCast(&loaded_image));
    if (status != .Success) {
        printf("failed to get loaded image protocol: {}", .{status});
        return status;
    }

    var fs: *uefi.protocol.SimpleFileSystem = undefined;
    const device_handle = loaded_image.device_handle orelse return .Unsupported;
    status = bs.handleProtocol(device_handle, &uefi.protocol.SimpleFileSystem.guid, @ptrCast(&fs));
    if (status != .Success) {
        printf("failed to get simple file system protocol: {}\r\n", .{status});
        return .Unsupported;
    }

    var root_dir: *uefi.protocol.File = undefined;
    status = fs.openVolume(&root_dir);
    if (status != .Success) {
        printf("failed to open root directory: {}\r\n", .{status});
        return status;
    }

    var kernel_file: *uefi.protocol.File = undefined;
    status = root_dir.open(
        &kernel_file,
        &[_:0]u16{ 'k', 'e', 'r', 'n', 'e', 'l', '.', 'e', 'l', 'f' },
        uefi.protocol.File.efi_file_mode_read,
        uefi.protocol.File.efi_file_read_only,
    );
    if (status != .Success) {
        printf("failed to open kernel file: {}\r\n", .{status});
        return status;
    }

    // read elf header
    var elf_header_size: usize = @sizeOf(elf.Ehdr);
    var elf_header_buf: [*]align(8) u8 = undefined;
    status = bs.allocatePool(.LoaderData, elf_header_size, &elf_header_buf);
    if (status != .Success) {
        printf("failed to allocate memory for kernel file header: {}\r\n", .{status});
        return status;
    }

    status = kernel_file.read(&elf_header_size, elf_header_buf);
    if (status != .Success) {
        printf("failed to read kernel file header: {}\r\n", .{status});
        return status;
    }

    const elf_header = elf.Header.parse(elf_header_buf[0..@sizeOf(elf.Ehdr)]) catch |err| {
        printf("failed to parse kernel file header: {}\r\n", .{err});
        return .LoadError;
    };

    status = bs.freePool(elf_header_buf);
    if (status != .Success) {
        printf("failed to free memory for kernel file header: {}\r\n", .{status});
        return status;
    }

    // allocate pages to load kernel
    var iter = elf_header.program_header_iterator(kernel_file);
    var kernel_first_addr: usize = std.math.maxInt(u64);
    var kernel_last_addr: usize = 0;
    while (iter.next() catch |err| {
        printf("failed to iterate program header: {}\r\n", .{err});
        return .LoadError;
    }) |program_header| {
        if (program_header.p_type != elf.PT_LOAD) continue;

        if (program_header.p_vaddr < kernel_first_addr) {
            kernel_first_addr = program_header.p_vaddr;
        }
        if (program_header.p_vaddr + program_header.p_memsz > kernel_last_addr) {
            kernel_last_addr = program_header.p_vaddr + program_header.p_memsz;
        }
    }

    const num_pages = (kernel_last_addr - kernel_first_addr + 4095) / 4096;
    status = bs.allocatePages(.AllocateAddress, .LoaderData, num_pages, @as(*[*]align(4096) u8, @ptrCast(&kernel_first_addr)));
    // status = bs.allocatePages(.AllocateAddress, .LoaderData, num_pages, @ptrCast(&kernel_first_addr));
    if (status != .Success) {
        printf("failed to allocate pages for kernel: {}\r\n", .{status});
        return status;
    }

    // load kernel to memory
    iter = elf_header.program_header_iterator(kernel_file);
    while (iter.next() catch |err| {
        printf("failed to iterate program header: {}\r\n", .{err});
        return .LoadError;
    }) |program_header| {
        if (program_header.p_type != elf.PT_LOAD) continue;

        status = kernel_file.setPosition(program_header.p_offset);
        if (status != .Success) {
            printf("failed to set kernel file read position: {}\r\n", .{status});
            return status;
        }
        status = kernel_file.read(@constCast(&program_header.p_filesz), @ptrFromInt(program_header.p_vaddr));
        if (status != .Success) {
            printf("failed to load kernel to memory: {}\r\n", .{status});
            return status;
        }

        // initialize .bss section with 0
        const zero_fill_count = program_header.p_memsz - program_header.p_filesz;
        if (zero_fill_count > 0) {
            bs.setMem(@ptrFromInt(program_header.p_vaddr + program_header.p_filesz), zero_fill_count, 0);
        }
    }

    status = kernel_file.close();
    if (status != .Success) {
        printf("failed to close kernel file: {}\r\n", .{status});
        return status;
    }
    status = root_dir.close();
    if (status != .Success) {
        printf("failed to close root directory: {}\r\n", .{status});
        return status;
    }

    var gop: *uefi.protocol.GraphicsOutput = undefined;
    status = bs.locateProtocol(&uefi.protocol.GraphicsOutput.guid, null, @ptrCast(&gop));
    if (status != .Success) {
        printf("failed to get graphics output protocol: {}\r\n", .{status});
        return status;
    }

    const frame_buf_conf = boot_info.FrameBufConf{
        .frame_buf = @ptrFromInt(gop.mode.frame_buffer_base),
        .pixels_per_row = gop.mode.info.pixels_per_scan_line,
        .horizon_res = gop.mode.info.horizontal_resolution,
        .vertical_res = gop.mode.info.vertical_resolution,
        .pixel_format = switch (gop.mode.info.pixel_format) {
            .RedGreenBlueReserved8BitPerColor => .RGB8BitPerColor,
            .BlueGreenRedReserved8BitPerColor => .BGR8BitPerColor,
            else => {
                return .Unsupported;
            },
        },
    };

    // exit boot service
    var map_size: usize = undefined;
    const descriptors: ?[*]uefi.tables.MemoryDescriptor = undefined;
    var map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;
    status = bs.getMemoryMap(&map_size, descriptors, &map_key, &descriptor_size, &descriptor_version);
    if (status != .Success) {
        printf("failed to get memory map: {}\r\n", .{status});
        return status;
    }

    status = bs.exitBootServices(uefi.handle, map_key);
    if (status != .Success) {
        printf("failed to exit boot services: {}\r\n", .{status});
        return status;
    }

    const kernelMain: *const fn (*const boot_info.FrameBufConf) callconv(.SysV) noreturn = @ptrFromInt(elf_header.entry);
    kernelMain(&frame_buf_conf);

    return .LoadError;
}

fn printf(comptime format: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    @memset(&buf, 0);
    const asciis = std.fmt.bufPrint(&buf, format, args) catch unreachable;
    for (asciis) |ascii| {
        con_out.outputString(&[_:0]u16{ ascii, 0 }).err() catch unreachable;
    }
}
