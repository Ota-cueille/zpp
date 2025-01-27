const utils = @import("../utils.zig");

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

    pub const table = utils.enum_table(@This());
};
