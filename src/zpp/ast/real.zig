const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const real = @This();

pub const args = token;

context: token,
value: f64,

pub fn alloc(allocator: std.mem.Allocator, infos: args) *real {
    const self = allocator.create(real) catch unreachable;
    return self.create(infos);
}

pub fn create(self: *real, infos: args) *real {
    self.context = infos;
    self.value = std.fmt.parseFloat(f64, infos.content) catch unreachable;

    return self;
}

pub fn print(self: *const real, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("real({d})\n", .{self.value}) catch unreachable;
}
