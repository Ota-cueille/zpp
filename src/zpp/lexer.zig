const std = @import("std");

const utils = @import("../utils.zig");
const token = @import("token.zig");

const lexer = @This();

// Base Information
source: []const u8,
cursor: u64,

// Lexing Context
start: token.location,
end: token.location,

pub fn initialize(source: []const u8) lexer {
    var self: lexer = undefined;
    @memset(std.mem.asBytes(&self), 0);

    self.source = source;
    self.cursor = 0;

    self.start.line = 1;
    self.start.column = 1;
    self.end.line = 1;
    self.end.column = 1;

    return self;
}

pub fn next(self: *lexer) token {
    self.skip_whitespaces_and_comments();

    self.start = self.end;
    if (self.cursor == self.source.len) return self.create(.eof);

    const lookahead = self.source[self.cursor];

    return switch (lookahead) {
        'a'...'z', 'A'...'Z', '_' => self.identifier_or_keyword_or_literal(),
        '0'...'9' => self.number(),
        '"' => self.string(),
        '#' => self.directive(.lexer),
        '@' => self.directive(.parser),
        else => self.symbol(),
    };
}

// Internal Implementation
fn create(self: *lexer, kind: token.kind) token {
    return token{
        .k = kind,
        .start = self.start,
        .end = self.end,
        .content = self.source[self.start.offset..self.end.offset],
    };
}

fn check(self: *const lexer, character: u8) bool {
    return self.cursor != self.source.len and self.source[self.cursor] == character;
}

fn preview(self: *const lexer, str: []const u8) bool {
    const until = @min(str.len, self.source.len - self.cursor);
    return std.mem.eql(u8, str, self.source[self.cursor .. self.cursor + until]);
}

fn advance(self: *lexer) void {
    std.debug.assert(self.cursor != self.source.len);

    if (self.source[self.cursor] == '\n') {
        self.end.column = 1;
        self.end.line += 1;
    } else {
        self.end.column += 1;
    }

    self.end.offset += 1;
    self.cursor += 1;
}

fn consume(self: *lexer, comptime character: u8) void {
    std.debug.assert(self.check(character));
    self.advance();
}

fn consume_if(self: *lexer, condition: fn (u8) bool) bool {
    if (self.cursor != self.source.len and condition(self.source[self.cursor])) {
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
    var previous_len = self.source.len - self.cursor;

    while (true) {
        while (self.consume_if(std.ascii.isWhitespace)) {}

        while (self.preview("//") or self.preview("/*")) {
            self.consume('/');

            switch (self.source[self.cursor]) {
                // one line comment
                '/' => while (self.consume_if(is_not_newline)) {},

                // multiline_comment
                '*' => {
                    while (self.cursor != self.source.len and !self.preview("*/")) : (self.advance()) {}
                    self.consume('*');
                    self.consume('/');
                },

                else => unreachable,
            }
        }

        if (previous_len == self.source.len - self.cursor) break;
        previous_len = self.source.len - self.cursor;
    }
}

fn is_character_valid_identifier(character: u8) bool {
    return switch (character) {
        'A'...'Z', 'a'...'z', '_' => true,
        else => false,
    };
}

fn identifier_or_keyword_or_literal(self: *lexer) token {
    while (self.consume_if(is_character_valid_identifier) or self.consume_if(std.ascii.isDigit)) {}

    var tok = self.create(.identifier);

    if (token.keyword.table.get(tok.content)) |kw| {
        tok.k = .keyword;
        tok.meta = .{ .keyword = kw };
    } else if (token.literal.check_boolean_literal(tok.content)) {
        tok.k = .literal;
        tok.meta = .{ .literal = .boolean };
    }

    return tok;
}

fn number(self: *lexer) token {
    while (self.consume_if(std.ascii.isDigit)) {}

    // it may be an integer or a floating point literal
    if (!self.check('.')) {
        var integer = self.create(.literal);
        integer.meta = .{ .literal = .integer };
        return integer;
    }

    self.consume('.');

    while (self.consume_if(std.ascii.isDigit)) {}

    var real = self.create(.literal);
    real.meta = .{ .literal = .real };
    return real;
}

fn is_newline(character: u8) bool {
    return switch (character) {
        '\n', std.ascii.control_code.vt => true,
        else => false,
    };
}

fn string(self: *lexer) token {
    self.consume('"');

    var is_escaped = false;
    while (!self.check('"') or is_escaped) {
        if (self.cursor == self.source.len or is_newline(self.source[self.cursor])) {
            var tok = self.create(.err);
            tok.meta.ecode = .unterminated_string;
            return tok;
        }

        is_escaped = self.source[self.cursor] == '\\';
        self.advance();
    }

    self.consume('"');

    var tok = self.create(.literal);
    tok.meta = .{ .literal = .string };
    return tok;
}

fn directive(self: *lexer, comptime kind: enum { lexer, parser }) token {
    self.consume(if (kind == .lexer) '#' else '@'); // consume '#' or '@'

    // todo(ota): create enum for lexer, parser and compiler directives to assure that directives are only the ones suported by the compiler
    while (self.consume_if(is_character_valid_identifier) or self.consume_if(std.ascii.isDigit)) {}

    var tok = self.create(.directive);
    tok.meta = .{ .directive = .{ .target = if (kind == .lexer) .lexer else .parser } };
    return tok;
}

fn create_symbol(self: *lexer, comptime symbol_character_count: u3) token {
    std.debug.assert(self.source.len - self.cursor >= symbol_character_count);

    inline for (0..symbol_character_count) |_| self.advance();

    var tok = self.create(.symbol);
    tok.meta = .{ .symbol = @enumFromInt(utils.encode(tok.content, symbol_character_count)) };

    return tok;
}

fn symbol(self: *lexer) token {
    return switch (self.source[self.cursor]) {
        // one character
        ',', ';', '(', ')', '[', ']', '{', '}' => self.create_symbol(1),

        // optionally two characters
        '.' => if (self.preview(".(")) self.create_symbol(2) else self.create_symbol(1),
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

        else => err: {
            var tok = self.create(.err);
            tok.meta.ecode = .unknown_symbol;
            self.advance();

            break :err tok;
        },
    };
}
