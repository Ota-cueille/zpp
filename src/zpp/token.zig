const token = @This();

// tokens are for lexical analysis
// behaviour is for sementic analysis
pub const kind = enum(u64) {
    symbol,

    // open and close
    // ()
    // []
    // {}
    // maybe || ..
    // maybe <> ??

    // punctuation
    // ,
    // ;
    // :

    // operators
    // .
    // maybe @
    // maybe &
    // maybe #

    // memory operators
    // =
    // +=
    // -=
    // *=
    // /=

    // mathematical operators
    // -
    // +
    // *
    // /

    // logical operators
    // ||
    // &&
    // !
    // ==
    // !=
    // <
    // >=
    // >
    // <=

    // compile time known values
    literal,

    literal_character, // 'u', '😊', '\uE45F'
    literal_integer, // 1, 2, 456
    literal_real, // 1., .0, 1.645, 2454.9
    literal_string, // "content"

    // label which holds information : variable, function, type, keyword, operator, ...
    identifier,

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
