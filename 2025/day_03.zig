const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) usize {
    _ = allocator;

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    var digit1: usize = 0;
    var digit2: usize = 0;
    var sum: usize = 0;

    while (it.next()) |token| {
        for (token) |byte| {
            if (digit1 < digit2) {
                digit1 = digit2;
                digit2 = byte - '0';
            } else if (digit2 <= (byte - '0')) {
                if (digit1 < digit2) digit1 = digit2;
                digit2 = byte - '0';
            }
        }
        sum += digit1 * 10 + digit2;
        digit1 = 0;
        digit2 = 0;
    }

    return sum;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) usize {
    _ = allocator;

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    var digits = [_]u8{0} ** 12;
    var sum: usize = 0;

    while (it.next()) |token| {
        for (token) |byte| {
            var to_update: bool = false;
            for (0..digits.len - 1) |idx| {
                if (digits[idx] < digits[idx + 1]) to_update = true;
                if (to_update) {
                    digits[idx] = digits[idx + 1];
                }
            }
            if (digits[digits.len - 1] <= (byte - '0') or to_update == true) {
                digits[digits.len - 1] = byte - '0';
            }
        }
        var partial: usize = 0;
        for (digits) |digit| {
            partial *= 10;
            partial += digit;
        }
        sum += partial;
        digits = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    }

    return sum;
}
