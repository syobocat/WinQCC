// SPDX-FileCopyrightText: NONE
//
// SPDX-License-Identifier: CC0-1.0

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .os_tag = .windows,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const win32 = b.dependency("zigwin32", .{});
    const known_folders = b.dependency("known_folders", .{});

    const mod = b.addModule("winqcc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "zigwin32", .module = win32.module("win32") },
            .{ .name = "known_folders", .module = known_folders.module("known-folders") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "winqcc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
            .imports = &.{
                .{ .name = "winqcc", .module = mod },
            },
        }),
    });
    exe.subsystem = .Windows;

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
