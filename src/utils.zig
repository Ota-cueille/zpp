pub fn encode(comptime str: []const u8) u16 {
    if (str.len > 2) @compileError("Symbol too long for u16 encoding");

    return switch (str.len) {
        1 => @as(u16, str[0]),
        2 => (@as(u16, str[0]) << 8) | @as(u16, str[1]),
        else => unreachable,
    };
}
