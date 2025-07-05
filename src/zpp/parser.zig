const std = @import("std");

const lexer = @import("lexer.zig");
const token = @import("token.zig");

const utils = @import("../utils.zig");

const ast = @import("ast.zig");

const parser = @This();

temporary_allocator: std.mem.Allocator,
lexer: *lexer,
lookaheads: std.BoundedArray(token, 10),

pub fn initialize(allocator: std.mem.Allocator, l: *lexer) parser {
    var self: parser = undefined;
    self.temporary_allocator = allocator;
    self.lexer = l;

    return self;
}

pub fn parse(self: *parser, allocator: std.mem.Allocator) *ast.program {
    const program = ast.program.alloc(allocator, .{});

    var lookahead = self.lexer.peek();
    while (lookahead.kind != .eof) : (lookahead = self.lexer.peek()) {
        switch (lookahead.kind) {
            // declaration
            .identifier => {
                const identifier = self.consume(.identifier);
                const op_double_colon = self.consume(.symbol);
                std.debug.assert(std.mem.eql(u8, "::", op_double_colon.content));

                lookahead = self.lexer.peek();
                switch (lookahead.kind) {
                    .symbol => {},
                    else => {},
                }
                const node = self.function(allocator, identifier);

                program.add(self.temporary_allocator, node);
            },
            else => unreachable,
        }
    }

    return program;
}

fn consume(self: *parser, kind: token.kind) token {
    const tok = self.lexer.next();
    std.debug.assert(tok.kind == kind);
    return tok;
}

fn consume_symbol(self: *parser, symbol: []const u8) token {
    const tok = self.lexer.next();
    std.debug.assert(tok.kind == .symbol and std.mem.eql(u8, tok.content, symbol));
    return tok;
}

fn consume_one_of(self: *parser, comptime kinds: []const token.kind) token {
    const tok = self.lexer.next();

    inline for (kinds) |kind| {
        if (tok.kind == kind) return tok;
    }

    std.log.err("unable to parse one of {any}, got {}\n", .{ kinds, tok.kind });
    unreachable;
}

/// Implementation detail
fn function(self: *parser, allocator: std.mem.Allocator, identifier: token) *ast.function {
    // parameters are of defined size so we can allocate them on the main arena
    var params = self.parameters(allocator);

    // expect identifier
    const return_type_token = self.consume(.identifier);

    // expect '{'
    _ = self.consume_symbol("{");

    var expressions = std.ArrayList(ast.node).init(self.temporary_allocator);
    defer expressions.deinit();

    while (self.lexer.peek().kind != .symbol or self.lexer.peek().content[0] != '}') {}

    const body = allocator.alloc(ast.node, expressions.items.len) catch unreachable;
    std.mem.copyForwards(ast.node, body, expressions.items);

    // expect '}'
    _ = self.consume_symbol("}");

    return ast.function.alloc(allocator, .{
        .identifier = identifier,
        .return_type = return_type_token,
        .parameters = params.toOwnedSlice() catch unreachable,
        .body = expressions.toOwnedSlice() catch unreachable,
    });
}

fn parameters(self: *parser, allocator: std.mem.Allocator) std.ArrayList(ast.parameter) {
    var storage = std.ArrayList(ast.parameter).init(allocator);

    // expect '('
    _ = self.consume_symbol("(");

    const lookahead = self.lexer.peek();
    if (lookahead.kind == .symbol and lookahead.content[0] == ')') {
        _ = self.consume_symbol(")");
        return storage;
    }

    while (true) {
        // allocate one parameter
        const parameter = storage.addOne() catch unreachable;

        // expect identifier
        const parameter_identifier_token = self.consume(.identifier);

        // expect ':'
        const must_be_colon = self.consume_symbol(":");

        // expect identifier
        const parameter_type_token = self.consume(.identifier);

        _ = ast.parameter.create(parameter, .{
            .colon = must_be_colon,
            .identifier = parameter_identifier_token,
            .type = parameter_type_token,
        });

        const last_symbol_was = self.consume(.symbol);
        switch (last_symbol_was.content[0]) {
            ',' => continue,
            ')' => break,
            else => unreachable,
        }
    }

    return storage;
}

fn literal(self: *parser, allocator: std.mem.Allocator) ast.node {
    const lookahead = self.lexer.peek();
    return switch (lookahead.kind) {
        .integer_literal => ast.node.alloc(ast.integer, allocator, lookahead),
        else => unreachable,
    };
}
