const std = @import("std");

const Box = struct {
    length: u32 = 0,
    width: u32 = 0,
    height: u32 = 0,
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Advent of Code 2024, Day 2\n", .{});
    try stdout.print("==========================\n", .{});

    var file = try std.fs.cwd().openFile("input/input02.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();

    var total_area: u32 = 0;
    var total_ribbon: u32 = 0;

    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var it = std.mem.split(u8, arr.items, "x");

        var i: u8 = 0;
        var box: Box = Box{};
        while (it.next()) |x| {
            const value = std.fmt.parseInt(u32, x, 10) catch |err| {
                std.debug.panic("{any}\n", .{err});
            };
            switch (i) {
                0 => box.length = value,
                1 => box.width = value,
                2 => box.height = value,
                else => {
                    std.debug.panic("Too much args\n", .{});
                },
            }
            i += 1;
        }
        const side1 = box.length * box.height;
        const side2 = box.length * box.width;
        const side3 = box.width * box.height;
        const area = 2 * side1 + 2 * side2 + 2 * side3;
        const shortest_side = min(side1, min(side2, side3));
        total_area += area + shortest_side;

        const longest_dim = max(box.length, max(box.width, box.height));
        const ribbon_len = 2 * box.length + 2 * box.width + 2 * box.height - 2 * longest_dim;
        const bow = box.length * box.height * box.width;
        total_ribbon += ribbon_len + bow;

        arr.clearRetainingCapacity();
    }

    try stdout.print("Area {d}\n", .{total_area});
    try stdout.print("Ribbon {d}\n", .{total_ribbon});
    try bw.flush();
}

fn min(a: u32, b: u32) u32 {
    return if (a < b) a else b;
}

fn max(a: u32, b: u32) u32 {
    return if (a > b) a else b;
}
