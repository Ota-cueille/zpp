const std = @import("std");

const token = @import("./token.zig");

const lexer = @This();

const Elexer = error{
    general,
    unknown_character,
    unterminated_construct,
    malformed_literal,
    unexpected_character,
};

// Configuration
const LOOKBACK = 2;
const LOOKAHEAD = 4;

// Base Information
source: []const u8,

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
    @memset(std.mem.asBytes(&self), 0);

    self.source = source;

    for (0..LOOKAHEAD + 1) |_| {
        _ = try self.next();
    }
}

pub fn next(self: *lexer) Elexer!void {
    self.error_context.at = token.location{};
    self.error_context.message = "Nothing is implemented in the lexer yet!";
    return Elexer.general;
}

pub fn peek(self: *lexer, offset: i3) token {
    const slice: []token = @as(*token, @ptrCast(&self.lookback[0]))[0 .. LOOKBACK + 1 + LOOKAHEAD];
    return slice[LOOKBACK + offset];
}

fn shift(self: *lexer, new: token) void {
    const slice: []token = @as(*token, @ptrCast(&self.lookback[0]))[0 .. LOOKBACK + 1 + LOOKAHEAD];
    std.mem.copyBackwards(token, slice[0..slice.len], slice[1 .. slice.len - 1]);
    slice[slice.len - 1] = new;
}
