const std = @import("std");

pub fn encode(str: []const u8, comptime bytes: u8) std.meta.Int(.unsigned, bytes * 8) {
    if (str.len > bytes) @panic("Symbol too long for encoding");

    const IntegerType = std.meta.Int(.unsigned, bytes * 8);
    var res: IntegerType = 0;
    inline for (0..bytes) |i| {
        res |= @as(IntegerType, str[i]) << (i * 8);
    }
    return res;
}

pub fn enumhash(E: type) type {
    const infos = @typeInfo(E).Enum;

    return struct {
        const context_t = struct { max_length: usize, table: std.StaticStringMap(infos.tag_type) };

        const context: context_t = init: {
            var kvs: [infos.fields.len]struct { []const u8, infos.tag_type } = undefined;
            var max_length = 0;

            for (infos.fields, kvs[0..]) |field, *kv| {
                kv.*.@"0" = field.name;
                kv.*.@"1" = field.value;

                max_length = if (field.name.len > max_length) field.name.len else max_length;
            }

            break :init .{ .max_length = max_length, .table = std.StaticStringMap(infos.tag_type).initComptime(kvs) };
        };

        pub fn get(word: []const u8) ?E {
            if (word.len > context.max_length) return null;
            return if (context.table.get(word)) |value| @enumFromInt(value) else null;
        }
    };
}
