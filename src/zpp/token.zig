const token = @This();

pub const kind = enum(u64) {
    symbol,
    // ::
    // (
    // )
    // {
    // }
    // ,

    // label which holds information : variable, function, type, keyword, operator, ...
    identifier,

    // literals
    integer_literal,

    eof,
};

pub const location = struct {
    offset: u32 = 0,
    line: u32 = 0,
    column: u32 = 0,
};

kind: kind,
start: location,
end: location,
content: []const u8,

pub fn create(content: []const u8, k: kind, start: location, end: location) token {
    var self: token = undefined;

    self.kind = k;
    self.start = start;
    self.end = end;
    self.content = content;

    return self;
}
