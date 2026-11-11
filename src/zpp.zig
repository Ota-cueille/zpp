const std = @import("std");

// 4 Mo of memory to store the source code.
var source_memory: [4 * 1024 * 1024]u8 = undefined;
var source_allocator = std.heap.FixedBufferAllocator.init(&source_memory);

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

    // Compiler Context
    const source = read_all_file(source_allocator.allocator(), source_filepath);

    std.debug.print("source code:\n{s}\n", .{source});
}

fn read_all_file(allocator: std.mem.Allocator, filepath: []const u8) []u8 {
    return std.fs.cwd().readFileAlloc(filepath, allocator, std.Io.Limit.unlimited) catch |e| could_not_read_file(e, filepath);
}

fn could_not_read_file(e: anyerror, path: []const u8) noreturn {
    std.log.err("An error has occured reading file {s}: {}", .{ path, e });
    unreachable;
}
