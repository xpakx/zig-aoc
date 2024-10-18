const std = @import("std");

const Direction = enum { FloorUp, FloorDown };

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of Code 2024, Day 1\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input01.txt", .{});
    defer file.close();

    var floor: i32 = 0;

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        const dir = switch (byte) {
            ')' => Direction.FloorDown,
            '(' => Direction.FloorUp,
            '\n' => continue,
            else => std.debug.panic("Shouldn't happen", .{}),
        };

        switch (dir) {
            Direction.FloorDown => floor -= 1,
            Direction.FloorUp => floor += 1,
        }

    }
    try stdout.print(" * Floor: {d}\n", .{floor});
}
