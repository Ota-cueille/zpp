const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const parameter = @This();

pub const args = struct {
    colon: token,
    identifier: token,
    type: token,
};

colon: token,
identifier: ast.identifier,
type: ast.identifier,

pub fn create(self: *parameter, infos: args) *parameter {
    self.colon = infos.colon;

    // use initializer in place
    _ = self.identifier.create(infos.identifier);
    _ = self.type.create(infos.type);

    return self;
}

pub fn alloc(allocator: std.mem.Allocator, infos: args) *parameter {
    const self = allocator.create(parameter) catch unreachable;
    return self.create(infos);
}

pub fn print(self: *const parameter, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("parameter ({s}): {s}\n", .{ self.type.name, self.identifier.name }) catch unreachable;
}
