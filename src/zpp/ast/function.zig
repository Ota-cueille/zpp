const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const function = @This();

pub const args = struct {
    identifier: token,
    return_type: token,
    parameters: []ast.parameter,
    body: []ast.node,
};

identifier: ast.identifier,
return_type: ast.identifier,
parameters: []ast.parameter,
body: []ast.node,

pub fn create(self: *function, infos: args) *function {
    _ = self.identifier.create(infos.identifier);
    _ = self.return_type.create(infos.return_type);
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

    utils.write_tabs(writer, depth + 1, 4);
    switch (self.parameters.len) {
        0 => writer.print("signature: () -> {s}\n", .{self.return_type.name}) catch unreachable,
        else => |n| {
            writer.print("signature: (", .{}) catch unreachable;
            for (0..n - 1) |i| {
                writer.print("{s}: {s}, ", .{ self.parameters[i].identifier.name, self.parameters[i].type.name }) catch unreachable;
            }
            writer.print("{s}: {s}) -> {s}\n", .{
                self.parameters[n - 1].identifier.name,
                self.parameters[n - 1].type.name,
                self.return_type.name,
            }) catch unreachable;
        },
    }

    if (self.body.len != 0) {
        writer.print("\n", .{}) catch unreachable;

        for (self.body) |expression| {
            expression.print(writer, depth + 1);
        }
    }

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
