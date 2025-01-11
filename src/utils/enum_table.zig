const std = @import("std");

pub fn enum_table(E: type) type {
    const enum_infos = @typeInfo(E).Enum;
    return struct {
        const hash_table = init: {
            var kv_pairs: [enum_infos.fields.len]struct { []const u8, enum_infos.tag_type } = undefined;

            for (enum_infos.fields, kv_pairs[0..]) |field, *kv| {
                kv.*.@"0" = field.name;
                kv.*.@"1" = field.value;
            }

            break :init std.StaticStringMap(enum_infos.tag_type).initComptime(kv_pairs);
        };

        pub fn get(word: []const u8) ?E {
            return if (hash_table.get(word)) |value| @enumFromInt(value) else null;
        }
    };
}
