const std = @import("std");

const Pos = struct {
    x: i32 = 0,
    y: i32 = 0,
};

const Direction = enum { Up, Down, Left, Right };

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Advent of Code 2024, Day 3\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input03.txt", .{});
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var h = std.AutoHashMap(Pos, i32).init(allocator);
    try h.put(Pos{}, 1);
    defer h.deinit();

    var pos = Pos{};

    var h2 = std.AutoHashMap(Pos, i32).init(allocator);
    try h2.put(Pos{}, 2);
    defer h2.deinit();
    var pos_santa = Pos{};
    var pos_robo = Pos{};
    var turn: u32 = 0;

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        const dir = switch (byte) {
            '^' => Direction.Up,
            'v' => Direction.Down,
            '>' => Direction.Right,
            '<' => Direction.Left,
            '\n' => continue,
            else => std.debug.panic("Shouldn't happen", .{}),
        };

        try updatePosition(dir, &pos, &h);

        if (@mod(turn, 2) == 0) {
            try updatePosition(dir, &pos_santa, &h2);
        } else {
            try updatePosition(dir, &pos_robo, &h2);
        }
        turn += 1;
    }

    var visited: u32 = 0;
    var it = h.iterator();
    while (it.next()) |_| {
        visited += 1;
    }

    try stdout.print(" * Visited houses: {d}\n", .{visited});

    var visited2: u32 = 0;
    var it2 = h2.iterator();
    while (it2.next()) |_| {
        visited2 += 1;
    }
    try stdout.print(" * Visited houses (with robot): {d}\n", .{visited2});
    try bw.flush();
}

pub fn updatePosition(dir: Direction, pos: *Pos, h: *std.AutoHashMap(Pos, i32)) !void {
    switch (dir) {
        Direction.Up => pos.y += 1,
        Direction.Down => pos.y -= 1,
        Direction.Right => pos.x += 1,
        Direction.Left => pos.x -= 1,
    }

    const current = h.get(pos.*);
    if (current) |v| {
        try h.put(pos.*, v + 1);
    } else {
        try h.put(pos.*, 1);
    }
}
