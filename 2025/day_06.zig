const std = @import("std");

const Op = enum { add, multiply };

fn doOperation(operator: Op, operand1: usize, operand2: usize) usize {
    return switch (operator) {
        .add => operand1 + operand2,
        .multiply => operand1 * operand2,
    };
}

pub fn part1(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var line_it = std.mem.tokenizeScalar(u8, input, '\n');

    var lines = std.ArrayList(std.mem.TokenIterator(u8, .scalar)).empty;
    defer lines.deinit(allocator);

    while (line_it.next()) |line| {
        const token_it = std.mem.tokenizeScalar(u8, line, ' ');
        lines.append(allocator, token_it) catch unreachable;
    }

    var sum: usize = 0;

    while (true) {
        if (lines.items[0].peek() == null) {
            break;
        }

        const operator = switch (lines.items[lines.items.len - 1].next().?[0]) {
            '+' => Op.add,
            '*' => Op.multiply,
            else => unreachable,
        };

        var current_result: usize = std.fmt.parseInt(usize, lines.items[0].next().?, 10) catch unreachable;

        for (lines.items[1 .. lines.items.len - 1]) |*token_it| {
            current_result = doOperation(operator, current_result, std.fmt.parseInt(usize, token_it.next().?, 10) catch unreachable);
        }

        sum += current_result;
    }

    return sum;
}

pub fn part2(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var line_it = std.mem.tokenizeScalar(u8, input, '\n');

    var lines_al = std.ArrayList([]const u8).empty;
    defer lines_al.deinit(allocator);

    while (line_it.next()) |line| {
        const trimmed_line = std.mem.trim(u8, line, "\r\t");
        lines_al.append(allocator, trimmed_line) catch unreachable;
    }

    var sum: usize = 0;
    var current_operator: Op = undefined;
    var current_result: usize = 0;

    const lines = lines_al.toOwnedSlice(allocator) catch unreachable;
    defer allocator.free(lines);

    for (lines[lines.len - 1], 0..) |operator_token, i| {
        switch (operator_token) {
            '+' => {
                sum += current_result;
                current_result = 0;
                current_operator = Op.add;
            },
            '*' => {
                sum += current_result;
                current_result = 1;
                current_operator = Op.multiply;
            },
            ' ' => {},
            else => unreachable,
        }

        var current_number: usize = 0;

        var not_blank: bool = false;

        for (lines[0 .. lines.len - 1]) |line| {
            if (line[i] == ' ') continue;
            not_blank = true;
            current_number *= 10;
            current_number += line[i] - '0';
        }

        if (not_blank) current_result = doOperation(current_operator, current_result, current_number);
    }

    sum += current_result;

    return sum;
}
