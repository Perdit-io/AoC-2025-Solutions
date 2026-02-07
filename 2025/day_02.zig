const std = @import("std");

pub fn part1(input: []const u8) usize {
    var it = std.mem.tokenizeScalar(u8, input, ',');
    var total_sum: usize = 0;

    while (it.next()) |token| {
        var nums = std.mem.tokenizeScalar(u8, std.mem.trim(u8, token, "\n"), '-');
        const range_start = std.fmt.parseInt(usize, nums.next().?, 10) catch 0;
        const range_end = std.fmt.parseInt(usize, nums.next().?, 10) catch 0;

        var len: usize = 2;
        while (len <= 18) : (len += 2) {
            const half_len = len / 2;

            const power_of_10 = std.math.pow(usize, 10, half_len);
            const multiplier = power_of_10 + 1;

            const x_min_digits = std.math.pow(usize, 10, half_len - 1);
            const x_max_digits = power_of_10 - 1;

            const x_min_range = (range_start + multiplier - 1) / multiplier;
            const x_max_range = range_end / multiplier;

            const start_x = @max(x_min_digits, x_min_range);
            const end_x = @min(x_max_digits, x_max_range);

            if (start_x > end_x) continue;

            const count = end_x - start_x + 1;
            const sum_x = count * (start_x + end_x) / 2;

            total_sum += sum_x * multiplier;
        }
    }
    return total_sum;
}

pub fn part1Slow(input: []const u8) usize {
    var it = std.mem.tokenizeScalar(u8, input, ',');
    var sum: usize = 0;

    while (it.next()) |token| {
        var numbers_it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, token, "\n"), '-');

        const num1: usize = std.fmt.parseInt(usize, numbers_it.next().?, 10) catch unreachable;
        const num2: usize = std.fmt.parseInt(usize, numbers_it.next().?, 10) catch unreachable;

        for (num1..num2 + 1) |n| {
            const digits = std.math.log10(n) + 1;
            const pow = std.math.pow(usize, 10, digits / 2);
            const half1 = n / pow;
            const half2 = n % pow;
            if (half1 == half2) sum += n;
        }
    }
    return sum;
}

pub fn part2(input: []const u8) usize {
    var it = std.mem.tokenizeScalar(u8, input, ',');
    var sum: usize = 0;

    const powers_of_10 = [_]usize{ 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000 };

    while (it.next()) |token| {
        var numbers_it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, token, "\n"), '-');

        const num1: usize = std.fmt.parseInt(usize, numbers_it.next().?, 10) catch unreachable;
        const num2: usize = std.fmt.parseInt(usize, numbers_it.next().?, 10) catch unreachable;

        var current_digits: usize = if (num1 == 0) 1 else std.math.log10(num1) + 1;
        var next_threshold = powers_of_10[current_digits];

        blk: for (num1..num2 + 1) |n| {
            if (n == next_threshold) {
                current_digits += 1;
                next_threshold *= 10;
            }
            const digits = current_digits;
            var repeat_digits = digits / 2;
            while (repeat_digits > 0) : (repeat_digits -= 1) {
                if (digits % repeat_digits != 0) continue;
                const pow = powers_of_10[repeat_digits];
                const repeating = n % pow;
                var num_left = n;
                while (true) {
                    num_left = num_left / pow;
                    if (num_left == 0) {
                        sum += n;
                        continue :blk;
                    }
                    const block_should_repeat = num_left % pow;
                    if (block_should_repeat != repeating) break;
                }
            }
        }
    }
    return sum;
}

// const p = try std.math.powi(usize, 10, l);
// var x = n;
// const y = x % p;
// while (true) {
//     x = x / p;
//     const z = x % p;
//     if (x == 0) return true;
//     if (z != y) break;
// }

fn part1Scrapped(input: []const u8) u64 {
    var it = std.mem.tokenizeAny(u8, input, ",\n");
    var sum: u64 = 0;

    while (it.next()) |token| {
        var it2 = std.mem.tokenizeScalar(u8, token, '-');

        const num1_str = it2.next().?;
        const num2_str = it2.next().?;

        var digits1 = num1_str.len / 2;
        var digits2 = num2_str.len / 2;

        std.debug.print("{s: >10} {s: >10}  - ", .{ num1_str, num2_str });

        var half1: u32 = undefined;

        if (num1_str.len % 2 == 1) {
            if (num1_str.len == num2_str.len) {
                std.debug.print("\n", .{});
                continue;
            }
            const pow: u31 = @truncate(digits1);
            half1 = std.math.pow(u32, 10, pow);
            digits1 += 1;
        } else {
            half1 = std.fmt.parseInt(u32, num1_str[0..(digits1)], 10) catch unreachable;
            const half1_2 = std.fmt.parseInt(u32, num1_str[(digits1)..], 10) catch unreachable;
            if (half1 < half1_2) half1 += 1;
        }

        var half2: u32 = undefined;

        if (num2_str.len % 2 == 1) {
            const pow: u31 = @truncate(digits2);
            half2 = std.math.pow(u32, 10, pow) - 1;
            digits2 -= 1;
        } else {
            half2 = std.fmt.parseInt(u32, num2_str[0..(digits2)], 10) catch unreachable;
            const half2_2 = std.fmt.parseInt(u32, num2_str[(digits2)..], 10) catch unreachable;
            if (half2 > half2_2) half2 -= 1;
        }

        std.debug.print("{d: >3}|{d: <3} - ", .{ digits1, digits2 });

        if (digits1 > digits2) {
            std.debug.print("\n", .{});
            continue;
        }

        var num1 = half1 * std.math.pow(u64, 10, digits1) + half1;
        const num2 = half2 * std.math.pow(u64, 10, digits2) + half2;

        if (num1 > num2) {
            std.debug.print("\n", .{});
            continue;
        }

        std.debug.print("{d: >10} | {d: >10} |", .{ num1, num2 });

        while (half1 <= half2) {
            sum += num1;
            half1 += 1;
            num1 = half1 * std.math.pow(u64, 10, digits1) + half1;
        }
        std.debug.print("{d: <10}\n", .{num1});
    }

    std.debug.print("{d}", .{sum});

    return sum;
}

// even .len, it should skip odd .len
//
// digits1|digits2 - digits3|digits4
// 99|00 - 999|999   digits2 can repeat digits1
// 11|99 - 999|999   digits2 can't repeat digits1
// same for digits3 and digits4
//
// compare digits1 to digits3
// 12|34 - 56|78     13|13 - 56|56    digits1 < digits2, so add 1 to digits1, and digits3 < digits4
// 12|34 - 78|56     13|13 - 77|77    digits1 < digits2, so add 1 to digits1, and digits3 > digits4,
//                                    so subtract 1 from digits3
//
// what if num2 has more digits
// 12|34 - 12345 - should be treated as 12|34 - 99|99
// 12|34 - 123|456 - should be treated as 12|34 - 99|99 U 100|000 - 123|456
//
// what if num1 has less digits
// 123 - 12|34 - should be treated as 10|00 - 12|34
// 1 - 123|456 => 10|00 - 99|99 U 100|000 - 123|456
//
// 12|34 - 99|99 => 13|13 - 99|99 => 99-13+1
//
// 12|34 - 1234|5678 - should be 12|34 - 99|99 U 100|000 - 999|999 U 1000|0000 - 1234|5678
//
// 1|0 - 9|9 => 1|1 - 9|9 => 9-1+1 = 9
// 10|00 - 99|99 => 10|10 - 99|99 => 99-10+1 = 90
// 100|000 - 999|999 => 100|100 - 999|999 => 999-100+1 = 900
//
// 3 dig - 9 dig    => 4 dig + 6 dig + 8 dig
// 123 - 123456789
// 10|00 - 99|99 U 100|000 - 999|999 U 1000|000 - 9999|9999
//       90      +        900        +        9000
//
// 1234 - 12345678
// 13|13 - 99|99 U 100|000 - 999|999 U 1000|0000 - 1234|1234
//    99-13+1    +        900        +      1234-1000+1
//
// 1. base case = 0
// 2. get num1.len
// 3. while loop until num2.len
// 4. skip odd .len
// 5. if num2.len > num1.len, use max/min appropriately per digit
// 6. if digits1 < digits2, digits1 + 1
// 7. if digits4 < digits3, digits4 - 1
// 8. per digit .len, do digits4 - digits1 + 1
// 9. sum all of them up^
