const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils/printer.zig");

const token = @import("../token.zig");

const integer = @This();

pub const args = token;

context: token,
value: u64,

pub fn create(allocator: std.mem.Allocator, infos: args) *integer {
    const self = allocator.create(integer) catch unreachable;
    self.context = infos;
    self.value = std.fmt.parseInt(u64, infos.content, 10) catch unreachable;
    return self;
}

pub fn print(self: *const integer, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("integer({})\n", .{self.value}) catch unreachable;
}
