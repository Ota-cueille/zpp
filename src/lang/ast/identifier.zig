const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils/printer.zig");

const token = @import("../token.zig");

const identifier = @This();

pub const args = token;

context: token,
name: []const u8,

pub fn create(allocator: std.mem.Allocator, infos: args) *identifier {
    const self = allocator.create(identifier) catch unreachable;
    self.context = infos;
    self.name = infos.content;
    return self;
}

pub fn print(self: *const identifier, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("identifier: {s}\n", .{self.name}) catch unreachable;
}
