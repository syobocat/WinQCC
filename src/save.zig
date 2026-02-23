// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

const std = @import("std");
const known_folders = @import("known_folders");

const win32 = @import("win32.zig");
const uid = @import("uid.zig");

const Config = @import("config.zig");

// Helper
fn copy(allocator: std.mem.Allocator, cursor_dir: []const u8, src: ?[]const u8) !?[]const u8 {
    if (src) |f| {
        const name = std.fs.path.basename(f);
        const dst = try std.fs.path.join(allocator, &[_][]const u8{ cursor_dir, name });
        try std.fs.copyFileAbsolute(f, dst, .{});
        return name;
    } else {
        return null;
    }
}

pub fn save(allocator: std.mem.Allocator) !void {
    // パスを準備しておく
    const desktop = try known_folders.getPath(allocator, .desktop) orelse return error.DesktopNotFound;
    const app_dir = try std.fs.getAppDataDir(allocator, "WinQCC");
    std.fs.makeDirAbsolute(app_dir) catch |e| if (e != error.PathAlreadyExists) return e;

    var path_buffer: [1024]u8 = undefined;
    const exe_path = try std.fs.selfExePath(&path_buffer);

    // カーソルファイルのパスをもらう
    const src_arrow = try win32.openFile(allocator, "「通常の選択」(Arrow)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_help = try win32.openFile(allocator, "「ヘルプの選択」(Help)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_appstarting = try win32.openFile(allocator, "「バックグラウンドで作業中」(AppStarting)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_wait = try win32.openFile(allocator, "「待ち状態」(Wait)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_crosshair = try win32.openFile(allocator, "「領域選択」(Crosshair)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_ibeam = try win32.openFile(allocator, "「テキスト選択」(IBeam)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_nwpen = try win32.openFile(allocator, "「手書き」(NWPen)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_no = try win32.openFile(allocator, "「利用不可」(No)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_sizens = try win32.openFile(allocator, "「上下に拡大/縮小」(SizeNS)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_sizewe = try win32.openFile(allocator, "「左右に拡大/縮小」(SizeWE)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_sizenwse = try win32.openFile(allocator, "「斜めに拡大/縮小 1」(SizeNWSE)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_sizenesw = try win32.openFile(allocator, "「斜めに拡大/縮小 2」(SizeNESW)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_sizeall = try win32.openFile(allocator, "「移動」(SizeAll)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_uparrow = try win32.openFile(allocator, "「代替選択」(UpArrow)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");
    const src_hand = try win32.openFile(allocator, "「リンクの選択」(Hand)のカーソルを選択してください。存在しない場合、キャンセルを押してください。");

    // コンフィグの生成
    const id = &uid.generateID();

    const cursor_dir = try std.fs.path.join(allocator, &[_][]const u8{ app_dir, id });
    try std.fs.makeDirAbsolute(cursor_dir);

    var config: Config = undefined;
    config.arrow = try copy(allocator, cursor_dir, src_arrow);
    config.help = try copy(allocator, cursor_dir, src_help);
    config.appstarting = try copy(allocator, cursor_dir, src_appstarting);
    config.wait = try copy(allocator, cursor_dir, src_wait);
    config.crosshair = try copy(allocator, cursor_dir, src_crosshair);
    config.ibeam = try copy(allocator, cursor_dir, src_ibeam);
    config.nwpen = try copy(allocator, cursor_dir, src_nwpen);
    config.no = try copy(allocator, cursor_dir, src_no);
    config.sizens = try copy(allocator, cursor_dir, src_sizens);
    config.sizewe = try copy(allocator, cursor_dir, src_sizewe);
    config.sizenwse = try copy(allocator, cursor_dir, src_sizenwse);
    config.sizenesw = try copy(allocator, cursor_dir, src_sizenesw);
    config.sizeall = try copy(allocator, cursor_dir, src_sizeall);
    config.uparrow = try copy(allocator, cursor_dir, src_uparrow);
    config.hand = try copy(allocator, cursor_dir, src_hand);

    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ cursor_dir, "config.zon" });
    const config_file = try std.fs.createFileAbsolute(config_path, .{});
    var writer_buf: [1024]u8 = undefined;
    var write = config_file.writer(&writer_buf);
    const writer = &write.interface;

    try std.zon.stringify.serialize(config, .{}, writer);
    try writer.flush();

    // ショートカットの作成
    const shortcut_name = try std.fmt.allocPrint(allocator, "カーソル変更_{s}.lnk", .{id});
    const shortcut_path = try std.fs.path.join(allocator, &[_][]const u8{ desktop, shortcut_name });

    try win32.createLink(allocator, exe_path, id, shortcut_path);

    // 通知
    _ = win32.msgBox(.{}, "デスクトップにショートカットを作成しました。");
}
