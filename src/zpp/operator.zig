const std = @import("std");
const token = @import("token.zig");

const utils = @import("../utils.zig");

const code = enum(u24) {
    // access operators
    @"." = utils.convert(u16, "."),

    // math operators
    @"+" = utils.convert(u16, "+"),
    @"-" = utils.convert(u16, "-"),
    @"*" = utils.convert(u16, "*"),
    @"/" = utils.convert(u16, "/"),
    @"%" = utils.convert(u16, "%"),

    // binary operators
    @"|" = utils.convert(u16, "|"),
    @"&" = utils.convert(u16, "&"),

    // logic operators
    @"or" = utils.convert(u16, "or"),
    @"and" = utils.convert(u24, "and"),
    not = utils.convert(u24, "not"),

    // memory operators
    @"=" = utils.convert(u16, "="),
    @"+=" = utils.convert(u16, "+="),
    @"-=" = utils.convert(u16, "-="),
    @"*=" = utils.convert(u16, "*="),
    @"/=" = utils.convert(u16, "/="),
};

pub fn from_slice(tok: []const u8) ?code {
    if (tok.len > 3) return null;

    const token_val = utils.convert(u14, tok);

    const infos = @typeInfo(code).Enum;
    inline for (infos.fields) |field| {
        if (field.value == token_val) return @enumFromInt(field);
    }

    return null;
}
