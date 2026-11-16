const std = @import("std");

const zpp = struct {
    const token = @import("zpp/token.zig");
    const lexer = @import("zpp/lexer.zig");
};

// 4 Mo of memory to store the source code.
var source_memory: [4 * 1024 * 1024]u8 = undefined;
var source_allocator = std.heap.FixedBufferAllocator.init(&source_memory);

// 4 Mo of memory to store the tokens.
var token_memory: [4 * 1024 * 1024]u8 = undefined;
var token_allocator = std.heap.FixedBufferAllocator.init(&token_memory);

///
/// This function is the entry point of the compiler's CLI.
/// The idea is to create both a CLI and a visual interface to
/// this language in the end. I would like this language to be
/// compiled, systems oriented, ~low~ level, simple and expressive
///
/// What I mean by ~low~ level is that the languages construct are
/// simple to reason about and the outputed asm is well defined.
/// That way the developper knows the outcome of theirs program.
///
/// But because I also want the language to be expressive, it will
/// be possible to describe complex constructs and even DSL inside
/// the language itself to allow for higher level constructs.
///
pub fn main() void {
    // todo(ota): maybe start a REPL or get files as user input in the future
    const source_filepath = "./examples/main.zpp";

    const source = read_all_file(source_allocator.allocator(), source_filepath);

    // Compiler Initialization
    var lexer = zpp.lexer.initialize(source);
    const tokens = lex_all_source(token_allocator.allocator(), &lexer);

    std.debug.print("generated {} tokens\n", .{tokens.len});
    std.log.info(" ---- program has been lexed successfully ! ---- ", .{});

    std.debug.print("\n", .{});
    std.log.info("Here are some data:", .{});
    std.log.info("  - Datastructures:", .{});
    std.log.info("    - sizeof(zpp.lexer) = {d}o", .{@sizeOf(zpp.lexer)});

    std.debug.print("\n", .{});
    std.log.info("    - sizeof(zpp.token) = {d}o", .{@sizeOf(zpp.token)});

    std.debug.print("\n", .{});
    std.log.info("  - allocators;", .{});
    std.log.info("    - source: {}o", .{source_allocator.end_index});
    std.log.info("    - token: {}o", .{token_allocator.end_index});
}

fn read_all_file(allocator: std.mem.Allocator, filepath: []const u8) []u8 {
    return std.fs.cwd().readFileAlloc(filepath, allocator, std.Io.Limit.unlimited) catch |e| could_not_read_file(e, filepath);
}

fn could_not_read_file(e: anyerror, path: []const u8) noreturn {
    std.log.err("An error has occured reading file {s}: {}", .{ path, e });
    unreachable;
}

fn lex_all_source(allocator: std.mem.Allocator, lexer: *zpp.lexer) []zpp.token {
    // magic number base on the metrics at the end of main to preallocate about enough
    // to hopefully, not reallocate later when resizing
    // const base_capacity: usize = @intFromFloat(0.3 * @as(f64, @floatFromInt(lexer.source.len)));

    var current = lexer.next();
    var tokens = std.ArrayList(zpp.token).initCapacity(allocator, 0) catch unreachable;

    while (current.k != .eof) : (current = lexer.next()) {
        tokens.append(allocator, current) catch |e| could_not_lex_all_file(e);
    }

    tokens.append(allocator, lexer.next()) catch |e| could_not_lex_all_file(e);

    return tokens.items;
}

fn could_not_lex_all_file(e: anyerror) noreturn {
    std.log.err("An error has occured lexing file: {}", .{e});
    unreachable;
}
