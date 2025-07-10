const std = @import("std");

pub fn encode(str: []const u8, comptime bytes: u8) std.meta.Int(.unsigned, bytes * 8) {
    if (str.len > bytes) @panic("Symbol too long for encoding");

    const IntegerType = std.meta.Int(.unsigned, bytes * 8);
    var res: IntegerType = 0;
    inline for (0..bytes) |i| {
        res |= @as(IntegerType, str[i]) << (i * 8);
    }
    return res;
}
