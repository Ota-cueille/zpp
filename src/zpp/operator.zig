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

    // comparison operators
    @"==" = utils.convert(u16, "=="),
    @"!=" = utils.convert(u16, "!="),
    @"<" = utils.convert(u16, "<"),
    @"<=" = utils.convert(u16, "<="),
    @">" = utils.convert(u16, ">"),
    @">=" = utils.convert(u16, ">="),

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

pub fn precedence(op: code, comptime unary: bool) u64 {
    return switch (op) {
        // low precedence
        .@"=" => 0,
        .@"+=" => 0,
        .@"-=" => 0,
        .@"*=" => 0,
        .@"/=" => 0,

        .@"or" => 1,
        .@"and" => 1,

        .@"==" => 2,
        .@"!=" => 2,

        .@"<" => 3,
        .@"<=" => 3,
        .@">" => 3,
        .@">=" => 3,

        .@"|" => 4,
        .@"+" => if (unary) 8 else 4, // WTF unary operators
        .@"-" => if (unary) 8 else 5, // WTF unary operators

        .@"&" => 6,
        .@"*" => 6,
        .@"/" => 7,
        .@"%" => 7,

        .not => if (unary) 8 else unreachable, // WTF unary operators
        .@"." => 10,
    };
}

pub fn from_slice(tok: []const u8) ?code {
    if (tok.len > 3) return null;

    const token_val = utils.convert(u14, tok);

    const infos = @typeInfo(code).Enum;
    inline for (infos.fields) |field| {
        if (field.value == token_val) return @enumFromInt(field.value);
    }

    return null;
}

pub fn is_unary(tok: []const u8) bool {
    const op_code = from_slice(tok) orelse return false;
    const prec = precedence(op_code, true);
    return prec == 8;
}
