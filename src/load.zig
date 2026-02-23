// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

const std = @import("std");

const win32 = @import("win32.zig");

const Config = @import("config.zig");

pub fn load(allocator: std.mem.Allocator, id: []const u8) !void {
    const app_dir = try std.fs.getAppDataDir(allocator, "WinQCC");
    const cursor_dir = try std.fs.path.join(allocator, &[_][]const u8{ app_dir, id });
    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ cursor_dir, "config.zon" });

    const file = try std.fs.openFileAbsolute(config_path, .{});

    const config_str = try file.readToEndAllocOptions(allocator, 1024, null, .@"8", 0);
    // TODO: Zig 0.16では:
    // var reader = file.reader(&.{});
    // const config_str = try reader.interface.allocRemainingAlignedSentinel(allocator, .unlimited, .@"8", 0);

    const config = try std.zon.parse.fromSlice(Config, allocator, config_str, null, .{});

    try win32.updateRegistry(allocator, cursor_dir, config);
    try win32.reloadCursor();
}
