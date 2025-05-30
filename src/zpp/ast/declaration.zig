const std = @import("std");
const ast = @import("../ast.zig");
const utils = @import("../../utils.zig");

const token = @import("../token.zig");

const declaration = @This();

pub const args = struct {
    colon: token,
    identifier: ast.identifier,
    optional_type: ?ast.identifier,
    rhs: ?ast.node,
};

colon: token,
identifier: ast.identifier,
optional_type: ?ast.identifier,
rhs: ?ast.node,

pub fn alloc(allocator: std.mem.Allocator, infos: args) *declaration {
    const self = allocator.create(declaration) catch unreachable;
    return self.create(infos);
}

pub fn create(self: *declaration, infos: args) *declaration {
    self.colon = infos.colon;
    self.identifier = infos.identifier;
    self.optional_type = infos.optional_type;
    self.rhs = infos.rhs;
    return self;
}

pub fn print(self: *const declaration, writer: std.io.AnyWriter, depth: u16) void {
    utils.write_tabs(writer, depth, 4);
    writer.print("declaration at l:{}-c:{} {{\n", .{ self.colon.start.line, self.colon.start.column }) catch unreachable;

    self.identifier.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    if (self.optional_type) |T| {
        writer.print("type is {s}\n", .{T.name}) catch unreachable;
    } else {
        writer.print("type is inferred\n", .{}) catch unreachable;
    }

    if (self.rhs) |sub_expression| sub_expression.print(writer, depth + 1);

    utils.write_tabs(writer, depth, 4);
    writer.print("}}\n", .{}) catch unreachable;
}
