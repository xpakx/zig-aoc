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

    const p1 = try part1();
    const p2 = try part2();

    try stdout.print(" * Nice words: {d}\n", .{p1});
    try stdout.print("** Nice words: {d}\n", .{p2});
    try bw.flush();
}

fn part1() !u32 {
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

    return nice_words;
}

const Key = struct {
    first: u8,
    second: u8,
};

fn part2() !u32 {
    var file = try std.fs.cwd().openFile("input/input05.txt", .{});
    defer file.close();

    var pos: u32 = 0;
    var last: u8 = '0';
    var last2: u8 = '0';
    var triad_flag: u8 = '0';

    var one_letter: u32 = 0;

    var nice_words: u32 = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var h = std.AutoHashMap(Key, u32).init(allocator);
    defer h.deinit();

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') {
            _ = try test_triad(last2, last, byte, triad_flag, &h);
            if (one_letter > 0) {
                var max_pairs: u32 = 0;

                var it = h.iterator();
                while (it.next()) |entry| {
                    if (entry.value_ptr.* > max_pairs) {
                        max_pairs = entry.value_ptr.*;
                    }
                }
                if (max_pairs > 1) {
                    nice_words += 1;
                }
            }
            pos = 0;
            one_letter = 0;
            triad_flag = '0';

            h.clearRetainingCapacity();
            continue;
        }

        if (pos <= 1) {
            last2 = last;
            last = byte;
            pos += 1;
            continue;
        }

        if (byte == last2) {
            one_letter += 1;
        }

        triad_flag = try test_triad(last2, last, byte, triad_flag, &h);

        last2 = last;
        last = byte;
        pos += 1;
    }

    return nice_words;
}

pub fn test_triad(last2: u8, last: u8, byte: u8, triad_flag: u8, h: *std.AutoHashMap(Key, u32)) !u8 {
    const key = Key{ .first = last2, .second = last };

    if (triad_flag != '0' and byte == triad_flag) {
        try updateMap(&key, 2, h);
        return '0';
    } else if (triad_flag != '0' and byte != triad_flag) {
        try updateMap(&key, 1, h);
        return '0';
    } else if (last == last2 and last == byte) {
        return byte;
    } else {
        try updateMap(&key, 1, h);
        return '0';
    }
}

pub fn updateMap(pos: *const Key, delta: u32, h: *std.AutoHashMap(Key, u32)) !void {
    const current = h.get(pos.*);
    if (current) |v| {
        try h.put(pos.*, v + delta);
    } else {
        try h.put(pos.*, delta);
    }
}
