const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const call = @This();

pub const args = struct {
    identifier: token,
    arguments: []ast.node,
};

function: ast.identifier,
arguments: []ast.node,

pub fn create(self: *call, infos: args) *call {
    self.function.create(infos.identifier);
    self.arguments = infos.arguments;
    return self;
}

pub fn alloc(allocator: std.mem.Allocator, infos: args) *call {
    const self = allocator.create(call) catch unreachable;
    return self.create(infos);
}

pub fn print(self: *const call, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("function call {s} {{\n", .{self.function.name}) catch unreachable;

    for (self.arguments) |argument| {
        argument.print(writer, depth + 1);
    }

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
