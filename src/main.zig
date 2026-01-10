const std = @import("std");
const cli = @import("cli.zig");
const walker = @import("walker.zig");
const Stats = @import("stats.zig").Stats;
const output = @import("output.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const options = cli.Cli.init(allocator) catch |err| switch (err) {
        error.ShowHelp => return,
        else => {
            std.debug.print("error: {s}\n", .{@errorName(err)});
            cli.printUsage(true);
            std.process.exit(1);
        },
    };
    defer options.deinit();
    var dir = std.fs.cwd().openDir(options.path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("error: directory '{s}' not found.\n", .{options.path});
            cli.printUsage(true);
            std.process.exit(1);
        },
        else => return err,
    };
    defer dir.close();
    var stats = Stats.init(allocator);
    defer stats.deinit();
    try walker.walk(dir, &options, &stats);
    try output.printSummary(&stats, options.size_format);
}
