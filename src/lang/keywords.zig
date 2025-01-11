const enum_table = @import("../utils/enum_table.zig").enum_table;

usingnamespace keywords;

pub const keywords = enum {
    @"if",
    @"else",
    @"switch",

    @"break",
    @"return",

    @"struct",
    @"enum",

    @"for",
    @"while",

    true,
    false,

    pub const table = enum_table(@This());
};
