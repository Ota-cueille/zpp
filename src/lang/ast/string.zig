const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils/printer.zig");

const token = @import("../token.zig");

const string = @This();

pub const args = token;

context: token,
value: []const u8,

pub fn create(allocator: std.mem.Allocator, infos: args) *string {
    const self = allocator.create(string) catch unreachable;
    self.context = infos;
    self.value = infos.content;
    return self;
}

pub fn print(self: *const string, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("string(\"{s}\")", .{self.value}) catch unreachable;
}
