const std = @import("std");

pub const node = union(enum) {
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

    pub fn from(comptime T: type, _: *T) node {
        return switch (T) {
            else => @compileError("Unknown ast.node type " ++ @typeName(T)),
        };
    }
};
