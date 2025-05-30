const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const program = @This();

pub const args = struct {};

functions: []ast.node,

pub fn create(self: *program, _: args) *program {
    self.functions = &[_]ast.node{};
    return self;
}

pub fn alloc(allocator: std.mem.Allocator, a: args) *program {
    const self = allocator.create(program) catch unreachable;
    return self.create(a);
}

pub fn print(self: *const program, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("program {{\n\n", .{}) catch unreachable;
    for (self.functions) |op| {
        op.print(writer, depth + 1);
        writer.print("\n", .{}) catch unreachable;
    }
    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}

pub fn add(self: *program, allocator: std.mem.Allocator, child: ast.node) void {
    switch (child) {
        .function => {
            self.functions = allocator.realloc(self.functions, self.functions.len + 1) catch unreachable;
            self.functions[self.functions.len - 1] = child;
        },
        inline else => |n| @panic("cannot add child of type " ++ @typeName(@TypeOf(n)) ++ " to a ast.program"),
    }
}
