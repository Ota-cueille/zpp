const std = @import("std");

const token = @import("token.zig");

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

    self.current_token = self.next();

    return self;
}

pub fn peek(self: *const lexer) token {
    return self.current_token;
}

pub fn next(self: *lexer) token {
    while (true) {
        self.skip_whitespaces();

        if (self.current_source.len == 0) {
            self.current_token = self.eof();
            return self.current_token;
        }

        self.previous_location = self.current_location;

        self.current_token = switch (self.current_source[0]) {
            '\'' => self.character(),

            '"' => self.string(),

            // try read an integer or a real number
            '0'...'9' => self.number(),

            // try to read an identifier
            'a'...'z', 'A'...'Z', '_' => self.identifier(),

            // SYMBOLS ????

            // simple single symbols
            '(', ')', '{', '}', '[', ']', ',', '&', ';' => self.single_character_symbol(),

            // see if it is not possible to
            // separate number from '.' symbol
            '.' => self.dot_or_real_number(),

            // same as for '.'
            '/' => self.comment_or_division_related_operators() orelse continue,

            // keeping '@' for annotations
            // keeping '#' for compiler directives

            ':' => self.one_followup_symbol(&[_]u8{ ':', '=' }),
            '=' => self.one_followup_symbol(&[_]u8{ '=', '>' }),
            '-' => self.one_followup_symbol(&[_]u8{ '=', '>' }),
            '!', '>', '<', '+', '*' => self.one_followup_symbol(&[_]u8{'='}),

            else => {
                std.log.err("unrecognized character: {}\n", .{self.current_source[0]});
                unreachable;
            },
        };

        return self.current_token;
    }
}

fn skip_whitespaces(self: *lexer) void {
    while (self.consume_if(std.ascii.isWhitespace)) {}
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

fn consume(self: *lexer, c: u8) void {
    std.debug.assert(self.current_source.len != 0 and self.current_source[0] == c);
    self.advance();
}

fn generate(self: *lexer, k: token.kind) token {
    return token.create(self.source[self.previous_location.offset..self.current_location.offset], k, self.previous_location, self.current_location);
}

/// Implementation detail
fn number(self: *lexer) token {
    // read first part of the number
    while (self.consume_if(std.ascii.isDigit)) {}

    if (!self.check('.')) { // NOTE: should check for "and !self.check('e') and !self.check('E')"
        // number is an integer
        return self.generate(.literal_integer);
    }

    // NOTE: handle negative exponents

    self.consume('.');

    // number is a real
    while (self.consume_if(std.ascii.isDigit)) {}

    return self.generate(.literal_real);
}

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

fn is_not_newline(c: u8) bool {
    return c != '\n' and c != std.ascii.control_code.vt;
}

fn string(self: *lexer) token {
    self.consume('"');

    var is_escaped = false;
    while (!self.check('"') or is_escaped) {
        is_escaped = self.check('\\');

        const is_newline_or_eof = !self.consume_if(is_not_newline);

        if (is_newline_or_eof and self.current_source.len != 0) {
            std.log.err("invalid character in string literal, no newline nor vertical tabs are allowed in this context !", .{});
        } else if (is_newline_or_eof) {
            std.log.err("unexpected eof while lexing string literal !", .{});
        }
    }

    self.consume('"');

    return self.generate(.literal_string);
}

fn character(self: *lexer) token {
    self.consume('\'');

    // TODO: unicodes and unicodes escape
    const success = self.consume_if(std.ascii.isASCII);
    if (!success) {
        std.log.err("character literal currently supports ascii codes only !", .{});
        unreachable;
    }

    self.consume('\'');

    return self.generate(.literal_character);
}

fn dot_or_real_number(self: *lexer) token {
    self.advance();

    switch (self.current_source[0]) {
        // if next character is a digit then it is a real number
        // otherwise it is the '.' operator
        '0'...'9' => {
            while (self.consume_if(std.ascii.isDigit)) {}
            return self.generate(.literal_real);
        },
        else => return self.generate(.symbol),
    }
}

fn comment_or_division_related_operators(self: *lexer) ?token {
    self.advance();

    switch (self.current_source[0]) {
        '/' => {
            while (self.consume_if(is_not_newline)) {}

            // maybe skipping comments is an option ?
            // could create proper token for comments
            return null;
        },
        else => {
            // could be '/='
            _ = self.consume_equal('=');
            return self.generate(.symbol);
        },
    }
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
