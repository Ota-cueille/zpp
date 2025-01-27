const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils/printer.zig");

const token = @import("../token.zig");

const declaration = @This();

pub const args = struct {
    colon: token,
    identifier: ast.identifier,
    optional_type: ?ast.node,
    rhs: ?ast.node,
};

colon: token,
identifier: ast.identifier,
optional_type: ?ast.node, 
rhs: ?ast.node,

pub fn create(allocator: std.mem.Allocator, infos: args) *declaration {
    const self = allocator.create(declaration) catch unreachable;
    self.colon = infos.colon;
    self.identifier = infos.identifier;
    self.optional_type = infos.optional_type;
    self.rhs = infos.rhs;
    return self;
}

pub fn print(self: *const declaration, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("binary operator ({s}) {{\n", .{self.colon.content}) catch unreachable;

    self.identifier.print(writer, depth + 1);
    self.rhs.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
