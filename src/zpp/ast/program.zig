const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const program = @This();

pub const args = struct {};

statements: []ast.node,

pub fn create(allocator: std.mem.Allocator, _: args) *program {
    const self = allocator.create(program) catch unreachable;
    self.statements = &[_]ast.node{};
    return self;
}

pub fn print(self: *const program, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("program {{\n", .{}) catch unreachable;
    for (self.statements) |op| {
        op.print(writer, depth + 1);
    }
    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}

pub fn add(self: *program, allocator: std.mem.Allocator, child: ast.node) void {
    switch (child) {
        .declaration => {
            self.statements = allocator.realloc(self.statements, self.statements.len + 1) catch unreachable;
            self.statements[self.statements.len - 1] = child;
        },
        inline else => |n| @panic("cannot add child of type " ++ @typeName(@TypeOf(n)) ++ " to a ast.program"),
    }
}
