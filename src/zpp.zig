const std = @import("std");

const zpp = struct {
    const token = @import("zpp/token.zig");
    const lexer = @import("zpp/lexer.zig");
    const parser = @import("zpp/parser.zig");
    const ast = @import("zpp/ast.zig");

    const pass = struct {
        const print = @import("zpp/pass/print.zig").print;
        const symbols = @import("zpp/pass/symbols.zig");
    };
};

// 4 Mib of memory to store the source code.
var source_memory: [4 * 1024 * 1024]u8 = undefined;
var source_allocator = std.heap.FixedBufferAllocator.init(&source_memory);

// 4 Mib of memory to store the tokens.
var token_memory: [4 * 1024 * 1024]u8 = undefined;
var token_allocator = std.heap.FixedBufferAllocator.init(&token_memory);

// 4 Mib of memory to store the AST nodes.
var ast_memory: [4 * 1024 * 1024]u8 = undefined;
var ast_allocator = std.heap.FixedBufferAllocator.init(&ast_memory);

// 1 Kib of memory to store the global declarations.
var global_item_list_memory: [1 * 1024]u8 = undefined;
var global_item_list_allocator = std.heap.FixedBufferAllocator.init(&global_item_list_memory);

// 4 Mib of memory to store the symbol table.
var symbol_memory: [4 * 1024 * 1024]u8 = undefined;
var symbol_allocator = std.heap.FixedBufferAllocator.init(&symbol_memory);

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

    var parser = zpp.parser.initialize(tokens);
    const top_level_items = parse_all_tokens(ast_allocator.allocator(), &parser);

    for (top_level_items) |item| {
        zpp.pass.print(item);
    }

    // generate symbols table
    const global_stackframe = symbol_allocator.allocator().create(zpp.pass.symbols.table) catch unreachable;
    global_stackframe.parent = global_stackframe;
    global_stackframe.symbols = std.StringHashMap(zpp.pass.symbols.table.symbol).init(symbol_allocator);

    for (top_level_items) |item| {
        zpp.pass.symbols.visit(global_stackframe, item, symbol_allocator);
    }

    {
        std.debug.print("generated {} tokens\n", .{tokens.len});
        std.log.info(" ---- program has been lexed successfully ! ---- ", .{});

        std.debug.print("\n", .{});
        std.log.info("Here are some data:", .{});
        std.log.info("  - Datastructures:", .{});
        std.log.info("    - sizeof(zpp.lexer) = {d}o", .{@sizeOf(zpp.lexer)});
        std.log.info("    - sizeof(zpp.parser) = {d}o", .{@sizeOf(zpp.parser)});

        std.debug.print("\n", .{});
        std.log.info("    - sizeof(zpp.token) = {d}o", .{@sizeOf(zpp.token)});

        std.log.info("    - sizeof(zpp.ast.node) = {d}o", .{@sizeOf(zpp.ast.node)});
        std.log.info("    - sizeof(zpp.ast.node.unary) = {d}o", .{@sizeOf(zpp.ast.unary)});
        std.log.info("    - sizeof(zpp.ast.node.binary) = {d}o", .{@sizeOf(zpp.ast.binary)});
        std.log.info("    - sizeof(zpp.ast.node.call) = {d}o", .{@sizeOf(zpp.ast.call)});
        std.log.info("    - sizeof(zpp.ast.node.block) = {d}o", .{@sizeOf(zpp.ast.block)});
        std.log.info("    - sizeof(zpp.ast.node.conditional_branch) = {d}o", .{@sizeOf(zpp.ast.conditional_branch)});
        std.log.info("    - sizeof(zpp.ast.node.block_branch) = {d}o", .{@sizeOf(zpp.ast.block_branch)});
        std.log.info("    - sizeof(zpp.ast.node.function_return) = {d}o", .{@sizeOf(zpp.ast.function_return)});
        std.log.info("    - sizeof(zpp.ast.node.function) = {d}o", .{@sizeOf(zpp.ast.function)});
        std.log.info("    - sizeof(zpp.ast.node.type) = {d}o", .{@sizeOf(zpp.ast.type)});
        std.log.info("    - sizeof(zpp.ast.node.directive) = {d}o", .{@sizeOf(zpp.ast.directive)});

        std.debug.print("\n", .{});
        std.log.info("  - allocators;", .{});
        std.log.info("    - source: {}o", .{source_allocator.end_index});
        std.log.info("    - token: {}o", .{token_allocator.end_index});
        std.log.info("    - ast: {}o", .{ast_allocator.end_index});

        const character_count = source.len;
        const token_count = tokens.len;
        const ast_node_count = parser.ast_node_count;

        const source_file_size_ko = @as(f64, @floatFromInt(source.len)) / 1000.0;
        const token_size_ko = @as(f64, @floatFromInt(tokens.len * @sizeOf(zpp.token))) / 1000.0;
        const ast_size_ko = (@as(f64, @floatFromInt(parser.ast_node_count * @sizeOf(zpp.ast.node))) + @as(f64, @floatFromInt(parser.ast_function_parameter_node_count * @sizeOf(zpp.ast.function.parameter))) + @as(f64, @floatFromInt(parser.ast_function_return_node_count * @sizeOf(zpp.ast.function.return_type)))) / 1000.0;

        const ratio_token_source_size = token_size_ko / source_file_size_ko;

        std.debug.print("\n", .{});
        std.log.info("  - buffers:", .{});
        std.log.info("    - source: {}Ko, {} characters", .{ source_file_size_ko, character_count });
        std.log.info("    - tokens: {}Ko, {} tokens [source size -> token size x {}]", .{ token_size_ko, token_count, ratio_token_source_size });
        std.log.info("    - ast: {}Ko, {} nodes [source size -> ast size x {}, token size -> ast size {}]", .{ ast_size_ko, ast_node_count, ast_size_ko / source_file_size_ko, ast_size_ko / token_size_ko });
        std.log.info("      - ast.function.parameters: {}", .{parser.ast_function_parameter_node_count});
        std.log.info("      - ast.function.returns: {}", .{parser.ast_function_return_node_count});
    }
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

fn parse_all_tokens(allocator: std.mem.Allocator, parser: *zpp.parser) []*zpp.ast.node {
    const what = global_item_list_allocator.allocator();

    var top_level_items = std.ArrayList(*zpp.ast.node).initCapacity(what, 0) catch unreachable;
    var lookahead = parser.lookahead();
    while (lookahead.k != .eof) : (lookahead = parser.lookahead()) {
        what.resize(top_level_items, top_level_items.len + 1) orelse could_not_parse_all_file();
        top_level_items.append(what, parser.next(allocator)) catch |e| could_not_parse_all_file(e);
    }

    return top_level_items.items;
}

fn could_not_parse_all_file(e: anyerror) noreturn {
    std.log.err("An error has occured parsing file: {}", .{e});
    unreachable;
}
