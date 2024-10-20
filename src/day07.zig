const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub fn main() !void {
    try stdout.print("Advent of Code 2024, Day 7\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input07.txt", .{});
    defer file.close();

    var scanner = Scanner{ .file = &file };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();
    try scanner.scan_tokens(&tokens);

    var h = std.StringHashMap(i32).init(allocator); // TODO: values should be instructions
    defer {
        var it = h.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        h.deinit();
    }

    try construct_hash_map(&tokens, &h, &allocator);

    try stdout.print("** Brightness: {d}\n", .{10});

    try bw.flush();
}

pub fn is_binary_operator(token_type: TokenType) bool {
    if (token_type == TokenType.AND) {
        return true;
    }
    if (token_type == TokenType.OR) {
        return true;
    }
    if (token_type == TokenType.LSHIFT) {
        return true;
    }
    if (token_type == TokenType.RSHIFT) {
        return true;
    }
    return false;
}

const TokenType = enum { AND, OR, NOT, LSHIFT, RSHIFT, Signal, ARROW, Name, NewLine, EOF };

const Token = struct {
    token_type: TokenType,
    literal: u32,
    literal_s: [10]u8 = @as([10]u8, undefined),
    line: u32,

    pub fn add_name(self: *Token, buffer: []u8, buffer_len: u32) void {
        std.mem.copyForwards(u8, &self.literal_s, buffer[0..buffer_len]);
    }
};

const Scanner = struct {
    file: *std.fs.File,
    peek_byte: u8 = '0',
    peeked: bool = false,
    param_buffer: [10]u8 = @as([10]u8, undefined),
    param_buffer_len: u32 = 0,

    pub fn scan_tokens(self: *Scanner, arr: *std.ArrayList(Token)) !void {
        var line: u32 = 1;

        while (true) {
            const byte = self.read() catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            if (byte == '\n') {
                try arr.append(Token{ .token_type = TokenType.NewLine, .literal = 0, .line = line });
                line += 1;
            } else if (byte == '-') {
                const next_byte = try self.peek();
                if (next_byte == '>') {
                    try arr.append(Token{ .token_type = TokenType.ARROW, .literal = 0, .line = line });
                    self.advance();
                } else {
                    std.debug.print("Unknown token {c}{c} found at line {d}\n", .{ byte, next_byte, line });
                }
            } else if (is_digit(byte)) {
                const num = try self.read_number(byte);
                try arr.append(Token{ .token_type = TokenType.Signal, .literal = num, .line = line });
            } else if (is_big_alpha(byte)) {
                const token_type = try self.read_instruction(byte, line);
                try arr.append(Token{ .token_type = token_type, .literal = 0, .line = line });
            } else if (is_alpha(byte)) {
                try self.read_name(byte);
                var token = Token{ .token_type = TokenType.Name, .literal = 0, .line = line };
                token.add_name(&self.param_buffer, self.param_buffer_len);
                try arr.append(token);
            } else if (byte != ' ') {
                std.debug.print("Unknown character {c} found at line {d}\n", .{ byte, line });
                return error.UnknownCharacter;
            }
        }
        try arr.append(Token{ .token_type = TokenType.EOF, .literal = 0, .line = line });
    }

    fn read(self: *Scanner) !u8 {
        if (self.peeked) {
            self.peeked = false;
            return self.peek_byte;
        }
        return self.file.reader().readByte();
    }

    fn peek(self: *Scanner) !u8 {
        if (self.peeked) {
            std.debug.panic("Cannot peek two times!", .{});
        }
        self.peek_byte = self.file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => return 26,
            else => return err,
        };
        self.peeked = true;
        return self.peek_byte;
    }

    fn advance(self: *Scanner) void {
        self.peeked = false;
    }

    fn read_number(self: *Scanner, byte: u8) !u32 {
        var num: u32 = @as(u32, byte - '0');
        while (true) {
            const new_byte = try self.peek();
            if (is_digit(new_byte)) {
                num *= 10;
                num += @as(u32, new_byte - '0');
                self.advance();
            } else {
                break;
            }
        }
        return num;
    }

    fn read_instruction(self: *Scanner, byte: u8, line: u32) !TokenType {
        self.param_buffer_len = 0;
        self.param_buffer[self.param_buffer_len] = byte;
        self.param_buffer_len += 1;

        while (true) {
            const new_byte = try self.peek();
            if (is_big_alpha(new_byte)) {
                self.param_buffer[self.param_buffer_len] = new_byte;
                self.param_buffer_len += 1;
                self.advance();
            } else {
                break;
            }
        }
        const param_slice = self.param_buffer[0..self.param_buffer_len];
        if (std.mem.eql(u8, param_slice, "AND")) {
            return TokenType.AND;
        }
        if (std.mem.eql(u8, param_slice, "OR")) {
            return TokenType.OR;
        }
        if (std.mem.eql(u8, param_slice, "NOT")) {
            return TokenType.NOT;
        }
        if (std.mem.eql(u8, param_slice, "LSHIFT")) {
            return TokenType.LSHIFT;
        }
        if (std.mem.eql(u8, param_slice, "RSHIFT")) {
            return TokenType.RSHIFT;
        }

        std.debug.print("Unknown identifier {s} found at line {d}\n", .{ param_slice, line });
        return error.UnknownToken;
    }

    fn read_name(self: *Scanner, byte: u8) !void {
        self.param_buffer_len = 0;
        self.param_buffer[self.param_buffer_len] = byte;
        self.param_buffer_len += 1;

        while (true) {
            const new_byte = try self.peek();
            if (is_alpha(new_byte)) {
                self.param_buffer[self.param_buffer_len] = new_byte;
                self.param_buffer_len += 1;
                self.advance();
            } else {
                break;
            }
        }
    }
};

pub fn is_digit(byte: u8) bool {
    return byte >= '0' and byte <= '9';
}

pub fn is_alpha(byte: u8) bool {
    return byte >= 'a' and byte <= 'z';
}

pub fn is_big_alpha(byte: u8) bool {
    return byte >= 'A' and byte <= 'Z';
}

fn min(a: u32, b: u32) u32 {
    return if (a < b) a else b;
}

fn max(a: u32, b: u32) u32 {
    return if (a > b) a else b;
}

const Operator = enum { AND, OR, NOT, LSHIFT, RSHIFT, NOOP };
const Operation = struct {
    op_type: Operator,
    value1: ?u32,
    value2: ?u32,
    identifier1: ?*const u8,
    identifier2: ?*const u8,

    pub fn is_unary(self: *const Operation) bool {
        return self.right == null;
    }
};

fn construct_hash_map(tokens: *std.ArrayList(Token), h: *std.StringHashMap(i32), allocator: *const std.mem.Allocator) !void {
    var group: u8 = 0;
    var arity: u8 = 0;
    var err: bool = false;

    for (tokens.items) |token| {
        if (token.token_type == TokenType.EOF) {
            break;
        }
        if (token.token_type == TokenType.NewLine) {
            if (group != 3) {
                try stdout.print("Error", .{});
            }
            try stdout.print("\n", .{});
            group = 0;
            arity = 0;
            err = false;
            continue;
        }

        if (err) {
            continue;
        }
        if (group == 1) {
            if (token.token_type == TokenType.ARROW) {
                group += 1;
                try stdout.print("->", .{});
            } else {
                try stdout.print("Error", .{});
                err = true;
            }
        } else if (group == 2) {
            if (token.token_type == TokenType.Name) {
                group += 1;
                const key_copy: []u8 = try allocator.alloc(u8, 10);
                std.mem.copyForwards(u8, key_copy, token.literal_s[0..10]);
                try stdout.print("{s}", .{token.literal_s});
                try h.put(key_copy, 8);
            } else {
                try stdout.print("Error", .{});
                err = true;
            }
        } else if (group == 0) {
            if (arity == 0) { // not set
                if (token.token_type == TokenType.NOT) {
                    arity = 1;
                    try stdout.print("~", .{});
                } else if (token.token_type == TokenType.Signal) {
                    arity = 2;
                    try stdout.print("{d}", .{token.literal});
                } else if (token.token_type == TokenType.Name) {
                    arity = 2;
                    try stdout.print("{s}", .{token.literal_s});
                } else {
                    try stdout.print("Error", .{});
                    err = true;
                }
            } else if (arity == 1) { // known to be not
                if (token.token_type == TokenType.Signal) {
                    group += 1;
                    try stdout.print("{d}", .{token.literal});
                } else if (token.token_type == TokenType.Name) {
                    group += 1;
                    try stdout.print("{s}", .{token.literal_s});
                } else {
                    try stdout.print("Error", .{});
                    err = true;
                }
            } else if (arity == 2) { // presumably binary operator, but can be 0-ary
                if (token.token_type == TokenType.ARROW) {
                    group += 2;
                    try stdout.print("->", .{});
                } else if (is_binary_operator(token.token_type)) {
                    arity = 1;
                    const symbol: u8 = switch (token.token_type) {
                        TokenType.AND => '&',
                        TokenType.OR => '|',
                        TokenType.LSHIFT => '<',
                        TokenType.RSHIFT => '>',
                        else => ' ',
                    };
                    try stdout.print("{c}", .{symbol});
                } else {
                    try stdout.print("Error", .{});
                    err = true;
                }
            }
        }
    }
}
