const std = @import("std");

pub fn build(b: *std.Build) void {
    var optimize: std.builtin.Mode = .ReleaseSafe;
    const is_debug = b.option(bool, "debug", "debug build") orelse false;
    if (is_debug) {
        optimize = .Debug;
    }

    const loader = b.addExecutable(.{
        .name = "bootx64",
        .root_source_file = .{ .path = "src/bootloader.zig" },
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .uefi,
            .abi = .msvc,
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
        .code_model = .kernel,
        .strip = !is_debug,
    });
    kernel.image_base = 0x100000;
    kernel.entry = .{ .symbol_name = "kernelEntry" };
    b.installArtifact(kernel);
}
