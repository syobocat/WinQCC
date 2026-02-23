// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

const std = @import("std");
const win32 = @import("zigwin32");
const reg = win32.system.registry;
const com = win32.system.com;
const shell = win32.ui.shell;
const dialog = win32.ui.controls.dialogs;
const messaging = win32.ui.windows_and_messaging;

const Config = @import("config.zig");

const toWide = std.unicode.utf8ToUtf16LeStringLiteral;
const toWideAlloc = std.unicode.utf8ToUtf16LeAllocZ;
const toUtf8Alloc = std.unicode.utf16LeToUtf8AllocZ;

pub fn createLink(allocator: std.mem.Allocator, exe_path: []const u8, arg: []const u8, save_path: []const u8) !void {
    var shell_link: *shell.IShellLinkW = undefined;
    defer _ = shell_link.IUnknown.Release();
    const create_res = com.CoCreateInstance(
        shell.CLSID_ShellLink,
        null,
        com.CLSCTX_INPROC_SERVER,
        shell.IID_IShellLinkW,
        @ptrCast(&shell_link),
    );
    if (create_res != 0) {
        return error.ShellLinkCreationError;
    }

    const set_path_res = shell_link.SetPath(try toWideAlloc(allocator, exe_path));
    if (set_path_res != 0) {
        return error.SetPathError;
    }

    const set_arg_res = shell_link.SetArguments(try toWideAlloc(allocator, arg));
    if (set_arg_res != 0) {
        return error.SetArgError;
    }

    var persist_file: *com.IPersistFile = undefined;
    defer _ = persist_file.IUnknown.Release();
    const file_res = shell_link.IUnknown.QueryInterface(com.IID_IPersistFile, @ptrCast(&persist_file));
    if (file_res != 0) {
        return error.PersistFileCreationError;
    }

    const save_res = persist_file.Save(try toWideAlloc(allocator, save_path), 0);
    if (save_res != 0) {
        return error.SaveError;
    }
}

pub fn msgBox(style: messaging.MESSAGEBOX_STYLE, comptime text: []const u8) messaging.MESSAGEBOX_RESULT {
    return messaging.MessageBoxW(null, toWide(text), toWide("WinQCC"), style);
}

pub fn msgBoxAlloc(allocator: std.mem.Allocator, style: messaging.MESSAGEBOX_STYLE, text: []const u8) !messaging.MESSAGEBOX_RESULT {
    return messaging.MessageBoxW(null, try toWideAlloc(allocator, text), toWide("WinQCC"), style);
}

pub fn openFile(allocator: std.mem.Allocator, comptime title: []const u8) !?[]const u8 {
    var buffer = std.mem.zeroes([1024]u16);
    const ptr: [*:0]u16 = @ptrCast(&buffer);
    var openfilename: dialog.OPENFILENAMEW = .{
        .lStructSize = @sizeOf(dialog.OPENFILENAMEW),
        .hwndOwner = null,
        .hInstance = null,
        .lpstrFilter = toWide("カーソルファイル (*.cur; *.ani)\x00*.CUR;*.ANI\x00"),
        .lpstrCustomFilter = null,
        .nMaxCustFilter = 0,
        .nFilterIndex = 0,
        .lpstrFile = ptr,
        .nMaxFile = 1024,
        .lpstrFileTitle = null,
        .nMaxFileTitle = 0,
        .lpstrInitialDir = null,
        .lpstrTitle = toWide(title),
        .Flags = .{ .FILEMUSTEXIST = 1 },
        .nFileOffset = 0,
        .nFileExtension = 0,
        .lpstrDefExt = null,
        .lCustData = 0,
        .lpfnHook = null,
        .lpTemplateName = null,
        .pvReserved = null,
        .dwReserved = 0,
        .FlagsEx = .{},
    };
    const ret = dialog.GetOpenFileNameW(&openfilename);
    if (ret == 0) {
        const err = dialog.CommDlgExtendedError();
        if (err == .CDERR_GENERALCODES) {
            // ユーザーがダイアログを閉じた
            return null;
        } else {
            return error.DialogError;
        }
    } else {
        return try toUtf8Alloc(allocator, std.mem.span(ptr));
    }
}

// Helper
fn setCursor(
    allocator: std.mem.Allocator,
    hkey: ?reg.HKEY,
    cursor_dir: []const u8,
    comptime name: []const u8,
    filename: ?[]const u8,
) !void {
    const err = if (filename) |n| some: {
        const path = try std.fs.path.join(allocator, &[_][]const u8{ cursor_dir, n });
        const path_utf16 = try toWideAlloc(allocator, path);
        break :some reg.RegSetValueExW(hkey, toWide(name), 0, reg.REG_SZ, @ptrCast(path_utf16), @intCast(path_utf16.len * 2));
    } else reg.RegSetValueExW(hkey, toWide(name), 0, reg.REG_SZ, @ptrCast(toWide("")), 2);

    if (err != .NO_ERROR) {
        return error.RegistryWriteError;
    }
}

pub fn updateRegistry(allocator: std.mem.Allocator, cursor_dir: []const u8, config: Config) !void {
    var key: ?reg.HKEY = undefined;

    const reg_open_res = reg.RegOpenKeyExW(reg.HKEY_CURRENT_USER, toWide("Control Panel\\Cursors"), 0, reg.KEY_WRITE, &key);
    if (reg_open_res != .NO_ERROR) {
        return error.RegistryOpenError;
    }

    const set_name_res = reg.RegSetValueExW(key, toWide(""), 0, reg.REG_SZ, @ptrCast(toWide("WinQCC")), 14);
    if (set_name_res != .NO_ERROR) {
        return error.RegistryWriteError;
    }

    const set_scheme_res = reg.RegSetValueExW(key, toWide("Scheme Source"), 0, reg.REG_DWORD, &1, 4);
    if (set_scheme_res != .NO_ERROR) {
        return error.RegistryWriteError;
    }

    try setCursor(allocator, key, cursor_dir, "arrow", config.arrow);
    try setCursor(allocator, key, cursor_dir, "help", config.help);
    try setCursor(allocator, key, cursor_dir, "appstarting", config.appstarting);
    try setCursor(allocator, key, cursor_dir, "wait", config.wait);
    try setCursor(allocator, key, cursor_dir, "crosshair", config.crosshair);
    try setCursor(allocator, key, cursor_dir, "ibeam", config.ibeam);
    try setCursor(allocator, key, cursor_dir, "nwpen", config.nwpen);
    try setCursor(allocator, key, cursor_dir, "no", config.no);
    try setCursor(allocator, key, cursor_dir, "sizens", config.sizens);
    try setCursor(allocator, key, cursor_dir, "sizewe", config.sizewe);
    try setCursor(allocator, key, cursor_dir, "sizenwse", config.sizenwse);
    try setCursor(allocator, key, cursor_dir, "sizenesw", config.sizenesw);
    try setCursor(allocator, key, cursor_dir, "sizeall", config.sizeall);
    try setCursor(allocator, key, cursor_dir, "uparrow", config.uparrow);
    try setCursor(allocator, key, cursor_dir, "hand", config.hand);

    const reg_close_res = reg.RegCloseKey(key);
    if (reg_close_res != .NO_ERROR) {
        return error.RegistryCloseError;
    }
}

pub fn reloadCursor() !void {
    const res = messaging.SystemParametersInfoW(messaging.SPI_SETCURSORS, 0, null, .{ .UPDATEINIFILE = 1, .SENDCHANGE = 1 });
    if (res != 0) {
        return error.ReloadCursorError;
    }
}
