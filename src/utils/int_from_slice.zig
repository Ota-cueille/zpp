const std = @import("std");

pub fn convert(comptime T: type, slice: []const u8) T {
    const infos = @typeInfo(T);
    std.debug.assert(infos == .Int and infos.Int.signedness == .unsigned and slice.len <= @sizeOf(T));

    var result: T = 0;

    for (slice, 0..) |byte, offset| {
        result |= (@as(T, @intCast(byte)) << @truncate(offset * 8));
    }

    return result;
}
