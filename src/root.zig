// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

pub const save = @import("save.zig").save;
pub const load = @import("load.zig").load;
pub const msgBox = @import("win32.zig").msgBox;
pub const msgBoxAlloc = @import("win32.zig").msgBoxAlloc;
