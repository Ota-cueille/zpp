const utils = @import("../utils.zig");

const token = @This();

pub const location = struct { offset: u32 = 0, line: u32 = 0, column: u32 = 0 };

pub const kind = enum(u8) { identifier, literal, symbol, eof };
pub const literal = enum(u56) { integer, real, string, character };
pub const symbol = enum(u56) {
    bind = utils.encode("::", 2),
    declare = utils.encode(":=", 2),

    assign = utils.encode("=", 1),
    add_assign = utils.encode("+=", 2),
    sub_assign = utils.encode("-=", 2),
    mul_assign = utils.encode("*=", 2),
    div_assign = utils.encode("/=", 2),
    mod_assign = utils.encode("%=", 2),

    equal = utils.encode("==", 2),
    lt = utils.encode("<", 1),
    lte = utils.encode("<=", 2),
    gt = utils.encode(">", 1),
    gte = utils.encode(">=", 2),

    add = utils.encode("+", 1),
    sub = utils.encode("-", 1),
    mul = utils.encode("*", 1),
    div = utils.encode("/", 1),
    mod = utils.encode("%", 1),

    comma = utils.encode(",", 1),
    colon = utils.encode(":", 1),
    semicolon = utils.encode(";", 1),

    lparenthesis = utils.encode("(", 1),
    rparenthesis = utils.encode(")", 1),
    lbracket = utils.encode("[", 1),
    rbracket = utils.encode("]", 1),
    lbrace = utils.encode("{", 1),
    rbrace = utils.encode("}", 1),

    pub fn is(self: @This(), comptime str: []const u8) bool {
        comptime if (str.len > 7) return false;
        const res: @This() = @enumFromInt(comptime utils.encode(str, str.len));
        return self == res;
    }
};

pub const flags = packed struct(u56) {
    reserved: u56 = 0,
    //     is_compile_time: bool = false,
    //     is_macro_generated: bool = false,
};

kind: kind,
meta: union(enum) {
    none,
    literal: literal,
    symbol: symbol,
    flags: flags,
} = .none,

start: location,
end: location,
content: []const u8,
