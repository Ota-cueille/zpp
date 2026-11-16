const utils = @import("../utils.zig");

const token = @This();

pub const location = struct { offset: u32 = 0, line: u32 = 0, column: u32 = 0 };

pub const kind = enum(u8) { identifier, keyword, literal, symbol, directive, err, eof };

pub const keyword = enum(u56) {
    // operators
    @"and" = utils.encode("and", 3),
    @"or" = utils.encode("or", 2),
    xor = utils.encode("xor", 3),

    // control flow
    @"if" = utils.encode("if", 2),
    @"else" = utils.encode("else", 4),

    @"for" = utils.encode("for", 3),

    @"break" = utils.encode("break", 5),
    @"return" = utils.encode("return", 6),
    // @"continue" = utils.encode("continue", 8),

    // types
    @"struct" = utils.encode("struct", 6),
    @"enum" = utils.encode("enum", 4),
    @"union" = utils.encode("union", 5),

    pub const table = utils.enumhash(@This());

    pub fn is(self: *const @This(), comptime str: []const u8) bool {
        comptime if (str.len > 6) return false;
        const res: @This() = @enumFromInt(comptime utils.encode(str, str.len));
        return self.* == res;
    }
};

const std = @import("std");

pub const literal = enum(u56) {
    integer,
    real,
    boolean,
    string,
    character,

    pub fn check_boolean_literal(identifier: []const u8) bool {
        return std.mem.eql(u8, identifier, "true") or std.mem.eql(u8, identifier, "false");
    }
};

pub const symbol = enum(u56) {
    bind = utils.encode("::", 2),
    declare = utils.encode(":=", 2),
    cast = utils.encode(".(", 2),

    resolve = utils.encode(".", 1),

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

    pub fn is(self: *const @This(), comptime str: []const u8) bool {
        comptime if (str.len > 2) return false;
        const res: @This() = @enumFromInt(comptime utils.encode(str, str.len));
        return self.* == res;
    }
};

pub const directive = struct {
    target: enum(u56) { lexer, parser, compiler },
};

pub const flags = packed struct(u56) {
    reserved: u56 = 0,
    // is_compile_time: bool = false,
    // is_macro_generated: bool = false,
};

pub const ecode = enum(u56) {
    unknown_symbol,
    unterminated_string,
};

k: kind,
meta: union(enum) {
    none,
    keyword: keyword,
    literal: literal,
    symbol: symbol,
    directive: directive,
    flags: flags,
    ecode: ecode,
} = .none,

start: location,
end: location,
content: []const u8,

pub fn is_unary_operator(self: *const token) bool {
    return self.k == .symbol and (self.meta.symbol.is("+") or self.meta.symbol.is("-"));
}

pub fn is_binary_operator(self: *const token) bool {
    return ((self.k == .symbol and (self.meta.symbol.is("-") or // subtraction operator
        self.meta.symbol.is("+") or // addition operator
        self.meta.symbol.is("/") or // division operator
        self.meta.symbol.is("*") or // multiplication operator
        self.meta.symbol.is("%") or // modulus operator
        self.meta.symbol.is("==") or // boolean operator (equal)
        self.meta.symbol.is("<") or // boolean operator (less than)
        self.meta.symbol.is("<=") or // boolean operator (less than or equal)
        self.meta.symbol.is(">") or // boolean operator (greater than)
        self.meta.symbol.is(">=") or // boolean operator (greater than or equal)
        self.meta.symbol.is(".") or // access resolution operator
        self.meta.symbol.is(".(") or // cast operator
        self.meta.symbol.is(":=") or // declaration
        self.meta.symbol.is("::") or // binding
        self.meta.symbol.is("=") // assignment
    )) or
        (self.k == .keyword and (self.meta.keyword.is("and") or // boolean operator (logical and)
            self.meta.keyword.is("or") or // boolean operator (logical or)
            self.meta.keyword.is("xor") // boolean operator (logical exclusive or)
        )));
}

// higher means more priority
pub fn get_binary_operator_precedence(operator: *const token) u8 {
    if (operator.k == .keyword) {
        const kw = operator.meta.keyword;
        if (kw.is("or") or kw.is("xor")) return 10;
        if (kw.is("and")) return 20;
    }
    if (operator.k == .symbol) {
        const sym = operator.meta.symbol;
        if (sym.is("::") or sym.is(":=")) return 1;
        if (sym.is("=") or sym.is("+=") or sym.is("-=") or sym.is("*=") or sym.is("/=") or sym.is("%=")) return 2;
        if (sym.is("==") or sym.is(">=") or sym.is("<=") or sym.is(">") or sym.is("<")) return 30;
        if (sym.is("+") or sym.is("-")) return 40;
        if (sym.is("*") or sym.is("/") or sym.is("%")) return 50;
        if (sym.is(".")) return 60;
    }
    return 0;
}
