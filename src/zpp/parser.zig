const std = @import("std");

const token = @import("token.zig");
const ast = @import("ast.zig");

const parser = @This();

var scratch_buffer: [1 * 1024 * 1024]u8 = undefined; // 1 Mo scratch buffer
var scratch_allocator = std.heap.FixedBufferAllocator.init(&scratch_buffer);

fn get_scratch_allocator() std.mem.Allocator {
    return scratch_allocator.allocator();
}

tokens: []token,
cursor: u64,
ast_node_count: usize,
ast_function_parameter_node_count: usize,
ast_function_return_node_count: usize,

pub fn initialize(tokens: []token) parser {
    var self: parser = undefined;

    self.tokens = tokens;
    self.cursor = 0;
    self.ast_node_count = 0;
    self.ast_function_parameter_node_count = 0;
    self.ast_function_return_node_count = 0;

    std.debug.assert(self.tokens[self.tokens.len - 1].k == .eof);

    return self;
}

pub fn lookahead(self: *const parser) *token {
    std.debug.assert(self.cursor < self.tokens.len);
    return &self.tokens[self.cursor];
}

pub fn next(self: *parser, allocator: std.mem.Allocator) *ast.node {
    scratch_allocator.reset();
    const node = self.parse_expression(allocator);
    _ = self.consume_symbol_if(";");
    return node;
}

fn parse_directive(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    const name = self.lookahead();

    node.* = ast.node{
        .directive = .{
            .name = name,
            .payload = null,
        },
    };

    self.consume(.directive);

    // todo(ota): implement complex directives
    // like with DSL or parameters

    return node;
}

fn parse_function(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    self.consume_symbol("(");

    const scratch = get_scratch_allocator();
    var parameters_accumulator = std.ArrayList(ast.function.parameter).initCapacity(scratch, 0) catch unreachable;

    while (!self.check_symbol(")")) {
        const parameter_name = self.lookahead();
        self.consume(.identifier);

        self.consume_symbol(":");

        const parameter_type = self.parse_expression(allocator);

        parameters_accumulator.append(
            scratch,
            ast.function.parameter{
                .name = parameter_name,
                .type = parameter_type,
            },
        ) catch unreachable;
        self.ast_function_parameter_node_count += 1;

        if (!self.consume_symbol_if(",")) break;
    }

    self.consume_symbol(")");

    // copy all parameters to ast node buffer
    const parameters = allocator.dupe(ast.function.parameter, parameters_accumulator.items) catch unreachable;

    var returns_accumulator = std.ArrayList(ast.function.return_type).initCapacity(scratch, 0) catch unreachable;
    while (!self.check_symbol("{")) {
        const is_named = self.has_enough_tokens(2) and self.tokens[self.cursor + 1].k == .symbol and self.tokens[self.cursor + 1].meta.symbol.is(":");

        if (is_named) {
            const name = self.lookahead();
            self.consume(.identifier);

            self.consume_symbol(":");

            const return_type = self.parse_expression(allocator);

            returns_accumulator.append(
                scratch,
                ast.function.return_type{
                    .name = name,
                    .type = return_type,
                },
            ) catch unreachable;
        } else {
            const return_type = self.parse_expression(allocator);

            returns_accumulator.append(
                scratch,
                ast.function.return_type{
                    .name = null,
                    .type = return_type,
                },
            ) catch unreachable;
        }

        self.ast_function_return_node_count += 1;
        if (!self.consume_symbol_if(",")) break;
    }

    const returns = allocator.dupe(ast.function.return_type, returns_accumulator.items) catch unreachable;

    const body = self.parse_block(allocator);

    node.* = ast.node{
        .function = .{
            .parameters = parameters,
            .returns = returns,
            .body = body,
        },
    };

    return node;
}

fn parse_block(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    self.consume_symbol("{");

    if (self.check_symbol("}")) {
        node.* = .{
            .block = .{
                .statements = &[_]*ast.node{},
            },
        };
        self.consume_symbol("}");
        return node;
    }

    const scratch = get_scratch_allocator();

    var statements_accumulator = std.ArrayList(*ast.node).initCapacity(scratch, 0) catch unreachable;
    while (!self.check_symbol("}")) {
        const statement = self.parse_expression(allocator);
        statements_accumulator.append(scratch, statement) catch unreachable;
        _ = self.consume_symbol_if(";");
    }

    const statements = allocator.dupe(*ast.node, statements_accumulator.items) catch unreachable;

    self.consume_symbol("}");

    node.* = ast.node{
        .block = .{
            .statements = statements,
        },
    };

    return node;
}

fn parse_type(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    const kw = self.lookahead();
    self.consume(.keyword);

    self.consume_symbol("{");

    if (kw.meta.keyword.is("struct")) {
        // parse struct declaration
    } else if (kw.meta.keyword.is("enum")) {
        // parse enum declaration
    } else if (kw.meta.keyword.is("union")) {
        // parse union declaration
    } else {
        std.debug.panic("Unexpected keyword for type declaration: {}", .{kw});
    }

    self.consume_symbol("}");

    return node;
}

fn parse_call(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    const callee = self.lookahead();
    self.consume(.identifier);

    const scratch = get_scratch_allocator();
    var arguments_accumulator = std.ArrayList(*ast.node).initCapacity(scratch, 0) catch unreachable;

    self.consume_symbol("(");
    while (!self.check_symbol(")")) {
        const argument = self.parse_expression(allocator);
        arguments_accumulator.append(scratch, argument) catch unreachable;
        _ = self.consume_symbol_if(",");
    }
    self.consume_symbol(")");

    const arguments = allocator.dupe(*ast.node, arguments_accumulator.items) catch unreachable;

    node.* = ast.node{
        .call = .{
            .callee = callee,
            .arguments = arguments,
        },
    };

    return node;
}

fn parse_conditional_branch(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    self.consume_keyword("if");

    const condition = self.parse_expression(allocator);

    const true_block = self.parse_expression(allocator);

    if (self.consume_keyword_if("else")) {
        const false_block = self.parse_expression(allocator);

        node.* = ast.node{
            .conditional_branch = .{
                .condition = condition,
                .tbody = true_block,
                .fbody = false_block,
            },
        };

        return node;
    }

    node.* = ast.node{
        .conditional_branch = .{
            .condition = condition,
            .tbody = true_block,
            .fbody = null,
        },
    };

    return node;
}

fn parse_loop(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    self.consume_keyword("for");

    // hmmm
    const iterator = self.parse_expression(allocator);
    const body = self.parse_expression(allocator);

    node.* = ast.node{
        .loop = .{
            .iterator = iterator,
            .body = body,
        },
    };

    return node;
}

fn parse_branch(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const node = allocator.create(ast.node) catch unreachable;
    self.ast_node_count += 1;

    node.* = ast.node{
        .block_branch = .{
            .keyword = self.lookahead(),
            .value = null,
        },
    };

    self.consume(.keyword);

    return node;
}

fn parse_unary(self: *parser, allocator: std.mem.Allocator) *ast.node {
    const tok = self.lookahead();

    // 1. check unary operator
    if (tok.is_unary_operator()) {
        const node = allocator.create(ast.node) catch unreachable;
        self.ast_node_count += 1;

        self.consume(.symbol); // consume the operator

        node.* = ast.node{
            .unary = .{
                .operator = tok,
                .value = self.parse_unary(allocator),
            },
        };

        return node;
    }

    // 2. check function declaration
    if (self.is_function()) {
        return self.parse_function(allocator);
    }

    // 3. check type declaration
    if (self.is_type()) {
        return self.parse_type(allocator);
    }

    // 4. check literals
    if (tok.k == .literal) {
        const node = allocator.create(ast.node) catch unreachable;
        self.ast_node_count += 1;

        node.* = ast.node{ .literal = tok };

        self.consume(.literal); // consume the literal

        return node;
    }

    // 5. check parenthesized expression
    if (tok.k == .symbol and tok.meta.symbol.is("(")) {
        self.consume_symbol("("); // consume '('
        const node = self.parse_expression(allocator);
        self.consume_symbol(")"); // consume ')'
        return node;
    }

    // 6. check function call
    if (self.is_call()) {
        return self.parse_call(allocator);
    }

    // 7. check identifier
    if (tok.k == .identifier) {
        const node = allocator.create(ast.node) catch unreachable;
        self.ast_node_count += 1;

        node.* = ast.node{ .identifier = tok };

        self.consume(.identifier); // consume the identifier

        return node;
    }

    // 8. check directives
    if (tok.k == .directive) {
        return self.parse_directive(allocator);
    }

    // 9. check block
    if (tok.k == .symbol and tok.meta.symbol.is("{")) {
        return self.parse_block(allocator);
    }

    // 10. check control flow

    // if
    if (tok.k == .keyword and tok.meta.keyword.is("if")) {
        return self.parse_conditional_branch(allocator);
    }

    // for
    if (tok.k == .keyword and tok.meta.keyword.is("for")) {
        return self.parse_loop(allocator);
    }

    // break or return
    if (tok.k == .keyword and tok.meta.keyword.is("break") or tok.meta.keyword.is("return")) {
        return self.parse_branch(allocator);
    }

    std.debug.panic("Unexpected token for unary expression or literal: {}", .{tok});
}

fn parse_expression_with_precedence(self: *parser, allocator: std.mem.Allocator, precedence: u8) *ast.node {
    var lhs = self.parse_unary(allocator);

    while (true) {
        const tok = self.lookahead();
        // stop pratt parsing at ';' and '{' for end of expressions and beginning of block
        if (!tok.is_binary_operator()) break;

        const new_precedence = tok.get_binary_operator_precedence();
        if (new_precedence < precedence) break;

        const operator = self.lookahead();
        self.consume(operator.k);

        const node = allocator.create(ast.node) catch unreachable;
        node.* = ast.node{
            .binary = .{
                .lhs = lhs,
                .operator = operator,
                .rhs = self.parse_expression_with_precedence(allocator, new_precedence + 1),
            },
        };

        lhs = node;
    }

    return lhs;
}

fn parse_expression(self: *parser, allocator: std.mem.Allocator) *ast.node {
    return self.parse_expression_with_precedence(allocator, 0);
}

/// utilities maybe to be removed
fn consume_until_sym(self: *parser, comptime symbol: []const u8) void {
    var current = self.lookahead();

    while (current.k != .eof and !(current.k == .symbol and current.meta.symbol.is(symbol))) {
        self.consume(current.k);
        current = self.lookahead();
    }
}

/// Internal Implementation
fn check(self: *const parser, kind: token.kind) bool {
    return self.cursor != self.tokens.len and self.tokens[self.cursor].k == kind;
}

fn check_symbol(self: *const parser, comptime symbol: []const u8) bool {
    return self.check(.symbol) and self.tokens[self.cursor].meta.symbol.is(symbol);
}

fn check_keyword(self: *const parser, comptime keyword: []const u8) bool {
    return self.check(.keyword) and self.tokens[self.cursor].meta.keyword.is(keyword);
}

fn consume(self: *parser, kind: token.kind) void {
    std.debug.assert(self.check(kind));
    self.cursor += 1;
}

fn consume_symbol(self: *parser, comptime symbol: []const u8) void {
    std.debug.assert(self.check_symbol(symbol));
    self.cursor += 1;
}

fn consume_symbol_if(self: *parser, comptime symbol: []const u8) bool {
    if (self.check_symbol(symbol)) {
        self.cursor += 1;
        return true;
    }
    return false;
}

fn consume_keyword(self: *parser, comptime keyword: []const u8) void {
    std.debug.assert(self.check_keyword(keyword));
    self.cursor += 1;
}

fn consume_keyword_if(self: *parser, comptime keyword: []const u8) bool {
    if (self.check_keyword(keyword)) {
        self.cursor += 1;
        return true;
    }
    return false;
}

// preview
fn has_enough_tokens(self: *const parser, n: u64) bool {
    return self.tokens.len - self.cursor >= n;
}

pub fn is_function(self: *const parser) bool {
    if (!self.has_enough_tokens(2)) return false;

    const starts_with_lparenthesis = self.tokens[self.cursor].k == .symbol and self.tokens[self.cursor].meta.symbol.is("(");
    // note(ota): do we need to check for the type identifier to confirm this is a parameter list?
    const has_parameter_list = self.has_enough_tokens(3) and self.tokens[self.cursor + 1].k == .identifier and self.tokens[self.cursor + 2].k == .symbol and self.tokens[self.cursor + 2].meta.symbol.is(":");
    // note(ota): '()' is not an expression so we are assured that this is a function declaration
    const is_followed_by_rparenthesis = self.tokens[self.cursor + 1].k == .symbol and self.tokens[self.cursor + 1].meta.symbol.is(")");

    return starts_with_lparenthesis and (has_parameter_list or is_followed_by_rparenthesis);
}

pub fn is_type(self: *const parser) bool {
    return self.has_enough_tokens(1) and self.tokens[self.cursor].k == .keyword and (self.tokens[self.cursor].meta.keyword.is("struct") or self.tokens[self.cursor].meta.keyword.is("enum") or self.tokens[self.cursor].meta.keyword.is("union"));
}

pub fn is_call(self: *const parser) bool {
    if (!self.has_enough_tokens(2)) return false;

    const starts_with_identifier = self.tokens[self.cursor].k == .identifier;
    const is_followed_by_lparenthesis = self.tokens[self.cursor + 1].k == .symbol and self.tokens[self.cursor + 1].meta.symbol.is("(");
    return starts_with_identifier and is_followed_by_lparenthesis;
}
