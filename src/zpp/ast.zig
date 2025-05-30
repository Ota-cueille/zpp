const std = @import("std");
const ast = @This();

// literals
pub const real = @import("./ast/real.zig");
pub const integer = @import("./ast/integer.zig");
pub const character = @import("./ast/character.zig");
pub const string = @import("./ast/string.zig");

// identifiers and shit
pub const identifier = @import("./ast/identifier.zig");

// expressions
pub const unary_operator = @import("./ast/unary_operator.zig");
pub const binary_operator = @import("./ast/binary_operator.zig");
pub const call = @import("./ast/call.zig");

// high level
pub const parameter = @import("./ast/parameter.zig");
pub const declaration = @import("./ast/declaration.zig");
pub const function = @import("./ast/function.zig");
pub const program = @import("./ast/program.zig");

pub const node = union(enum) {
    // literals
    real: *real,
    integer: *integer,
    string: *string,
    character: *character,

    // identifiers and shit
    identifier: *identifier,

    // expressions
    unary_operator: *unary_operator,
    binary_operator: *binary_operator,
    call: *call,

    // high level
    parameter: *parameter,
    declaration: *declaration,
    function: *function,
    program: *program,

    pub fn print(self: *const node, writer: std.io.AnyWriter, depth: u16) void {
        switch (self.*) {
            inline else => |case| case.print(writer, depth),
        }
    }

    pub fn create(comptime T: type, memory: *T, args: T.args) node {
        return node.from(T, T.create(memory, args));
    }

    pub fn alloc(comptime T: type, allocator: std.mem.Allocator, args: T.args) node {
        return node.from(T, T.alloc(allocator, args));
    }

    pub fn from(comptime T: type, ctx: *T) node {
        return switch (T) {
            // literals
            integer => node{ .integer = ctx },
            real => node{ .real = ctx },
            string => node{ .string = ctx },
            character => node{ .character = ctx },

            // identifiers and shit
            identifier => node{ .identifier = ctx },

            // expressions
            unary_operator => node{ .unary_operator = ctx },
            binary_operator => node{ .binary_operator = ctx },
            call => node{ .call = ctx },

            // high level
            parameter => node{ .parameter = ctx },
            declaration => node{ .declaration = ctx },
            function => node{ .function = ctx },
            program => node{ .program = ctx },

            else => @compileError("Unknown ast.node type " ++ @typeName(T)),
        };
    }
};
