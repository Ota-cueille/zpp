const std = @import("std");
const token = @import("token.zig");

fn u16_from_u8_slice(slice: []const u8) u16 {
    // max operator size is currently 2
    std.debug.assert(slice.len <= 2);
    var result: u16 = 0;
    for (slice, 0..) |byte, offset| {
        result |= (@as(u16, @intCast(byte)) << @truncate(offset * 8));
    }
    return result;
}

fn code_from_u8_slice(slice: []const u8) code {
    const result = u16_from_u8_slice(slice);
    return @enumFromInt(result);
}

pub const code = enum(u16) {
    add = u16_from_u8_slice("+"),
    subtract = u16_from_u8_slice("-"),
    divide = u16_from_u8_slice("/"),
    multiply = u16_from_u8_slice("*"),

    equal = u16_from_u8_slice("=="),
    different = u16_from_u8_slice("!="),
    greater_equal = u16_from_u8_slice(">="),
    less_equal = u16_from_u8_slice("<="),

    greater = u16_from_u8_slice(">"),
    less = u16_from_u8_slice("<"),
};

pub fn get_precedence(op: token) u64 {
    std.debug.assert(op.kind == .symbol);

    const c = code_from_u8_slice(op.content);

    return switch (c) {
        .add => 2,
        .subtract => 3,
        .multiply => 4,
        .divide => 5,

        .equal => 1,
        .different => 1,
        .greater_equal => 1,
        .less_equal => 1,

        .greater => 1,
        .less => 1,
    };
}

pub fn exists(slice: []const u8) bool {
    if (slice.len > 2) return false;

    const value = u16_from_u8_slice(slice);
    inline for (@typeInfo(code).Enum.fields) |field| {
        if (field.value == value) return true;
    }

    return false;
}

test code_from_u8_slice {
    const s1 = "!=";
    const expected1: u16 = ('!' << 0) | ('=' << 1);
    std.testing.expectEqual(expected1, code_from_u8_slice(s1));

    const s2 = '+';
    const expected2: u16 = '+';
    std.testing.expectEqual(expected2, code_from_u8_slice(s2));

    const s3 = "==";
    const expected3: u16 = ('=' << 0) | ('=' << 1);
    std.testing.expectEqual(expected3, code_from_u8_slice(s3));
}
