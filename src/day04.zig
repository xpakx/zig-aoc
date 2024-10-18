const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub fn main() !void {
    try stdout.print("Advent of Code 2024, Day 4\n", .{});
    try stdout.print("==========================\n", .{});

    const key = "ckczppom";
    const part1 = try calculate(key, 5);
    const part2 = try calculate(key, 6);

    try stdout.print(" * Part 1: {d}\n", .{part1});
    try stdout.print(" * Part 2: {d}\n", .{part2});

    try bw.flush();
}

fn calculate(key: []const u8, _zeroes: u8) !u32 {
    var zeroes: u8 = _zeroes;

    var full: bool = true;
    if (zeroes % 2 != 0) {
        full = false;
        zeroes -= 1;
    }

    zeroes = zeroes / 2;

    var buffer: [30]u8 = undefined;
    std.mem.copyForwards(u8, &buffer, key);

    var found: bool = false;
    var num: u32 = 1;
    var digits: u32 = 1;
    var order: u32 = 10;
    while (!found) {
        appendNumAsBytes(&buffer, num, key.len, digits);
        found = test_md5(buffer[0 .. digits + key.len], zeroes, full);
        num += 1;
        if (num / order != (num - 1) / order) {
            digits += 1;
            order *= 10;
        }
    }

    num -= 1;
    return num;
}

fn test_md5(key: []const u8, zeroes: u8, last_byte_full: bool) bool {
    var md5 = std.crypto.hash.Md5.init(.{});
    var hash: [16]u8 = undefined;
    md5.update(key);
    md5.final(&hash);

    var all_zeroes = true;
    for (hash[0..zeroes]) |byte| {
        // try stdout.print("{x}\n", .{byte});
        if (byte != 0) {
            all_zeroes = false;
        }
    }
    if (!last_byte_full) {
        const byte = hash[zeroes];
        // try stdout.print("{x}\n", .{byte});
        const end = byte & 0b11110000;
        if (end != 0) {
            all_zeroes = false;
        }
    }

    return all_zeroes;
}

fn appendNumAsBytes(buffer: []u8, num: u32, key_len: usize, digits: u32) void {
    var num_copy = num;
    var i = key_len + digits - 1;
    while (num_copy != 0) {
        buffer[i] = @as(u8, '0') + @as(u8, @intCast(num_copy % 10));
        num_copy /= 10;
        i -= 1;
    }
}
