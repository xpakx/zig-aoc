const std = @import("std");

const Direction = enum { FloorUp, FloorDown };

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of Code 2024, Day 1\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input01.txt", .{});
    defer file.close();

    var floor: i32 = 0;

    var pos: u16 = 0;
    var part2Found: bool = false;

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

        if (!part2Found) {
            pos += 1;
            if (floor == -1) {
                part2Found = true;
            }
        }
    }
    try stdout.print(" * Floor: {d}\n", .{floor});
    try stdout.print("** Position: {d}\n", .{pos});
}
