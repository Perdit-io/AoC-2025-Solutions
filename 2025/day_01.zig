const std = @import("std");

// This was reimplemented to try changing dir to i16 instead of char u8, which was needed for
// part 2 retry
pub fn part1(comptime input: []const u8) usize {
    const result = comptime blk: {
        @setEvalBranchQuota(500_000);

        var dial: isize = 50;
        var hits: usize = 0;
        var it = std.mem.tokenizeAny(u8, input, &std.ascii.whitespace);

        while (it.next()) |token| {
            const dir: isize = if (token[0] == 'L') -1 else 1;
            const value = std.fmt.parseInt(usize, token[1..], 10) catch |err| {
                @compileError(std.fmt.comptimePrint("Invalid number in token '{s}': {any}", .{ token, err }));
            };

            dial = @mod(dir * value + dial, 100);
            if (dial == 0) hits += 1;
        }

        break :blk hits;
    };

    return result;
}

// Idea from previous attempt: if dir 'R', there's no edge cases. So why not just flip the dial
// and not branch anymore?
pub fn part2(comptime input: []const u8) usize {
    const result = comptime blk: {
        @setEvalBranchQuota(500_000);

        var dial: isize = 50;
        var hits: usize = 0;
        var it = std.mem.tokenizeAny(u8, input, &std.ascii.whitespace);

        while (it.next()) |token| {
            const dir: isize = if (token[0] == 'L') -1 else 1;
            const value = std.fmt.parseInt(usize, token[1..], 10) catch |err| {
                @compileError(std.fmt.comptimePrint("Invalid number in token '{s}': {any}", .{ token, err }));
            };

            // flipped if dir == -1 (30 -> 70) (1 -> 99),
            // otherwise, it's the same value (30 -> 30) (1 -> 1)
            const flipped_dial = @mod(dir * dial + 100, 100);
            hits += @abs(@divFloor(flipped_dial + value, 100));
            dial = @mod(dir * value + dial, 100);
        }

        break :blk hits;
    };

    return result;
}

fn part2a(comptime input: []const u8) u16 {
    const result = comptime blk: {
        @setEvalBranchQuota(500_000);

        var dial: i16 = 50;
        var hits: u16 = 0;
        var it = std.mem.tokenizeAny(u8, input, &std.ascii.whitespace);

        while (it.next()) |token| {
            const dir = token[0];
            const value = std.fmt.parseInt(u15, token[1..], 10) catch |err| {
                @compileError(std.fmt.comptimePrint("Invalid number in token '{s}': {any}", .{ token, err }));
            };

            switch (dir) {
                'L' => {
                    // to handle false cases like 0 end false negative (gets counted now),
                    // and 0 start false positive (doesn't now)
                    const temp_dial = dial - 1;
                    hits += @abs(@divFloor(temp_dial, 100) - @divFloor(temp_dial - value, 100));
                    dial = @mod(dial - value, 100);
                },
                'R' => {
                    hits += @abs(@divFloor(dial + value, 100));
                    dial = @mod(dial + value, 100);
                },
                else => unreachable,
            }
        }

        break :blk hits;
    };

    return result;
}
