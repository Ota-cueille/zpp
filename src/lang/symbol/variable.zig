const std = @import("std");

const variable = @This();

const args = []const u8;

name: []const u8,
// declaration: ast.node

pub fn create(allocator: std.mem.Allocator, name: args) *variable {
    const self = allocator.create(variable) catch unreachable;
    self.name = name;
    return self;
}
