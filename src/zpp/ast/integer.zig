const std = @import("std");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const integer = @This();

value: u64,

pub fn create(self: *integer, literal: token) *integer {
    self.value = std.fmt.parseInt(u64, literal.content, 10) catch unreachable;
    return self;
}

pub fn alloc(allocator: std.mem.Allocator, literal: token) *integer {
    const self = allocator.create(literal) catch unreachable;
    return self.create(literal);
}

pub fn print(self: *const integer, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("integer({})\n", .{self.value});
}
