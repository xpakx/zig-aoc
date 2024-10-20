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
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();
    try scanner.scan_tokens(&tokens);

    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();
    try extract_instructions(&tokens, &instructions);
    // try stdout.print("{any}\n", .{instructions});

    var lights: [1000][1000]bool = [_][1000]bool{[_]bool{false} ** 1000} ** 1000;

    for (instructions.items) |instr| {
        updateLights(instr, &lights);
    }

    const lit = countLights(&lights);

    try stdout.print(" * Lit lights: {d}\n", .{lit});

    var lights2: [1000][1000]u16 = [_][1000]u16{[_]u16{0} ** 1000} ** 1000;

    for (instructions.items) |instr| {
        updateLights2(instr, &lights2);
    }

    const lit2 = countBrightness(&lights2);
    try stdout.print("** Brightness: {d}\n", .{lit2});
    try bw.flush();
}

const Action = enum { TurnOn, TurnOff, Toggle };

const Coord = struct {
    x: u32,
    y: u32,
};

const Instruction = struct {
    action: Action,
    start: Coord,
    end: Coord,
};

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

pub fn extract_instructions(tokens: *std.ArrayList(Token), instructions: *std.ArrayList(Instruction)) !void {
    var part: u8 = 0;
    var turn: bool = false;
    var error_line: u32 = 0;
    var err: bool = false;
    var action: Action = undefined;
    var x1: u32 = undefined;
    var y1: u32 = undefined;
    var x2: u32 = undefined;
    var y2: u32 = undefined;

    for (try tokens.toOwnedSlice()) |token| {
        if (part >= 8) {
            if (err) {
                err = false;
            } else {
                const instr = Instruction{
                    .action = action,
                    // min and max for easier iterating later on, they're all rectangles after all
                    .start = Coord{ .x = min(x1, x2), .y = min(y1, y2) },
                    .end = Coord{ .x = max(x1, x2), .y = max(y1, y2) },
                };
                try instructions.append(instr);
            }
            part = 0;
        }
        switch (token.token_type) {
            TokenType.Turn => {
                if (part != 0) {
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Token `turn` at bad position\n", .{token.line});
                }
                turn = true;
            },
            TokenType.On => {
                if (part != 0 and !turn) {
                    turn = false;
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Token `on` at bad position\n", .{token.line});
                }
                turn = false;
                part = 1;
                action = Action.TurnOn;
            },
            TokenType.Off => {
                if (part != 0 and !turn) {
                    turn = false;
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Token `off` at bad position\n", .{token.line});
                }
                turn = false;
                part = 1;
                action = Action.TurnOff;
            },
            TokenType.Toggle => {
                if (part != 0) {
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Token `toggle` at bad position\n", .{token.line});
                }
                part = 1;
                action = Action.Toggle;
            },
            TokenType.Num => {
                if (part != 1 and part != 3 and part != 5 and part != 7) {
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Number `{d}` at bad position\n", .{ token.line, token.literal });
                }
                if (part == 1) {
                    x1 = token.literal;
                } else if (part == 3) {
                    y1 = token.literal;
                } else if (part == 5) {
                    x2 = token.literal;
                } else if (part == 7) {
                    y2 = token.literal;
                }
                part += 1;
            },
            TokenType.Comma => {
                if (part != 2 and part != 6) {
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Comma at bad position\n", .{token.line});
                }
                part += 1;
            },
            TokenType.Through => {
                if (part != 4) {
                    err = true;
                    error_line = token.line;
                    std.debug.print("{d} | Token `through` at bad position\n", .{token.line});
                }
                part = 5;
            },
            TokenType.EOF => {},
        }
    }
}

fn min(a: u32, b: u32) u32 {
    return if (a < b) a else b;
}

fn max(a: u32, b: u32) u32 {
    return if (a > b) a else b;
}

// this is actually pretty dumb thing to do, we could calculate
// unions and xors of rectangles instead the way e.g. window
// managers do, but this way it's faster to implement
pub fn updateLights(instr: Instruction, lights: *[1000][1000]bool) void {
    for (instr.start.x..instr.end.x + 1) |i| {
        for (instr.start.y..instr.end.y + 1) |j| {
            switch (instr.action) {
                Action.TurnOn => lights[i][j] = true,
                Action.TurnOff => lights[i][j] = false,
                Action.Toggle => lights[i][j] = !lights[i][j],
            }
        }
    }
}

pub fn countLights(lights: *[1000][1000]bool) u32 {
    var result: u32 = 0;
    for (0..1000) |i| {
        for (0..1000) |j| {
            if (lights[i][j]) {
                result += 1;
            }
        }
    }
    return result;
}

pub fn updateLights2(instr: Instruction, lights: *[1000][1000]u16) void {
    for (instr.start.x..instr.end.x + 1) |i| {
        for (instr.start.y..instr.end.y + 1) |j| {
            switch (instr.action) {
                Action.TurnOn => lights[i][j] += 1,
                Action.TurnOff => {
                    if (lights[i][j] > 0) {
                        lights[i][j] -= 1;
                    }
                },
                Action.Toggle => lights[i][j] += 2,
            }
        }
    }
}

pub fn countBrightness(lights: *[1000][1000]u16) u32 {
    var result: u32 = 0;
    for (0..1000) |i| {
        for (0..1000) |j| {
            result += @as(u32, lights[i][j]);
        }
    }
    return result;
}
