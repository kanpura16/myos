const std = @import("std");

pub fn build(b: *std.Build) void {
    var optimize: std.builtin.Mode = .ReleaseSafe;
    const is_debug = b.option(bool, "debug", "debug build") orelse false;
    if (is_debug) {
        optimize = .Debug;
    }

    const loader = b.addExecutable(.{
        .name = "bootx64",
        .root_source_file = .{ .path = "src/boot_loader.zig" },
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .uefi,
        }),
        .optimize = optimize,
        .linkage = .static,
        .strip = !is_debug,
    });
    b.installArtifact(loader);

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "src/kernel.zig" },
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .freestanding,
        }),
        .optimize = optimize,
        .linkage = .static,
        .link_libc = false,
        .code_model = .kernel,
        .strip = !is_debug,
    });
    kernel.image_base = 0x100000;
    kernel.entry = .{ .symbol_name = "kernelMain" };
    kernel.link_z_relro = false;
    kernel.is_linking_libc = false;
    kernel.is_linking_libcpp = false;
    b.installArtifact(kernel);
}