const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const binary_operator = @This();

pub const args = struct {
    operator: token,
    lhs: ast.node,
    rhs: ast.node,
};

operator: token,
lhs: ast.node,
rhs: ast.node,

pub fn create(allocator: std.mem.Allocator, infos: args) *binary_operator {
    const self = allocator.create(binary_operator) catch unreachable;
    self.colon = infos.operator;
    self.identifier = infos.lhs;
    self.rhs = infos.rhs;
    return self;
}

pub fn print(self: *const binary_operator, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("binary operator ({s}) {{\n", .{self.operator.content}) catch unreachable;

    self.lhs.print(writer, depth + 1);
    self.rhs.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
