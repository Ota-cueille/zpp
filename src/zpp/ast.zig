const std = @import("std");
const ast = @This();

// literals
pub const integer = @import("./ast/integer.zig");

// identifiers and shit
pub const identifier = @import("./ast/identifier.zig");

// high level
pub const parameter = @import("./ast/parameter.zig");
pub const function = @import("./ast/function.zig");
pub const program = @import("./ast/program.zig");

pub const node = union(enum) {
    // literals
    integer: *integer,

    // identifiers and shit
    identifier: *identifier,

    // high level
    parameter: *parameter,
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

            // identifiers and shit
            identifier => node{ .identifier = ctx },

            // high level
            parameter => node{ .parameter = ctx },
            function => node{ .function = ctx },
            program => node{ .program = ctx },

            else => @compileError("Unknown ast.node type " ++ @typeName(T)),
        };
    }
};
