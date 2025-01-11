const std = @import("std");

pub fn write_tabs(writer: std.io.AnyWriter, depth: u16, comptime indentation_size: u3) void {
    const tab = init: {
        var buffer: [indentation_size]u8 = undefined;
        for (&buffer) |*c| {
            c.* = ' ';
        }
        break :init @as([]const u8, &buffer);
    };

    for (0..depth) |_| {
        writer.print("{s}", .{tab}) catch unreachable;
    }
}
