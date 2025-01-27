const std = @import("std");
const lexer = @import("zpp/lexer.zig");

test lexer {
    const allocator = std.testing.allocator;

    const cwd = std.fs.cwd();
    const examples = try cwd.openDir("./examples", .{});

    const it = examples.iterate();

    while (try it.next()) |entry| {
        // asume any file in this directory is a source file
        if (entry.kind != .file) continue;

        const l = lexer.initialize(buffer);

        for (0..100) |i| {
            const tok = l.next();

            std.debug.print("-- token[{}] --\n", .{i});
            pretty.print(allocator, tok, .{ .tab_size = 3, .inline_mode = false }) catch |err| {
                std.log.err("An error has occured pretty printing token: {}\n", .{err});
                unreachable;
            };

            if (tok.kind == .eof) break;
        }
    }
}
