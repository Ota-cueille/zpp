const std = @import("std");

const utils = @import("../utils.zig");
const token = @import("./token.zig");

const lexer = @This();

pub const Elexer = error{
    general,
    unknown_character,
    unterminated_construct,
    malformed_literal,
    unexpected_eof,
    unexpected_character,
};

// Configuration
const LOOKBACK = 2;
const LOOKAHEAD = 4;

// Base Information
source: []const u8,
current_source: []const u8,

// Lexing Context
start: token.location,
end: token.location,

// Token Storage
lookback: [LOOKBACK]token,
current: token,
lookahead: [LOOKAHEAD]token,

// Error Context
error_context: struct {
    at: token.location,
    message: []const u8,
},

pub fn initialize(self: *lexer, source: []const u8) Elexer!void {
    @memset(std.mem.asBytes(self), 0);

    self.source = source;
    self.current_source = self.source;

    for (0..LOOKAHEAD + 1) |_| {
        _ = try self.next();
    }
}

pub fn next(self: *lexer) Elexer!void {
    self.skip_whitespaces_and_comments();

    self.start = self.end;
    if (self.current_source.len == 0) {
        self.shift(self.create(.eof));
        return;
    }

    const lookahead = self.current_source[0];

    switch (lookahead) {
        'a'...'z', 'A'...'Z', '_' => self.identifier(),
        '0'...'9' => self.number(),
        '"' => try self.string(),
        else => self.symbol(),
    }
}

pub fn peek(self: *lexer, offset: i3) token {
    std.debug.assert(-LOOKBACK >= offset and offset <= LOOKAHEAD);
    const slice: []token = @as(*token, @ptrCast(&self.lookback[0]))[0 .. LOOKBACK + 1 + LOOKAHEAD];
    return slice[LOOKBACK + offset];
}

// Internal Implementation
fn create(self: *lexer, kind: token.kind) token {
    return token{
        .kind = kind,
        .start = self.start,
        .end = self.end,
        .content = self.source[self.start.offset..self.end.offset],
    };
}

fn shift(self: *lexer, new: token) void {
    const slice: []token = @as([*]token, @ptrCast(&self.lookback[0]))[0 .. LOOKBACK + 1 + LOOKAHEAD];
    std.mem.copyForwards(token, slice[0..slice.len], slice[1..slice.len]);
    slice[slice.len - 1] = new;
}

fn preview(self: *const lexer, str: []const u8) bool {
    const until = @min(self.current_source.len, str.len);
    return std.mem.eql(u8, str, self.current_source[0..until]);
}

fn advance(self: *lexer) void {
    std.debug.assert(self.current_source.len != 0);

    if (self.current_source[0] == '\n') {
        self.end.column = 0;
        self.end.line += 1;
    } else {
        self.end.column += 1;
    }

    self.end.offset += 1;
    self.current_source = self.current_source[1..];
}

fn consume(self: *lexer, comptime character: u8) void {
    std.debug.assert(self.current_source.len != 0 and self.current_source[0] == character);
    self.advance();
}

fn consume_if(self: *lexer, condition: fn (u8) bool) bool {
    if (self.current_source.len != 0 and condition(self.current_source[0])) {
        self.advance();
        return true;
    } else {
        return false;
    }
}

fn is_not_newline(c: u8) bool {
    return c != '\n' and c != std.ascii.control_code.vt;
}

fn skip_whitespaces_and_comments(self: *lexer) void {
    var previous_len = self.current_source.len;

    while (true) {
        while (self.consume_if(std.ascii.isWhitespace)) {}

        while (self.preview("//") or self.preview("/*")) {
            self.consume('/');

            switch (self.current_source[0]) {
                // one line comment
                '/' => while (self.consume_if(is_not_newline)) {},

                // multiline_comment
                '*' => {
                    while (self.current_source.len != 0 and !self.preview("*/")) : (self.advance()) {}
                    self.consume('*');
                    self.consume('/');
                },

                else => unreachable,
            }
        }

        if (previous_len == self.current_source.len) break;
        previous_len = self.current_source.len;
    }
}

fn is_character_valid_identifier(character: u8) bool {
    return switch (character) {
        'A'...'Z', 'a'...'z', '_' => true,
        else => false,
    };
}

fn identifier(self: *lexer) void {
    while (self.consume_if(is_character_valid_identifier) or self.consume_if(std.ascii.isDigit)) {}
    self.shift(self.create(.identifier));
}

fn number(self: *lexer) void {
    while (self.consume_if(std.ascii.isDigit)) {}

    // it may be an integer or a floating point literal
    if (self.current_source[0] != '.') {
        var integer = self.create(.literal);
        integer.meta = .{ .literal = .integer };
        self.shift(integer);
        return;
    }

    self.consume('.');

    while (self.consume_if(std.ascii.isDigit)) {}

    var real = self.create(.literal);
    real.meta = .{ .literal = .real };
    self.shift(real);
}

fn is_newline(character: u8) bool {
    return switch (character) {
        '\n', std.ascii.control_code.vt => true,
        else => false,
    };
}

fn string(self: *lexer) Elexer!void {
    self.consume('"');

    var is_escaped = false;
    while (self.current_source[0] != '"' or is_escaped) {
        if (self.current_source.len == 0) {
            self.error_context.at = self.end;
            self.error_context.message = "unexpected EOF inside string literal";
            return Elexer.unexpected_eof;
        } else if (is_newline(self.current_source[0])) {
            self.error_context.at = self.end;
            self.error_context.message = "unexpected '\\n' or '\\v' inside string literal";
            return Elexer.unexpected_character;
        }

        is_escaped = self.current_source[0] == '\\';
        self.advance();
    }

    self.consume('"');

    var tok = self.create(.literal);
    tok.meta = .{ .literal = .string };
    self.shift(tok);
}

fn create_symbol(self: *lexer, comptime symbol_character_count: u3) token {
    std.debug.assert(self.current_source.len >= symbol_character_count);

    inline for (0..symbol_character_count) |_| self.advance();

    var tok = self.create(.symbol);
    tok.meta = .{ .symbol = @enumFromInt(utils.encode(tok.content, symbol_character_count)) };

    return tok;
}

fn symbol(self: *lexer) void {
    const tok = switch (self.current_source[0]) {
        // one character
        ',', ';', '(', ')', '[', ']', '{', '}' => self.create_symbol(1),

        // optionally two characters
        ':' => if (self.preview("::") or self.preview(":=")) self.create_symbol(2) else self.create_symbol(1),
        '=' => if (self.preview("==")) self.create_symbol(2) else self.create_symbol(1),

        // logicals
        '>' => if (self.preview(">=")) self.create_symbol(2) else self.create_symbol(1),
        '<' => if (self.preview("<=")) self.create_symbol(2) else self.create_symbol(1),

        // arithmetics
        '+' => if (self.preview("+=")) self.create_symbol(2) else self.create_symbol(1),
        '-' => if (self.preview("-=")) self.create_symbol(2) else self.create_symbol(1),
        '*' => if (self.preview("*=")) self.create_symbol(2) else self.create_symbol(1),
        '/' => if (self.preview("/=")) self.create_symbol(2) else self.create_symbol(1),
        '%' => if (self.preview("%=")) self.create_symbol(2) else self.create_symbol(1),

        else => unreachable,
    };

    self.shift(tok);
}
