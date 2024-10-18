const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const Direction = enum { FloorUp, FloorDown };

pub fn is_vowel(byte: u8) bool {
    return byte == 'a' or byte == 'i' or byte == 'e' or byte == 'u' or byte == 'o';
}

pub fn is_bad_pair(first: u8, second: u8) bool {
    if (first == 'a' and second == 'b') {
        return true;
    }
    if (first == 'c' and second == 'd') {
        return true;
    }
    if (first == 'p' and second == 'q') {
        return true;
    }
    if (first == 'x' and second == 'y') {
        return true;
    }
    return false;
}

pub fn main() !void {
    try stdout.print("Advent of Code 2024, Day 5\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input05.txt", .{});
    defer file.close();

    var vowels: u32 = 0;
    var pairs: u32 = 0;
    var pos: u32 = 0;
    var last: u8 = '0';
    var bad_pairs: u32 = 0;

    var nice_words: u32 = 0;

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') {
            if (vowels >= 3 and bad_pairs == 0 and pairs > 0) {
                nice_words += 1;
            }
            vowels = 0;
            pairs = 0;
            pos = 0;
            bad_pairs = 0;
            continue;
        }

        if (bad_pairs > 0) {
            pos += 1;
            continue;
        }

        if (is_vowel(byte)) {
            vowels += 1;
        }
        if (pos > 0 and byte == last) {
            pairs += 1;
        }
        if (pos > 0 and is_bad_pair(last, byte)) {
            bad_pairs += 1;
        }
        last = byte;
        pos += 1;
    }
    try stdout.print(" * Nice words: {d}\n", .{nice_words});
    try bw.flush();
}
