const std = @import("std");

pub const function = @import("./symbol/function.zig");
pub const variable = @import("./symbol/variable.zig");

pub const symbol = union(enum) {
    function: *function,
    variable: *variable,

    pub fn create(comptime T: type, allocator: std.mem.Allocator, args: T.args) symbol {
        return symbol.from(T, T.create(allocator, args));
    }

    pub fn from(comptime T: type, ctx: *T) symbol {
        return switch (T) {
            function => symbol{ .function = ctx },
            variable => symbol{ .variable = ctx },

            else => @compileError("Unknown symbol type " ++ @typeName(T)),
        };
    }
};

// pub const table = struct {
//     allocator: std.mem.Allocator,
//     map: std.StringArrayHashMap(symbol),

//     pub fn create(allocator: std.mem.Allocator) table {}
//     pub fn delete(self: *table) void {}

//     pub fn add(self: *table, comptime T: type, name: []const u8, parameters: T.args) void {
//         self.map.put(name, T.create(self.allocator, parameters)) catch unreachable;
//     }
// };
