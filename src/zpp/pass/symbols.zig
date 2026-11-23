const std = @import("std");
const ast = @import("../ast.zig");

pub const table = struct {
    pub const symbol = struct {
        kind: enum(u8) { constant, variable, function, parameter, return_value, type },
    };

    parent: *table,
    symbols: std.StringHashMap(symbol),
};

// maybe have a scratch allocator to store
// the symbol table tree and then copy it at
// the end of the symbols hashtable

pub fn visit(stackframe: *table, root: *ast.node, allocator: std.mem.Allocator) *table {
    switch (root.*) {
        .binary => |node| {
            // instead of hard reject of same variable name allow soft shadownig for different types, allowing "renaming" of variables
            // example, for some types you want the same semantic for std::string and const char* and std::string_view
            // note(ota): then this will enfore strong typing with symbol, how to resolve function call arguments
            // and downcast could be a problem if allowed flexible
            std.debug.assert(node.lhs.k == .identifier and !stackframe.symbols.contains(node.lhs.identifier.content));
            if (node.operator.k == .symbol and node.operator.meta.symbol.is("::")) {
                stackframe.symbols.put(node.lhs.identifier.content, table.symbol{
                    .kind = switch (node.rhs) {
                        .function => .function,
                        else => .constant,
                    },
                }) catch unreachable;
            } else if (node.operator.k == .symbol and node.operator.meta.symbol.is(":=")) {
                stackframe.symbols.put(node.lhs.identifier.content, table.symbol{
                    .kind = switch (node.rhs) {
                        .function => .function,
                        else => .variable,
                    },
                }) catch unreachable;
            }
            visit(stackframe, node.lhs, allocator);
            visit(stackframe, node.rhs, allocator);
        },
        .block => |block| {
            const block_stackframe = allocator.create(table) catch unreachable;
            block_stackframe.parent = stackframe;
            block_stackframe.symbols = std.StringHashMap(table.symbol).init(allocator);

            for (block.statements) |statement| {
                visit(block_stackframe, statement, allocator);
            }
        },
        .unary => |unary| {
            visit(stackframe, unary.value, allocator);
        },
        .function => |function| {
            const header_stackframe = allocator.create(table) catch unreachable;
            header_stackframe.parent = stackframe;
            header_stackframe.symbols = std.StringHashMap(table.symbol).init(allocator);

            for (function.parameters) |parameter| {
                header_stackframe.symbols.put(parameter.name.content, table.symbol{
                    .kind = .variable,
                }) catch unreachable;
            }

            for (function.returns) |ret_value| {
                if (ret_value.name) |name| {
                    header_stackframe.symbols.put(name.content, table.symbol{
                        .kind = .variable,
                    }) catch unreachable;
                }
            }

            visit(header_stackframe, function.body, allocator);
        },
        .loop => |loop| {
            const iterator_stackframe = allocator.create(table) catch unreachable;
            iterator_stackframe.parent = stackframe;
            iterator_stackframe.symbols = std.StringHashMap(table.symbol).init(allocator);

            // visit iterator when semantic will be decided

            visit(iterator_stackframe, loop.body, allocator);
        },
        .conditional_branch => |@"if"| {
            visit(stackframe, @"if".tbody, allocator);
            if (@"if".fbody) |fbody| {
                visit(stackframe, fbody, allocator);
            }
        },
        .call => {
            for (root.call.arguments) |argument| {
                visit(stackframe, argument, allocator);
            }
        },
        .block_branch => {
            if (root.block_branch.value) |node| {
                visit(stackframe, node, allocator);
            }
        },
        .directive => {
            // node(ota): are payload not intended for compiler extensions ???
            if (root.directive.payload) |payload| {
                visit(stackframe, payload, allocator);
            }
        },
        .function_return => {
            if (root.function_return.value) |value| {
                visit(stackframe, value, allocator);
            }
        },
        .type => {
            for (root.type.content) |element| {
                visit(stackframe, element, allocator);
            }
        },
        else => {},
    }
}
