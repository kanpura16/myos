const std = @import("std");
const uefi = std.os.uefi;

const boot_info = @import("boot_info.zig");
const elf = @import("elf.zig");

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

    var loaded_image: *uefi.protocol.LoadedImage = undefined;
    status = bs.handleProtocol(uefi.handle, &uefi.protocol.LoadedImage.guid, @ptrCast(&loaded_image));
    if (status != .Success) {
        printf("failed to get loaded image protocol: {}", .{status});
        return status;
    }

    const device_handle = loaded_image.device_handle orelse return .Unsupported;
    var fs: *uefi.protocol.SimpleFileSystem = undefined;
    status = bs.handleProtocol(device_handle, &uefi.protocol.SimpleFileSystem.guid, @ptrCast(&fs));
    if (status != .Success) {
        printf("failed to get simple file system protocol: {}\r\n", .{status});
        return .Unsupported;
    }

    var root_dir: *const uefi.protocol.File = undefined;
    status = fs.openVolume(&root_dir);
    if (status != .Success) {
        printf("failed to open root directory: {}\r\n", .{status});
        return status;
    }

    var kernel_file: *const uefi.protocol.File = undefined;
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

    const ehdr_size: usize = @sizeOf(elf.Elf64Hdr);
    var ehdr_buf: [ehdr_size]u8 align(8) = undefined;
    status = kernel_file.read(@constCast(&ehdr_size), &ehdr_buf);
    if (status != .Success) {
        printf("failed to read elf header: {}\r\n", .{status});
        return status;
    }
    const ehdr: *const elf.Elf64Hdr = @ptrCast(&ehdr_buf);

    var kernel_first_addr: u64 = std.math.maxInt(u64);
    var kernel_last_addr: u64 = 0;
    var i: u16 = 0;
    while (i < ehdr.e_phnum) : (i += 1) {
        const phdr_size: usize = @sizeOf(elf.Elf64Phdr);

        status = kernel_file.setPosition(ehdr.e_phoff + phdr_size * i);
        if (status != .Success) {
            printf("failed to set kernel file read position: {}\r\n", .{status});
            return status;
        }

        var phdr_buf: [phdr_size]u8 align(8) = undefined;
        status = kernel_file.read(@constCast(&phdr_size), &phdr_buf);
        if (status != .Success) {
            printf("failed to read program header: {}\r\n", .{status});
            return status;
        }
        const phdr: *const elf.Elf64Phdr = @ptrCast(&phdr_buf);

        if (phdr.p_type != .PT_LOAD) continue;

        kernel_first_addr = @min(kernel_first_addr, phdr.p_paddr);
        kernel_last_addr = @max(kernel_last_addr, phdr.p_paddr + phdr.p_memsz);
    }

    const num_pages = (kernel_last_addr - kernel_first_addr) / 0x1000 + 1;
    status = bs.allocatePages(.AllocateAddress, .LoaderData, num_pages, @ptrCast(&kernel_first_addr));
    if (status != .Success) {
        printf("failed to allocate pages for kernel: {}\r\n", .{status});
        return status;
    }

    i = 0;
    while (i < ehdr.e_phnum) : (i += 1) {
        const phdr_size: usize = @sizeOf(elf.Elf64Phdr);

        status = kernel_file.setPosition(ehdr.e_phoff + phdr_size * i);
        if (status != .Success) {
            printf("failed to set kernel file read position: {}\r\n", .{status});
            return status;
        }

        var phdr_buf: [phdr_size]u8 align(8) = undefined;
        status = kernel_file.read(@constCast(&phdr_size), &phdr_buf);
        if (status != .Success) {
            printf("failed to read program header: {}\r\n", .{status});
            return status;
        }
        const phdr: *const elf.Elf64Phdr = @ptrCast(&phdr_buf);

        if (phdr.p_type != .PT_LOAD) continue;

        status = kernel_file.setPosition(phdr.p_offset);
        if (status != .Success) {
            printf("failed to set kernel file read position: {}\r\n", .{status});
            return status;
        }
        status = kernel_file.read(@constCast(&phdr.p_filesz), @ptrFromInt(phdr.p_paddr));
        if (status != .Success) {
            printf("failed to load kernel to memory: {}\r\n", .{status});
            return status;
        }

        // initialize bss section with 0
        const zero_fill_count = phdr.p_memsz - phdr.p_filesz;
        if (zero_fill_count > 0) {
            bs.setMem(@ptrFromInt(phdr.p_paddr + phdr.p_filesz), zero_fill_count, 0);
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

    var gop: ?*uefi.protocol.GraphicsOutput = undefined;
    status = bs.locateProtocol(&uefi.protocol.GraphicsOutput.guid, null, @ptrCast(&gop));
    if (status != .Success) {
        printf("failed to get graphics output protocol: {}\r\n", .{status});
        return status;
    }

    const frame_buf_conf: *const boot_info.FrameBufConf = &boot_info.FrameBufConf{
        .frame_buf = @ptrFromInt(gop.?.mode.frame_buffer_base),
        .pixels_per_row = gop.?.mode.info.pixels_per_scan_line,
        .horizon_res = gop.?.mode.info.horizontal_resolution,
        .vertical_res = gop.?.mode.info.vertical_resolution,
        .pixel_format = switch (gop.?.mode.info.pixel_format) {
            .RedGreenBlueReserved8BitPerColor => .RGB8BitPerColor,
            .BlueGreenRedReserved8BitPerColor => .BGR8BitPerColor,
            else => |pixel_format| {
                printf("unsupported pixel format: {}", .{pixel_format});
                return .Unsupported;
            },
        },
    };

    // exit boot service
    comptime var memmap_buf_size: usize = 4096 * 4;
    var memmap_buf: [memmap_buf_size]u8 align(8) = undefined;
    var map_key: usize = 0;
    var descriptor_size: usize = 0;
    var descriptor_version: u32 = 0;
    status = bs.getMemoryMap(&memmap_buf_size, @ptrCast(&memmap_buf), &map_key, &descriptor_size, &descriptor_version);
    if (status != .Success) {
        printf("failed to get memory map: {}\r\n", .{status});
        return status;
    }

    status = bs.exitBootServices(uefi.handle, map_key);
    if (status != .Success) {
        printf("failed to exit boot services: {}\r\n", .{status});
        return status;
    }

    const kernelMain: *const fn (*const boot_info.FrameBufConf) callconv(.SysV) noreturn = @ptrFromInt(ehdr.e_entry);
    kernelMain(frame_buf_conf);

    return .LoadError;
}

fn printf(comptime format: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const asciis = std.fmt.bufPrint(&buf, format, args) catch unreachable;
    for (asciis) |ascii| {
        con_out.outputString(&[_:0]u16{@intCast(ascii)}).err() catch unreachable;
    }
}
