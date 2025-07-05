const std = @import("std");

pub const token = @import("token.zig");

const lexer = @This();

source: []const u8,
current_source: []const u8,

previous_location: token.location,
current_location: token.location,

current_token: token,

pub fn initialize(source: []const u8) lexer {
    var self: lexer = undefined;

    self.source = source;
    self.current_source = source;

    self.current_location = .{ .offset = 0, .column = 0, .line = 0 };
    self.previous_location = .{ .offset = 0, .column = 0, .line = 0 };

    _ = self.next();

    return self;
}

pub fn peek(self: *const lexer) token {
    return self.current_token;
}

pub fn next(self: *lexer) token {
    self.skip_whitespaces();
    self.skip_comments();

    const previous_token = self.current_token;
    self.previous_location = self.current_location;

    if (self.current_source.len == 0) {
        self.current_token = self.eof();
        return previous_token;
    }

    self.current_token = switch (self.current_source[0]) {
        // try to read an identifier
        'a'...'z', 'A'...'Z', '_' => self.identifier(),

        // try to read an integer
        '0'...'9' => self.integer(),

        // simple single symbols
        '(', ')', '{', '}', ',' => self.single_character_symbol(),

        // can scan for:  [ ':', '::' ]
        ':' => self.one_followup_symbol(&[_]u8{':'}),

        else => {
            std.log.err("unrecognized character: {} '{c}'", .{ self.current_source[0], self.current_source[0] });
            std.log.err("on line and column: {} {}\n", .{ self.current_location.line, self.current_location.column });
            unreachable;
        },
    };

    return previous_token;
}

fn skip_whitespaces(self: *lexer) void {
    while (self.consume_if(std.ascii.isWhitespace)) {}
}

fn is_not_newline(c: u8) bool {
    return c != '\n' and c != std.ascii.control_code.vt;
}

fn skip_comments(self: *lexer) void {
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

        self.skip_whitespaces();
    }
}

fn preview(self: *lexer, string: []const u8) bool {
    const until = @min(self.current_source.len, string.len);
    return std.mem.eql(u8, self.current_source[0..until], string);
}

fn check(self: *lexer, c: u8) bool {
    return self.current_source.len != 0 and self.current_source[0] == c;
}

fn check_if(self: *lexer, condition: fn (u8) bool) bool {
    return self.current_source.len != 0 and condition(self.current_source[0]);
}

fn advance(self: *lexer) void {
    std.debug.assert(self.current_source.len != 0);

    if (self.current_source[0] == '\n') {
        self.current_location.column = 0;
        self.current_location.line += 1;
    } else {
        self.current_location.column += 1;
    }

    self.current_location.offset += 1;
    self.current_source = self.current_source[1..];
}

fn consume_if(self: *lexer, condition: fn (u8) bool) bool {
    if (self.current_source.len != 0 and condition(self.current_source[0])) {
        self.advance();
        return true;
    } else {
        return false;
    }
}

fn consume_equal(self: *lexer, c: u8) bool {
    if (self.current_source.len != 0 and self.current_source[0] == c) {
        self.advance();
        return true;
    } else {
        return false;
    }
}

fn consume(self: *lexer, char: u8) void {
    std.debug.assert(self.current_source.len != 0 and self.current_source[0] == char);
    self.advance();
}

fn generate(self: *lexer, kind: token.kind) token {
    return token.create(self.source[self.previous_location.offset..self.current_location.offset], kind, self.previous_location, self.current_location);
}

/// Implementation detail
fn is_character_valid_identifier(c: u8) bool {
    return switch (c) {
        '_', 'a'...'z', 'A'...'Z' => true,
        else => false,
    };
}

fn identifier(self: *lexer) token {
    // first character of identifier cannot be a number
    const success = self.consume_if(is_character_valid_identifier);
    std.debug.assert(success);

    while (self.consume_if(is_character_valid_identifier) or self.consume_if(std.ascii.isDigit)) {}

    return self.generate(.identifier);
}

fn single_character_symbol(self: *lexer) token {
    std.debug.assert(self.current_source.len != 0);
    self.advance();
    return self.generate(.symbol);
}

fn one_followup_symbol(self: *lexer, comptime possibilities: []const u8) token {
    std.debug.assert(self.current_source.len != 0);

    // consume the first symbol
    self.advance();

    inline for (possibilities) |followup| if (self.consume_equal(followup)) break;

    return self.generate(.symbol);
}

fn eof(_: *lexer) token {
    return token.create("", .eof, .{}, .{});
}

fn integer(self: *lexer) token {
    while (self.consume_if(std.ascii.isDigit)) {}
    return self.generate(.integer_literal);
}

// Tests
test lexer {
    const source =
        \\/**
        \\ * Multiline comments
        \\ */
        \\identifier /* in the middle comment */ :: () {} // one line comment
    ;

    const tokens = &[_]token{
        token.create(
            "identifier",
            .identifier,
            .{ .column = 0, .line = 3, .offset = 30 },
            .{ .column = 10, .line = 3, .offset = 40 },
        ),
        token.create(
            "::",
            .symbol,
            .{ .column = 39, .line = 3, .offset = 69 },
            .{ .column = 41, .line = 3, .offset = 71 },
        ),
        token.create(
            "(",
            .symbol,
            .{ .column = 42, .line = 3, .offset = 72 },
            .{ .column = 43, .line = 3, .offset = 73 },
        ),
        token.create(
            ")",
            .symbol,
            .{ .column = 43, .line = 3, .offset = 73 },
            .{ .column = 44, .line = 3, .offset = 74 },
        ),
        token.create(
            "{",
            .symbol,
            .{ .column = 45, .line = 3, .offset = 75 },
            .{ .column = 46, .line = 3, .offset = 76 },
        ),
        token.create(
            "}",
            .symbol,
            .{ .column = 46, .line = 3, .offset = 76 },
            .{ .column = 47, .line = 3, .offset = 77 },
        ),
    };

    var l = lexer.initialize(source);

    for (tokens) |expected| {
        const actual = l.next();
        try std.testing.expectEqual(actual, expected);
    }

    const must_be_eof = l.next();
    try std.testing.expect(must_be_eof.kind == .eof);
}
