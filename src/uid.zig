// SPDX-FileCopyrightText: 2026 SyoBoN <syobon@syobon.net>
//
// SPDX-License-Identifier: UPL-1.0

const std = @import("std");

pub fn generateID() [16]u8 {
    const timestamp = std.time.timestamp();

    var rng: std.Random.DefaultPrng = .init(@bitCast(timestamp));
    const rand = rng.random();

    const id = rand.int(u64);
    return std.fmt.hex(id);
}
