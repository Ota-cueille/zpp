const std = @import("std");

const token = @import("token.zig");
const lexer = @import("lexer.zig");

const parser = @This();

allocator: std.mem.Allocator,

lexer: lexer,

pub fn initialize(allocator: std.mem.Allocator, l: lexer) parser {
    var self: parser = undefined;

    self.allocator = allocator;

    self.lexer = l;

    return self;
}

pub fn parse(self: *parser) !void {
    while (true) {
        if (self.lexer.current.kind == .eof) break;

        // else expect declaration on the global scope
        if (self.lexer.peek(0).kind != .identifier)
            return error.expected_identifier_for_declaration;

        // consume the identifier
        const identifier = self.consume();

        // TODO: at the moment, we only parse '::' but let's think of how we could handle the ':' <type> ':' case!
        const is_binding_operator = self.lexer.peek(0).kind == .symbol or self.lexer.peek(0).meta.symbol.is("::");
        if (!is_binding_operator) return error.expected_type_declaration_or_binding_operator;

        // consume the binding
        const binding_op = self.consume();

        // is the next construct a type declaration
        if (self.is_type_declaration()) {
            const struct_kw = self.consume();

            if (self.lexer.current.kind != .symbol or !self.lexer.current.meta.symbol.is("{")) return error.expected_open_brace_on_type_declaration;
            _ = self.consume();

            // at the moment, member declarations are:
            // 1. <identifier> ':' <type> ['=' <expression>],
            // 2. <identifier> '::' <function declaration>
            while (true) {
                if (self.lexer.current.kind != .identifier) return error.expecting_identifier_for_struct_declaration;
                const identifier = self.consume();

            }

            if (self.lexer.current.kind != .symbol or !self.lexer.current.meta.symbol.is("}")) return error.expected_close_brace_on_type_declaration;
            _ = self.consume();
        }

        // is the next construct a function declaration
        if (self.is_function_declaration()) {}
    }
}

/// Internal Implementation
fn consume(self: *parser) token {
    const tok = self.lexer.peek(0);
    try self.lexer.next();
    return tok;
}

// preview
fn is_type_declaration(self: *const parser) bool {
    const is_struct = self.lexer.peek(0).kind == .keyword and self.lexer.peek(0).meta.keyword == .@"struct";
    return is_struct;
}

fn is_function_declaration(self: *const parser) bool {
    const starts_with_lparenthesis = self.lexer.peek(0).kind == .symbol and self.lexer.peek(0).meta.symbol.is("(");
    const has_parameter_list = self.lexer.peek(1).kind == .identifier and self.lexer.peek(2).kind == .symbol and self.lexer.peek(2).meta.symbol.is(":");
    const followed_by_rparenthesis = self.lexer.peek(1).kind == .symbol and self.lexer.peek(1).meta.symbol.is(")");
    return starts_with_lparenthesis and (has_parameter_list or followed_by_rparenthesis);
}
