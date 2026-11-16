const std = @import("std");
const ast = @import("../ast.zig");

var accumulator_buffer: [1 * 1024 * 1024]u8 = undefined;
var accumulator_allocator = std.heap.FixedBufferAllocator.init(&accumulator_buffer);

pub fn print(root: *const ast.node) void {
    accumulator_allocator.reset();
    print_node(root, 0, true);
}

// branch printing helper
fn print_tree(depth: usize, last: bool) void {
    std.debug.print("{s}", .{accumulator_buffer[0 .. depth * 4]});
    std.debug.print("{s}", .{if (last) "`-- " else "|-- "});

    const tree = accumulator_allocator.allocator().alloc(u8, 4) catch unreachable;
    if (last) {
        std.mem.copyForwards(u8, tree, "    ");
    } else {
        std.mem.copyForwards(u8, tree, "|   ");
    }
}

// recursive print function for ast.node
fn print_node(n: *const ast.node, depth: usize, last: bool) void {
    switch (n.*) {
        .literal => |tok| {
            print_tree(depth, last);
            std.debug.print("literal({s})\n", .{tok.content});
        },
        .identifier => |tok| {
            print_tree(depth, last);
            std.debug.print("identifier({s})\n", .{tok.content});
        },
        .unary => |*un| {
            print_tree(depth, last);
            std.debug.print("unary({s})\n", .{un.operator.content});
            print_node(un.value, depth + 1, true);
        },
        .binary => |*bin| {
            print_tree(depth, last);
            std.debug.print("binary({s})\n", .{bin.operator.content});
            print_node(bin.lhs, depth + 1, false);
            print_node(bin.rhs, depth + 1, true);
        },
        .call => |*c| {
            print_tree(depth, last);
            std.debug.print("call of {s}\n", .{c.callee.content});
            for (c.arguments, 0..) |arg, i| {
                print_node(arg, depth + 1, i == c.arguments.len - 1);
            }
        },
        .block => |*b| {
            print_tree(depth, last);
            std.debug.print("block ({} statements)\n", .{b.statements.len});
            for (b.statements, 0..) |stmt, i| {
                print_node(stmt, depth + 1, i == b.statements.len - 1);
            }
        },
        .conditional_branch => |*cb| {
            print_tree(depth, last);
            std.debug.print("if\n", .{});
            print_node(cb.condition, depth + 1, false);
            print_node(cb.tbody, depth + 1, cb.fbody == null);
            if (cb.fbody) |fb| {
                print_node(fb, depth + 1, true);
            }
        },
        .block_branch => |*bb| {
            print_tree(depth, last);
            std.debug.print("{s}\n", .{bb.keyword.content});
            if (bb.value) |val| {
                print_node(val, depth + 1, true);
            }
        },
        .function_return => |*ret| {
            print_tree(depth, last);
            std.debug.print("return\n", .{});
            if (ret.value) |val| {
                print_node(val, depth + 1, true);
            }
        },
        .loop => |*l| {
            print_tree(depth, last);
            std.debug.print("loop\n", .{});
            print_node(l.iterator, depth + 1, last);
            print_node(l.body, depth + 1, true);
        },
        .function => |*f| {
            print_tree(depth, last);
            std.debug.print("function\n", .{});
            print_node(f.body, depth + 1, true);
        },
        .type => |*t| {
            print_tree(depth, last);
            std.debug.print("type declaration\n", .{});
            for (t.content, 0..) |item, i| {
                print_node(item, depth + 1, i == t.content.len - 1);
            }
        },
        .directive => |*dir| {
            print_tree(depth, last);
            std.debug.print("directive({s})\n", .{dir.name.content});
            if (dir.payload) |p| {
                print_node(p, depth + 1, true);
            }
        },
    }
}
