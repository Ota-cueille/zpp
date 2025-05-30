const std = @import("std");

const lexer = @import("lexer.zig");
const token = @import("token.zig");

const utils = @import("../utils.zig");

const ast = @import("ast.zig");
const operator = @import("operator.zig");

pub fn parse(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const program = ast.program.alloc(allocator, .{});

    while (true) {
        const lookahead = l.peek();
        if (lookahead.kind == .eof) break;

        const decl = function(allocator, l);

        program.add(allocator, decl);
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
fn declaration(_: std.mem.Allocator, l: *lexer) ast.node {
    // expect <identifier>
    // const identifier = consume(l, .identifier);

    // expect '::'
    const must_be_colons = consume(l, .symbol);
    std.debug.assert(std.mem.eql(u8, must_be_colons.content, "::"));

    // can be any of: <expression>, <function>, <struct>, <enum>, <union>
}

fn function(allocator: std.mem.Allocator, l: *lexer) ast.node {
    // expect <identifier>
    const identifier = consume(l, .identifier);

    // expect '::'
    const must_be_colons = consume(l, .symbol);
    std.debug.assert(std.mem.eql(u8, must_be_colons.content, "::"));

    // expect '('
    const must_be_open_parenthesis = consume(l, .symbol);
    std.debug.assert(must_be_open_parenthesis.content[0] == '(');

    var parameters = std.ArrayList(ast.parameter).init(allocator);

    var previous: ?token = null;
    while (l.peek().kind != .symbol) : (previous = consume(l, .symbol)) {
        // allocate one parameter
        const parameter = parameters.addOne() catch unreachable;

        const parameter_identifier_token = consume(l, .identifier);

        const must_be_colon = consume(l, .symbol);
        std.debug.assert(must_be_colon.content[0] == ':');

        const parameter_type_token = consume(l, .identifier);

        _ = parameter.create(.{
            .colon = must_be_colon,
            .identifier = parameter_identifier_token,
            .type = parameter_type_token,
        });
    }

    // expect ')'
    // it is possible for the previous loop to eat the last
    // symbol which should be ')' so we check for that
    previous = if (previous == null) consume(l, .symbol) else previous;
    std.debug.assert(previous.?.content[0] == ')');

    // expect '{'
    const must_be_open_brace = consume(l, .symbol);
    std.debug.assert(must_be_open_brace.content[0] == '{');

    var tempArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const tempAllocator = tempArena.allocator();

    var expressions = std.ArrayList(ast.node).init(tempAllocator);
    defer expressions.deinit();

    while (l.peek().kind != .symbol or l.peek().content[0] != '}') {
        expressions.append(expression(allocator, l, 0)) catch unreachable;

        const must_be_colon = consume(l, .symbol);
        std.debug.assert(must_be_colon.content[0] == ';');
    }

    const body = allocator.alloc(ast.node, expressions.items.len) catch unreachable;
    std.mem.copyForwards(ast.node, body, expressions.items);

    // expect '}'
    const must_be_close_brace = consume(l, .symbol);
    std.debug.assert(must_be_close_brace.content[0] == '}');

    return ast.node.alloc(ast.function, allocator, .{
        .identifier = identifier,
        .parameters = parameters.toOwnedSlice() catch unreachable,
        .body = expressions.toOwnedSlice() catch unreachable,
    });
}

fn call(allocator: std.mem.Allocator, l: *lexer) ast.node {
    // expect <identifier>
    const identifier = consume(l, .identifier);

    // expect '('
    const must_be_open_parenthesis = consume(l, .symbol);
    std.debug.assert(must_be_open_parenthesis.content[0] == '(');

    // expressions

    // expect ')'
    const must_be_close_parenthesis = consume(l, .symbol);
    std.debug.assert(must_be_close_parenthesis.content[0] == ')');

    return ast.node.alloc(ast.call, allocator, .{ identifier, &[_]ast.node{} });
}

fn expression(allocator: std.mem.Allocator, l: *lexer, precedence: u64) ast.node {
    var lhs = init: {
        const lookahead = l.peek();

        // at this point, the token is eather a literal, an identifier, an open parenthesis or a unary operator
        if (lookahead.kind == .symbol and lookahead.content[0] == '(') {
            _ = consume(l, .symbol);

            const parenthesized_expression = expression(allocator, l, 0);

            const must_be_close_parenthesis = consume(l, .symbol);
            std.debug.assert(must_be_close_parenthesis.content[0] == ')');

            break :init parenthesized_expression;
        } else if (lookahead.kind == .symbol and operator.is_unary(lookahead.content)) {
            break :init unary(allocator, l);
        }

        break :init literal_or_identifier(allocator, l);
    };

    while (true) {
        const expr = parse_with_precedence: {
            const lookahead = l.peek();

            const next_precedence = compute_next_precedence: {
                if (lookahead.kind != .symbol) break :parse_with_precedence lhs;
                const op = operator.from_slice(lookahead.content) orelse break :parse_with_precedence lhs;
                break :compute_next_precedence operator.precedence(op, false);
            };

            if (next_precedence <= precedence) {
                break :parse_with_precedence lhs;
            } else {
                const tok_operator = consume(l, .symbol);
                const rhs = expression(allocator, l, next_precedence);
                break :parse_with_precedence ast.node.alloc(ast.binary_operator, allocator, .{
                    .lhs = lhs,
                    .rhs = rhs,
                    .operator = tok_operator,
                });
            }
        };

        if (std.meta.eql(expr, lhs)) break;

        // lhs is now encoded in expr so we just continue to parse the rest of the expression
        lhs = expr;
    }

    return lhs;
}

fn unary(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const tok_operator = consume(l, .symbol);
    const lookahead = l.peek();

    const operand = init: {
        if (lookahead.kind == .symbol and lookahead.content[0] == '(') {
            // eat the '('
            _ = consume(l, .symbol);

            const expr = expression(allocator, l, 0);

            // eat the ')'
            const must_be_close_parenthesis = consume(l, .symbol);
            std.debug.assert(must_be_close_parenthesis.content[0] == ')');

            break :init expr;
        } else break :init literal_or_identifier(allocator, l);
    };

    return ast.node.alloc(ast.unary_operator, allocator, .{
        .operator = tok_operator,
        .expression = operand,
    });
}

fn literal_or_identifier(allocator: std.mem.Allocator, l: *lexer) ast.node {
    const tok = consume_one_of(l, &[_]token.kind{ .identifier, .literal_integer, .literal_real, .literal_character, .literal_string });
    return switch (tok.kind) {
        // literals
        .literal_integer => ast.node.alloc(ast.integer, allocator, tok),
        .literal_real => ast.node.alloc(ast.real, allocator, tok),
        .literal_character => ast.node.alloc(ast.character, allocator, tok),
        .literal_string => ast.node.alloc(ast.string, allocator, tok),

        // identifiers and shit
        .identifier => ast.node.alloc(ast.identifier, allocator, tok),

        else => unreachable,
    };
}
