const std = @import("std");

const lexer = @import("lexer.zig");
const token = @import("./token.zig");

const utils = @import("../utils.zig");

const ast = @import("ast.zig");
const operator = @import("./operator.zig");

pub fn parse(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const program = ast.program.create(allocator, .{});

    while (true) {
        const lookahead = l.peek();
        if (lookahead.kind == .eof) break;

        const s = expression(allocator, l, 0);

        program.add(allocator, s);
    }

    return ast.node.from(ast.program, program);
}

fn consume(l: *lexer, kind: token.kind) token {
    const tok = l.peek();
    std.debug.assert(tok.kind == kind);
    _ = l.next();
    return tok;
}

fn consume_one_of(l: *lexer, comptime kinds: []const token.kind) token {
    const tok = l.peek();
    inline for (kinds) |kind| {
        if (tok.kind == kind) {
            _ = l.next();
            return tok;
        }
    }

    std.log.err("unable to parse one of {any}, got {}\n", .{ kinds, tok.kind });
    unreachable;
}

/// Implementation detail

// fn statement(allocator: std.mem.Allocator, l: *lexer) ast.node {}

fn declaration(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const identifier = consume(l, .identifier);

    const lookahead = l.peek();
    std.debug.assert(lookahead.kind == .symbol);

    if (utils.convert(u16, lookahead.content) == comptime utils.convert(u16, ":=")) {
        const sym = consume(l, .symbol);
        const rhs = expression(allocator, l, 0);
        return ast.node.create(ast.declaration, allocator, .{
            .colon = sym,
            .identifier = identifier,
            .requested_T = null,
            .rhs = rhs,
        });
    }

    std.debug.assert(utils.convert(u16, lookahead.content) == ':');
}

fn is_open_parenthesis(tok: *const token) bool {
    return tok.kind == .symbol and tok.content.len == 1 and tok.content[0] == '(';
}

fn expression(allocator: std.mem.Allocator, l: *lexer, precedence: u64) ast.node {
    var lhs = init: {
        const lookahead = l.peek();
        if (is_open_parenthesis(&lookahead)) {
            _ = consume(l, .symbol);

            const parenthesized_expression = expression(allocator, l, 0);

            const must_be_close_parenthesis = consume(l, .symbol);
            std.debug.assert(must_be_close_parenthesis.content.len == 1 and must_be_close_parenthesis.content[0] == ')');

            break :init parenthesized_expression;
        }

        break :init literal_or_identifier(allocator, l);
    };

    while (true) {
        const expr = parse_with_precedence: {
            const lookahead = l.peek();

            if (lookahead.kind != .symbol or !operator.exists(lookahead.content))
                break :parse_with_precedence lhs;

            const next_precedence = operator.get_precedence(lookahead);

            if (next_precedence <= precedence) {
                break :parse_with_precedence lhs;
            } else {
                const tok_operator = consume(l, .symbol);
                const rhs = expression(allocator, l, next_precedence);
                break :parse_with_precedence ast.node.create(ast.binary_operator, allocator, .{ .lhs = lhs, .rhs = rhs, .operator = tok_operator });
            }
        };

        if (std.meta.eql(expr, lhs)) break;

        // lhs is now encoded in expr so we just continue to parse the rest of the expression
        lhs = expr;
    }

    return lhs;
}

fn literal_or_identifier(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const tok = consume_one_of(l, &[_]token.kind{ .identifier, .literal_integer, .literal_real, .literal_character, .literal_string });
    return switch (tok.kind) {
        // literals
        .literal_integer => ast.node.create(ast.integer, allocator, tok),
        .literal_real => ast.node.create(ast.real, allocator, tok),
        .literal_character => ast.node.create(ast.character, allocator, tok),
        .literal_string => ast.node.create(ast.string, allocator, tok),

        // identifiers and shit
        .identifier => ast.node.create(ast.identifier, allocator, tok),

        else => unreachable,
    };
}
