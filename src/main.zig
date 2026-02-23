// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

const std = @import("std");
const winqcc = @import("winqcc");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.skip();
    if (args.next()) |id| {
        winqcc.load(allocator, id) catch |err| switch (err) {
            // TODO: エラーハンドリングもうちょっとがんばる
            error.OutOfMemory => _ = winqcc.msgBox(.{ .ICONHAND = 1 }, "メモリ不足です。"),
            inline else => |e| _ = try winqcc.msgBoxAlloc(
                allocator,
                .{ .ICONHAND = 1, .ICONQUESTION = 1 },
                try std.fmt.allocPrint(allocator, "Error: {}", .{e}),
            ),
        };
    } else {
        winqcc.save(allocator) catch |err| switch (err) {
            // TODO: エラーハンドリングもうちょっとがんばる
            error.OutOfMemory => _ = winqcc.msgBox(.{ .ICONHAND = 1 }, "メモリ不足です。"),
            inline else => |e| _ = try winqcc.msgBoxAlloc(
                allocator,
                .{ .ICONHAND = 1, .ICONQUESTION = 1 },
                try std.fmt.allocPrint(allocator, "Error: {}", .{e}),
            ),
        };
    }
}
