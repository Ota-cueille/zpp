const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const unary_operator = @This();

pub const args = struct {
    operator: token,
    expression: ast.node,
};

operator: token,
expression: ast.node,

pub fn create(self: *unary_operator, infos: args) *unary_operator {
    self.operator = infos.operator;
    self.expression = infos.expression;
    return self;
}

pub fn alloc(allocator: std.mem.Allocator, infos: args) *unary_operator {
    const self = allocator.create(unary_operator) catch unreachable;
    return self.create(infos);
}

pub fn print(self: *const unary_operator, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("unary ({s}) {{\n", .{self.operator.content}) catch unreachable;

    self.expression.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
