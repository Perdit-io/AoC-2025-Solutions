const std = @import("std");

const Op = enum { add, multiply };

fn doOperation(operator: Op, operand1: usize, operand2: usize) usize {
    switch (operator) {
        .add => {
            return operand1 + operand2;
        },
        .multiply => {
            return operand1 * operand2;
        },
    }
}

pub fn part1(input: []const u8) usize {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const allocator = debug_allocator.allocator();

    var word_it = std.mem.tokenizeScalar(u8, input, '\n');

    var lines = std.ArrayList(std.mem.TokenIterator(u8, .scalar)).empty;
    defer lines.deinit(allocator);

    while (word_it.next()) |line| {
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
