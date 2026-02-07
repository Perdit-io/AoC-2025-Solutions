const std = @import("std");

const default_year = "2025";
const default_day_str = "1";
const default_bench = false;
const default_bench_iter = 100;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const run_step = b.step("solve", "Run and print solution(s)");
    const test_step = b.step("test", "Run unit tests for solution(s)");

    // Options
    const year = b.option([]const u8, "year", b.fmt("Year (default: {s})", .{default_year})) orelse default_year;
    const day_str = b.option([]const u8, "day", b.fmt("Day(s) to run (e.g. 1, 1..5) (default: {s})", .{default_day_str})) orelse default_day_str;
    const bench = b.option(bool, "bench", b.fmt("Run benchmarks (default: {})", .{default_bench})) orelse default_bench;
    const bench_iter = b.option(usize, "bench_iter", b.fmt("Iterations (default: {d})", .{default_bench_iter})) orelse default_bench_iter;

    var start: usize = 0;
    var end: usize = 0;
    if (std.mem.indexOf(u8, day_str, "..")) |idx| {
        start = std.fmt.parseInt(usize, day_str[0..idx], 10) catch @panic("Invalid day format");
        end = std.fmt.parseInt(usize, day_str[idx + 2 ..], 10) catch @panic("Invalid day format");
    } else {
        start = std.fmt.parseInt(usize, day_str, 10) catch @panic("Invalid day format");
        end = start;
    }

    var solutions_code = std.ArrayList(u8).empty;
    defer solutions_code.deinit(b.allocator);
    var active_days = std.ArrayList(u8).initCapacity(b.allocator, 25) catch unreachable;
    defer active_days.deinit(b.allocator);

    const virtual_dir = b.addWriteFiles();
    const runner_path = virtual_dir.addCopyFile(b.path("build/runner.zig"), "runner.zig");

    for (start..end + 1) |d| {
        const day_src_name = b.fmt("day_{d:0>2}.zig", .{d});
        const day_txt_name = b.fmt("day_{d:0>2}.txt", .{d});

        const original_src = b.path(b.fmt("{s}/{s}", .{ year, day_src_name }));
        const original_txt = b.path(b.fmt("input/{s}/{s}", .{ year, day_txt_name }));

        if (std.fs.cwd().access(b.fmt("{s}/{s}", .{ year, day_src_name }), .{}) != error.FileNotFound and std.fs.cwd().access(b.fmt("input/{s}/{s}", .{ year, day_txt_name }), .{}) != error.FileNotFound) {
            const day_path = virtual_dir.addCopyFile(original_src, day_src_name);
            _ = virtual_dir.addCopyFile(original_txt, day_txt_name);
            const line = b.fmt("pub const day_{d:0>2} = @import(\"{s}\");\n", .{ d, day_src_name });
            solutions_code.appendSlice(b.allocator, line) catch unreachable;

            active_days.appendAssumeCapacity(@intCast(d));

            const day_mod = b.createModule(.{
                .root_source_file = day_path,
                .target = b.graph.host,
                .optimize = optimize,
            });
            const tester = b.addTest(.{
                .name = "solutions",
                .root_module = day_mod,
            });
            const run_test = b.addRunArtifact(tester);
            test_step.dependOn(&run_test.step);
        }
    }

    _ = virtual_dir.add("solutions.zig", solutions_code.items);

    const exe = b.addExecutable(.{
        .name = "aoc-runner",
        .root_module = b.createModule(.{
            .root_source_file = runner_path, // The copy in cache
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });

    const solutions_mod = b.createModule(.{
        .root_source_file = virtual_dir.getDirectory().path(b, "solutions.zig"),
        .target = b.graph.host,
    });
    exe.root_module.addImport("solutions", solutions_mod);

    const options = b.addOptions();
    options.addOption(bool, "bench", bench);
    options.addOption(usize, "bench_iter", bench_iter);
    options.addOption([]const u8, "year", year);
    options.addOption([]const u8, "days", active_days.items);
    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    run_step.dependOn(&run_exe.step);
}
