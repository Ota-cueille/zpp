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
pub const binary_operator = @import("./ast/binary_opeartor.zig");

// high level
pub const assignment = @import("./ast/assignment.zig");
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
    binary_operator: *binary_operator,

    // high level
    assignment: *assignment,
    program: *program,

    pub fn print(self: *const node, writer: std.io.AnyWriter, depth: u16) void {
        switch (self.*) {
            inline else => |case| case.print(writer, depth),
        }
    }

    pub fn create(comptime T: type, allocator: std.mem.Allocator, args: T.args) node {
        return node.from(T, T.create(allocator, args));
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
            binary_operator => node{ .binary_operator = ctx },

            // high level
            assignment => node{ .assignment = ctx },
            program => node{ .program = ctx },

            else => @compileError("Unknown ast.node type " ++ @typeName(T)),
        };
    }
};
