const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils/printer.zig");

const token = @import("../token.zig");

const assignment = @This();

pub const args = struct {
    operator: token,
    lhs: ast.node,
    rhs: ast.node,
};

operator: token,
lhs: ast.node,
rhs: ast.node,

pub fn create(allocator: std.mem.Allocator, infos: args) *assignment {
    const self = allocator.create(assignment) catch unreachable;
    self.operator = infos.operator;
    self.lhs = infos.lhs;
    self.rhs = infos.rhs;
    return self;
}

pub fn print(self: *const assignment, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("binary operator ({s}) {{\n", .{self.operator.content}) catch unreachable;

    self.lhs.print(writer, depth + 1);
    self.rhs.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
