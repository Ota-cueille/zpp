const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const character = @This();

pub const args = token;

context: token,
// NODE: unicode would be best here
value: u8,

pub fn create(allocator: std.mem.Allocator, infos: args) *character {
    const self = allocator.create(character) catch unreachable;
    self.context = infos;
    self.value = infos.content[1];
    return self;
}

pub fn print(self: *const character, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("character('{c}')", .{self.value}) catch unreachable;
}
