const utils = @import("../utils.zig");

const token = @This();

pub const location = struct { offset: u32 = 0, line: u32 = 0, column: u32 = 0 };

// add more kinds as needed
kind: enum(u8) { identifier, literal, symbol, eof },

meta: union(enum) {
    none,

    literal: enum(u56) { integer, real, string, character },

    symbol: enum(u56) {
        double_colon = utils.encode("::"),
        equal_equal = utils.encode("=="),
        arrow = utils.encode("->"),
        plus = utils.encode("+"),
        minus = utils.encode("-"),
        // add more symbols as needed

        pub fn is(self: @This(), comptime str: []const u8) bool {
            const res: @This() = comptime @enumFromInt(utils.encode(str));
            return self == res;
        }
    },

    flags: packed struct(u56) {
        reserved: u56 = 0,
        //     is_compile_time: bool = false,
        //     is_macro_generated: bool = false,
    },
} = .none,

start: location,
end: location,
content: []const u8,
