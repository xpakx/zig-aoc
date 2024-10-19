const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub fn main() !void {
    try stdout.print("Advent of Code 2024, Day 6\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input06.txt", .{});
    defer file.close();

    var scanner = Scanner{ .file = &file };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var arr = std.ArrayList(Token).init(allocator);
    defer arr.deinit();
    try scanner.scan_tokens(&arr);

    try stdout.print("{any}", .{arr});

    try stdout.print(" * Floor: {d}\n", .{10});
    try bw.flush();
}

const TokenType = enum { Turn, On, Off, Toggle, Num, Comma, Through, EOF };

const Token = struct {
    token_type: TokenType,
    literal: u32,
    line: u32,
};

const Scanner = struct {
    file: *std.fs.File,
    peek_byte: u8 = '0',
    peeked: bool = false,
    param_buffer: [10]u8 = undefined,
    param_buffer_len: u32 = 0,

    pub fn scan_tokens(self: *Scanner, arr: *std.ArrayList(Token)) !void {
        var line: u32 = 1;

        while (true) {
            const byte = self.read() catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            if (byte == '\n') {
                line += 1;
            } else if (byte == ',') {
                try arr.append(Token{ .token_type = TokenType.Comma, .literal = 0, .line = line });
            } else if (is_digit(byte)) {
                const num = try self.read_number(byte);
                try arr.append(Token{ .token_type = TokenType.Num, .literal = num, .line = line });
            } else if (is_alpha(byte)) {
                const token_type = try self.read_identifier(byte, line);
                try arr.append(Token{ .token_type = token_type, .literal = 0, .line = line });
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

    fn read_identifier(self: *Scanner, byte: u8, line: u32) !TokenType {
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
        const param_slice = self.param_buffer[0..self.param_buffer_len];
        if (std.mem.eql(u8, param_slice, "turn")) {
            return TokenType.Turn;
        }
        if (std.mem.eql(u8, param_slice, "off")) {
            return TokenType.Off;
        }
        if (std.mem.eql(u8, param_slice, "on")) {
            return TokenType.On;
        }
        if (std.mem.eql(u8, param_slice, "toggle")) {
            return TokenType.Toggle;
        }
        if (std.mem.eql(u8, param_slice, "through")) {
            return TokenType.Through;
        }

        std.debug.print("Unknown identifier {s} found at line {d}\n", .{ param_slice, line });
        return error.UnknownToken;
    }
};

pub fn is_digit(byte: u8) bool {
    return byte >= '0' and byte <= '9';
}

pub fn is_alpha(byte: u8) bool {
    return byte >= 'a' and byte <= 'z';
}
