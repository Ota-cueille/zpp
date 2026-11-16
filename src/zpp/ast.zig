const std = @import("std");

const token = @import("token.zig");

pub const unary = struct {
    operator: *token,
    value: *node,
};

pub const binary = struct {
    operator: *token,
    lhs: *node,
    rhs: *node,
};

pub const call = struct {
    callee: *token,
    arguments: []*node,
};

pub const block = struct {
    statements: []*node,
};

pub const conditional_branch = struct {
    condition: *node,
    tbody: *node,
    fbody: ?*node,
};

pub const block_branch = struct {
    keyword: *token,
    value: ?*node,
};

pub const loop = struct {
    iterator: *node,
    body: *node,
};

pub const function_return = struct {
    value: ?*node,
};

pub const function = struct {
    pub const parameter = struct {
        name: *token,
        type: *node,
    };

    pub const return_type = struct {
        name: ?*token,
        type: *node,
    };

    parameters: []parameter,
    returns: []return_type,
    body: *node,
};

pub const @"type" = struct {
    keyword: *token, // struct, enum, union, etc
    content: []*node,
};

pub const directive = struct {
    name: *token,
    payload: ?*node,
};

pub const node = union(enum) {
    // terminals
    literal: *token,
    identifier: *token,

    // operations
    unary: unary,
    binary: binary,
    call: call,

    // control flow
    block: block,
    conditional_branch: conditional_branch, // ifs
    block_branch: block_branch, // breaks and continues
    function_return: function_return, // returns
    loop: loop,

    // declarations
    function: function,
    type: @"type",

    // directives
    directive: directive,
};
