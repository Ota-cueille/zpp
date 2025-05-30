const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const function = @This();

pub const args = struct {
    identifier: token,
    parameters: []ast.parameter,
    body: []ast.node,
};

identifier: ast.identifier,
parameters: []ast.parameter,
body: []ast.node,

pub fn create(self: *function, infos: args) *function {
    _ = self.identifier.create(infos.identifier);
    self.parameters = infos.parameters;
    self.body = infos.body;
    return self;
}

pub fn alloc(allocator: std.mem.Allocator, infos: args) *function {
    const self = allocator.create(function) catch unreachable;
    return self.create(infos);
}

pub fn print(self: *const function, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("function {s} {{\n", .{self.identifier.name}) catch unreachable;

    for (self.parameters) |*parameter| {
        parameter.print(writer, depth + 1);
    }

    writer.print("\n", .{}) catch unreachable;

    for (self.body) |expression| {
        expression.print(writer, depth + 1);
    }

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
