const std = @import("std");

const function = @This();

const args = []const u8;

name: []const u8,
// signature: *ast.function

pub fn create(allocator: std.mem.Allocator, name: args) *function {
    const self = allocator.create(function) catch unreachable;
    self.name = name;
    return self;
}
