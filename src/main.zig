const std = @import("std");

const pretty = @import("ext/pretty.zig");

const lexer = @import("lang/lexer.zig");
const parser = @import("lang/parser.zig");
const ast = @import("lang/ast.zig");

pub fn main() void {
    const source_filepath = "./examples/expressions.l";

    const buffer = read_all_file(std.heap.page_allocator, source_filepath);
    defer std.heap.page_allocator.free(buffer);

    // AST nodes allocator
    var ast_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ast_arena.deinit();

    var l: lexer = lexer.initialize(buffer);
    const root = parser.parse(ast_arena.allocator(), &l);

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
