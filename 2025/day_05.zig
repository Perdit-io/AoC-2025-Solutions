const std = @import("std");

const NumRange = struct {
    lower: usize,
    upper: usize,

    const Self = @This();

    fn inside(self: Self, num: usize) bool {
        return (self.lower <= num and num <= self.upper);
    }
};

pub fn part1(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var it = std.mem.splitScalar(u8, input, '\n');

    var ranges = std.ArrayList(NumRange).empty;
    defer ranges.deinit(allocator);

    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "")) break;

        var it2 = std.mem.tokenizeScalar(u8, token, '-');
        const lower: usize = std.fmt.parseInt(usize, it2.next().?, 10) catch unreachable;
        const upper: usize = std.fmt.parseInt(usize, it2.next().?, 10) catch unreachable;

        ranges.append(allocator, .{ .lower = lower, .upper = upper }) catch unreachable;
    }

    var sum: usize = 0;

    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "")) break;

        const num: usize = std.fmt.parseInt(usize, token, 10) catch unreachable;
        for (ranges.items) |range| {
            if (range.inside(num)) {
                sum += 1;
                break;
            }
        }
    }

    return sum;
}

pub fn part2(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var it = std.mem.splitScalar(u8, input, '\n');

    var ranges = std.ArrayList(NumRange).empty;
    defer ranges.deinit(allocator);

    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "")) break;

        var it2 = std.mem.tokenizeScalar(u8, token, '-');
        const lower: usize = std.fmt.parseInt(usize, it2.next().?, 10) catch unreachable;
        const upper: usize = std.fmt.parseInt(usize, it2.next().?, 10) catch unreachable;

        ranges.append(allocator, .{ .lower = lower, .upper = upper }) catch unreachable;
    }

    const sortFn = struct {
        fn lessThan(_: void, a: NumRange, b: NumRange) bool {
            return a.lower < b.lower;
        }
    }.lessThan;

    std.mem.sort(NumRange, ranges.items, {}, sortFn);

    var sum: usize = 0;
    var current_lower: usize = ranges.items[0].lower;
    var current_upper: usize = ranges.items[0].upper;

    for (ranges.items[1..]) |range| {
        if (range.lower <= current_upper) {
            current_upper = @max(current_upper, range.upper);
        } else {
            sum += current_upper - current_lower + 1;
            current_lower = range.lower;
            current_upper = range.upper;
        }
    }

    sum += current_upper - current_lower + 1;

    return sum;
}
