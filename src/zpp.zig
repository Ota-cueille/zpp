const std = @import("std");

const zpp = struct {
    const lexer = @import("zpp/lexer.zig");
};

///
/// This function is the entry point of the compiler's CLI.
/// The idea is to create both a CLI and a visual interface to
/// this language at term. I would like this language to be
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
    // TODO: maybe start a REPL or get files as user input in the future
    const source_filepath = "./examples/main.zpp";

    const buffer = read_all_file(std.heap.page_allocator, source_filepath);
    defer std.heap.page_allocator.free(buffer);

    var lexer: zpp.lexer = undefined;
    lexer.initialize(buffer) catch |e| std.log.err("Lexer could not be initialized properly with file `./examples/main.zig`! Error was: {}!", .{e});

    while (lexer.current.kind != .eof) {
        if (lexer.current.kind == .keyword) {
            std.log.info("keyword: {s}", .{lexer.current.content});
        }

        lexer.next() catch {
            std.log.err("Compiler Error at l.{}:c.{} : {s}", .{ lexer.error_context.at.line, lexer.error_context.at.column, lexer.error_context.message });
            return;
        };
    }

    std.log.info(" ---- program has been lexed successfully ! ---- ", .{});
}

fn read_all_file(allocator: std.mem.Allocator, filepath: []const u8) []u8 {
    return std.fs.cwd().readFileAlloc(allocator, filepath, std.math.maxInt(usize)) catch |e| could_not_read_file(e, filepath);
}

fn could_not_read_file(e: anyerror, path: []const u8) noreturn {
    std.log.err("An error has occured reading file {s}: {}\n", .{ path, e });
    unreachable;
}
