const std = @import("std");

// there is definitely a better way of handling the data, like making just a single grid, but this works already
const PaperRoll = struct {
    adjacent_rolls: [3][3]bool,
    exists: bool,
    x: usize,
    y: usize,

    const Self = @This();

    fn init(exists: bool, x: usize, y: usize) Self {
        return .{ .adjacent_rolls = [_][3]bool{
            [_]bool{ false, false, false },
            [_]bool{ false, false, false },
            [_]bool{ false, false, false },
        }, .exists = exists, .x = x, .y = y };
    }

    fn change_adjacent(self: *Self, i: u8, j: u8, exists: bool) void {
        if (i >= self.adjacent_rolls.len or j >= self.adjacent_rolls[0].len) @panic("Invalid input parameters in fn change_adjacent.");
        self.adjacent_rolls[i][j] = exists;
    }

    fn count_adjacents(self: Self) usize {
        var num: usize = 0;
        for (self.adjacent_rolls) |row| {
            for (row) |value| {
                if (value) num += 1;
            }
        }
        return num;
    }
};

pub fn part1(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    var data_alist = std.ArrayList([]PaperRoll).empty;
    var idx: usize = 0;
    while (it.next()) |line| {
        var alist = std.ArrayList(PaperRoll).initCapacity(allocator, line.len) catch unreachable;
        for (line, 0..) |token, j| {
            if (token == '@') {
                alist.appendAssumeCapacity(PaperRoll.init(true, idx, j));
            } else { // token == '.'
                alist.appendAssumeCapacity(PaperRoll.init(false, idx, j));
            }
        }
        data_alist.append(allocator, alist.toOwnedSlice(allocator) catch unreachable) catch unreachable;
        idx += 1;
    }

    const data = data_alist.toOwnedSlice(allocator) catch unreachable;

    var sum: usize = 0;

    for (data, 0..) |row, i| {
        for (row, 0..) |roll, j| {
            if (roll.exists) {
                if (i < data.len - 1 and j < data[0].len - 1) data[i + 1][j + 1].change_adjacent(0, 0, true);
                if (i < data.len - 1) data[i + 1][roll.y].change_adjacent(0, 1, true);
                if (i < data.len - 1 and j > 0) data[i + 1][j - 1].change_adjacent(0, 2, true);
                if (j < data[0].len - 1) data[i][j + 1].change_adjacent(1, 0, true);
                if (j > 0) data[i][j - 1].change_adjacent(1, 2, true);
                if (i > 0 and j < data[0].len - 1) data[i - 1][j + 1].change_adjacent(2, 0, true);
                if (i > 0) data[i - 1][roll.y].change_adjacent(2, 1, true);
                if (i > 0 and j > 0) data[i - 1][j - 1].change_adjacent(2, 2, true);
            }
        }
    }

    for (data) |row| {
        for (row) |roll| {
            if (roll.count_adjacents() < 4 and roll.exists) {
                sum += 1;
            }
        }
    }

    return sum;
}

pub fn part2(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    var data_alist = std.ArrayList([]PaperRoll).empty;
    var idx: usize = 0;
    while (it.next()) |line| {
        var alist = std.ArrayList(PaperRoll).initCapacity(allocator, line.len) catch unreachable;
        for (line, 0..) |token, j| {
            if (token == '@') {
                alist.appendAssumeCapacity(PaperRoll.init(true, idx, j));
            } else { // token == '.'
                alist.appendAssumeCapacity(PaperRoll.init(false, idx, j));
            }
        }
        data_alist.append(allocator, alist.toOwnedSlice(allocator) catch unreachable) catch unreachable;
        idx += 1;
    }

    const data = data_alist.toOwnedSlice(allocator) catch unreachable;

    var sum: usize = 0;

    for (data, 0..) |row, i| {
        for (row, 0..) |roll, j| {
            if (roll.exists) {
                if (i < data.len - 1 and j < data[0].len - 1) data[i + 1][j + 1].change_adjacent(0, 0, true);
                if (i < data.len - 1) data[i + 1][j].change_adjacent(0, 1, true);
                if (i < data.len - 1 and j > 0) data[i + 1][j - 1].change_adjacent(0, 2, true);
                if (j < data[0].len - 1) data[i][j + 1].change_adjacent(1, 0, true);
                if (j > 0) data[i][j - 1].change_adjacent(1, 2, true);
                if (i > 0 and j < data[0].len - 1) data[i - 1][j + 1].change_adjacent(2, 0, true);
                if (i > 0) data[i - 1][j].change_adjacent(2, 1, true);
                if (i > 0 and j > 0) data[i - 1][j - 1].change_adjacent(2, 2, true);
            }
        }
    }

    var to_be_removed = std.ArrayList(PaperRoll).empty;
    defer to_be_removed.deinit(allocator);

    while (true) {
        var inner_sum: usize = 0;

        to_be_removed.clearRetainingCapacity();

        for (data) |row| {
            for (row) |roll| {
                if (roll.count_adjacents() < 4 and roll.exists) {
                    inner_sum += 1;
                    to_be_removed.append(allocator, roll) catch unreachable;
                }
            }
        }
        for (to_be_removed.items) |roll| {
            if (roll.exists) {
                if (roll.x < data.len - 1 and roll.y < data[0].len - 1) data[roll.x + 1][roll.y + 1].change_adjacent(0, 0, false);
                if (roll.x < data.len - 1) data[roll.x + 1][roll.y].change_adjacent(0, 1, false);
                if (roll.x < data.len - 1 and roll.y > 0) data[roll.x + 1][roll.y - 1].change_adjacent(0, 2, false);
                if (roll.y < data[0].len - 1) data[roll.x][roll.y + 1].change_adjacent(1, 0, false);
                if (roll.y > 0) data[roll.x][roll.y - 1].change_adjacent(1, 2, false);
                if (roll.x > 0 and roll.y < data[0].len - 1) data[roll.x - 1][roll.y + 1].change_adjacent(2, 0, false);
                if (roll.x > 0) data[roll.x - 1][roll.y].change_adjacent(2, 1, false);
                if (roll.x > 0 and roll.y > 0) data[roll.x - 1][roll.y - 1].change_adjacent(2, 2, false);
                data[roll.x][roll.y].exists = false;
            }
        }
        sum += inner_sum;
        if (inner_sum == 0) break;
    }

    return sum;
}
