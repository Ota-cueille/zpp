const std = @import("std");

const pretty = @import("ext/pretty.zig");

const zpp = @import("zpp.zig");

pub fn main() void {
    const source_filepath = "./examples/all.zpp";

    const buffer = read_all_file(std.heap.page_allocator, source_filepath);
    defer std.heap.page_allocator.free(buffer);

    // AST nodes allocator
    var ast_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ast_arena.deinit();

    var lexer: zpp.lexer = zpp.lexer.initialize(buffer);
    var parser: zpp.parser = zpp.parser.initialize(std.heap.page_allocator, &lexer);
    const root = parser.parse(ast_arena.allocator());

    std.log.info("program has been parsed successfully !", .{});

    var stdout = std.io.getStdOut();
    const writer = stdout.writer();
    root.print(writer.any(), 0);
}

fn read_all_file(allocator: std.mem.Allocator, filepath: []const u8) []u8 {
    return std.fs.cwd().readFileAlloc(allocator, filepath, std.math.maxInt(usize)) catch |err| could_not_read_file(err, filepath);
}

fn could_not_read_file(err: anyerror, path: []const u8) noreturn {
    std.log.err("An error has occured reading file {s}: {}\n", .{ path, err });
    unreachable;
}
