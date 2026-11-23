const std = @import("std");
const ast = @import("../ast.zig");

var accumulator_buffer: [1 * 1024 * 1024]u8 = undefined;
var accumulator_index: usize = 0;

pub fn print(root: *const ast.node) void {
    print_node(root, true);
}

// branch printing helper
fn push_tree(last: bool) void {
    std.debug.assert(accumulator_index * 4 < accumulator_buffer.len);

    accumulator_buffer[accumulator_index * 4 + 0] = if (last) ' ' else '|';
    accumulator_buffer[accumulator_index * 4 + 1] = ' ';
    accumulator_buffer[accumulator_index * 4 + 2] = ' ';
    accumulator_buffer[accumulator_index * 4 + 3] = ' ';

    accumulator_index += 1;
}

fn pop_tree() void {
    std.debug.assert(accumulator_index > 0);
    accumulator_index -= 1;
}

fn print_tree(last: bool) void {
    std.debug.print("{s}", .{accumulator_buffer[0 .. accumulator_index * 4]});
    if (last) {
        std.debug.print("`-- ", .{});
    } else {
        std.debug.print("|-- ", .{});
    }
}

// recursive print function for ast.node
fn print_node(n: *const ast.node, last: bool) void {
    print_tree(last);

    push_tree(last);
    switch (n.*) {
        .literal => |tok| {
            std.debug.print("literal({s})\n", .{tok.content});
        },
        .identifier => |tok| {
            std.debug.print("identifier({s})\n", .{tok.content});
        },
        .unary => |*un| {
            std.debug.print("unary({s})\n", .{un.operator.content});

            print_node(un.value, true);
        },
        .binary => |*bin| {
            std.debug.print("binary({s})\n", .{bin.operator.content});

            print_node(bin.lhs, false);
            print_node(bin.rhs, true);
        },
        .call => |*c| {
            std.debug.print("call of {s}\n", .{c.callee.content});

            for (c.arguments, 0..) |arg, i| {
                print_node(arg, i == c.arguments.len - 1);
            }
        },
        .block => |*b| {
            std.debug.print("block ({} statements)\n", .{b.statements.len});

            for (b.statements, 0..) |stmt, i| {
                print_node(stmt, i == b.statements.len - 1);
            }
        },
        .conditional_branch => |*cb| {
            std.debug.print("if\n", .{});

            print_node(cb.condition, false);
            print_node(cb.tbody, cb.fbody == null);

            if (cb.fbody) |fb| {
                print_node(fb, true);
            }
        },
        .block_branch => |*bb| {
            std.debug.print("{s}\n", .{bb.keyword.content});

            if (bb.value) |val| {
                print_node(val, true);
            }
        },
        .function_return => |*ret| {
            std.debug.print("return\n", .{});

            if (ret.value) |val| {
                print_node(val, true);
            }
        },
        .loop => |*l| {
            std.debug.print("loop\n", .{});

            print_node(l.iterator, false);
            print_node(l.body, true);
        },
        .function => |*f| {
            std.debug.print("function\n", .{});

            print_node(f.body, true);
        },
        .type => |*t| {
            std.debug.print("type declaration\n", .{});

            for (t.content, 0..) |item, i| {
                print_node(item, i == t.content.len - 1);
            }
        },
        .directive => |*dir| {
            std.debug.print("directive({s})\n", .{dir.name.content});

            if (dir.payload) |p| {
                print_node(p, true);
            }
        },
    }
    pop_tree();
}
