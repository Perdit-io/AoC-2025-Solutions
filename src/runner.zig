const std = @import("std");
const config = @import("config");
const solutions = @import("solutions");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const writer_buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(writer_buffer);
    var stdout = std.fs.File.stdout();
    defer stdout.close();
    var stdout_writer = stdout.writer(writer_buffer);
    const writer = &stdout_writer.interface;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var total_ns: u64 = 0;

    inline for (@typeInfo(solutions).@"struct".decls) |decl| {
        const Sol = @field(solutions, decl.name);

        if (!@hasDecl(Sol, "tasks")) continue;

        defer _ = arena.reset(.retain_capacity);
        const solution_allocator = arena.allocator();

        try writer.print("\n\x1b[1;32m== {s} ==\x1b[0m\n", .{Sol.name});

        inline for (Sol.tasks) |task| {
            total_ns += try runTask(writer, task, solution_allocator);
            try writer.flush();
        }
    }

    if (config.bench) {
        try writer.writeAll("Total elapsed benchmark time: ");
    } else {
        try writer.writeAll("Total elapsed solution time: ");
    }
    _ = try printTime(writer, total_ns);
    try writer.writeAll("\n");
    try writer.flush();
}

fn runTask(writer: *std.Io.Writer, task: anytype, allocator: std.mem.Allocator) !u64 {
    var timer = std.time.Timer.start() catch unreachable;
    const result, const nanoseconds = timer: {
        const answer = task.func(task.input);
        const t = timer.read();
        break :timer .{ answer, t };
    };

    try writer.writeAll("\x1b[36m");
    try writer.print("  [{s}] ", .{task.name});
    try writer.writeAll("\x1b[0m");

    if (config.bench) {
        return runBenchmark(writer, task, allocator, result);
    }

    try writer.writeAll(" ");
    try writer.writeAll("\x1b[90m");
    try writer.writeAll("(");
    const fill = try printTime(writer, nanoseconds);
    try writer.writeAll(")");
    try writer.writeAll("\x1b[0m");
    try writer.splatByteAll(' ', fill);
    try printAnswer(writer, result);
    try writer.print("\n", .{});

    return nanoseconds;
}

fn runBenchmark(writer: *std.Io.Writer, task: anytype, allocator: std.mem.Allocator, expected_result: anytype) !u64 {
    const times: []u64 = try allocator.alloc(u64, config.bench_iter);
    defer allocator.free(times);

    var timer = std.time.Timer.start() catch unreachable;

    for (times) |*t| {
        timer.reset();
        _ = task.func(task.input);
        t.* = timer.read();
    }

    std.mem.sort(u64, times, {}, std.sort.asc(u64));

    const min_ns: u64 = times[0];
    const max_ns: u64 = times[times.len - 1];
    const sum_ns: u64 = pass: {
        var sum: u64 = 0;
        for (times) |t| sum += t;
        break :pass sum;
    };
    const mean_ns: u64 = sum_ns / times.len;
    const middle_index = @divTrunc(times.len, 2);
    const median_ns: u64 = if (times.len % 2 == 1)
        times[middle_index]
    else
        (times[middle_index - 1] + times[middle_index]) / 2;

    const stddev: u64 = pass: {
        var sum: f64 = 0.0;
        for (times) |t| {
            const t_float: f64 = @floatFromInt(t);
            const mean_ns_float: f64 = @floatFromInt(mean_ns);
            const diff = t_float - mean_ns_float;
            sum += diff * diff;
        }
        const variance = sum / @as(f64, @floatFromInt(times.len));
        break :pass @intFromFloat(@sqrt(variance));
    };

    try printAnswer(writer, expected_result);
    try writer.writeAll("\n  ");
    try writer.writeAll("\x1b[90m");
    try writer.writeAll("\xce\xbc\xc2\xb1\xcf\x83: "); // μ±σ
    try writer.writeAll("\x1b[0m");
    _ = try printTime(writer, mean_ns);
    try writer.writeAll(" \xc2\xb1 ");
    _ = try printTime(writer, stddev);
    try writer.writeAll("\n  ");
    try writer.writeAll("\x1b[90m");
    try writer.writeAll("med: ");
    try writer.writeAll("\x1b[0m");
    _ = try printTime(writer, median_ns);
    try writer.writeAll("\n  ");
    try writer.writeAll("\x1b[90m");
    try writer.writeAll("min: ");
    try writer.writeAll("\x1b[0m");
    _ = try printTime(writer, min_ns);
    try writer.writeAll("\n  ");
    try writer.writeAll("\x1b[90m");
    try writer.writeAll("max: ");
    try writer.writeAll("\x1b[0m");
    _ = try printTime(writer, max_ns);
    try writer.writeByte('\n');

    return sum_ns;
}

fn printTime(writer: *std.Io.Writer, nanoseconds: u64) !u8 {
    const max_digits = 8;
    var t: f64 = @floatFromInt(nanoseconds);
    if (nanoseconds == 0) {
        // Unsure if this is possible, but handle it
        try writer.print("instant", .{});
        return 4;
    } else if (nanoseconds < 100) {
        try writer.print("{d:.0} ns", .{nanoseconds});
        const whole_digits = if (nanoseconds >= 10) @as(u8, 2) else @as(u8, 1);
        const trailing_digits = 0;
        return max_digits - @min(max_digits, whole_digits + trailing_digits);
    } else if (nanoseconds < 100 * 1000) {
        t /= @floatFromInt(std.time.ns_per_us);
        try writer.print("{d:.1} \xc2\xb5s", .{t});
        const whole_digits = if (t < 1.0) @as(u8, 1) else @as(u8, @intFromFloat(@floor(std.math.log10(@trunc(t))))) + 1;
        const trailing_digits = 2;
        return max_digits - @min(max_digits, whole_digits + trailing_digits);
    } else if (nanoseconds < 100 * 1000 * 10000) {
        t /= @floatFromInt(std.time.ns_per_ms);
        try writer.print("{d:.3} ms", .{t});
        const whole_digits = if (t < 1.0) @as(u8, 1) else @as(u8, @intFromFloat(@floor(std.math.log10(@trunc(t))))) + 1;
        const trailing_digits = 4;
        return max_digits - @min(max_digits, whole_digits + trailing_digits + if (nanoseconds >= 100 * 1000 * 10000 - 500) @as(u8, 1) else @as(u8, 0));
    } else if (nanoseconds < 100 * 1000 * 10000 * 60) {
        t /= @floatFromInt(std.time.ns_per_s);
        try writer.print("{d:.3} s", .{t});
        const whole_digits = if (t < 1.0) @as(u8, 1) else @as(u8, @intFromFloat(@floor(std.math.log10(@trunc(t))))) + 1;
        const trailing_digits = 3;
        return max_digits - @min(max_digits, whole_digits + trailing_digits);
    } else if (nanoseconds <= 100 * 1000 * 10000 * 60 * 60) {
        t /= @floatFromInt(std.time.ns_per_min);
        try writer.print("{d:.3} m", .{t});
        const whole_digits = if (t < 1.0) @as(u8, 1) else @as(u8, @intFromFloat(@floor(std.math.log10(@trunc(t))))) + 1;
        const trailing_digits = 3;
        return max_digits - @min(max_digits, whole_digits + trailing_digits);
    } else {
        t /= @floatFromInt(std.time.ns_per_hour);
        try writer.print("{d:.2} hr", .{t});
        const whole_digits = if (t < 1.0) @as(u8, 1) else @as(u8, @intFromFloat(@floor(std.math.log10(@trunc(t))))) + 1;
        const trailing_digits = 3;
        return max_digits - @min(max_digits, whole_digits + trailing_digits);
    }
}

fn printAnswer(writer: *std.Io.Writer, answer: anytype) !void {
    const Answer = @TypeOf(answer);
    const fmt = switch (@typeInfo(Answer)) {
        .int, .float => "{d}",
        .pointer => |p| switch (p.child) {
            u8 => if (p.sentinel_ptr == null and (p.size == .many or p.size == .c)) "{any}" else "{s}",
            else => "{any}",
        },
        else => if (comptime isContainer(Answer) and @hasDecl(Answer, "format")) "{f}" else "{any}",
    };
    try writer.print(" " ++ fmt, .{answer});
}

fn isContainer(T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"enum", .@"union" => true,
        else => false,
    };
}
