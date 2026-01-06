const std = @import("std");

const usage =
    \\statz - fast folder analysis tool.
    \\
    \\usage: sz [<path>] [<options>...]
    \\
    \\Arguments:
    \\  <path> the path to analyze, defaults to the CWD
    \\
;

const Cli = struct {
    path: []const u8,
    verbose: bool = false,
    symlinks: bool = false,
    hidden_files: bool = false,

    fn init(allocator: std.mem.Allocator) !Cli {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();
        if (!args.skip()) return error.MissingProgramName;
        var cli = Cli{ .path = "" };
        var seen_path = false;
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try printUsage(false);
                return error.ShowHelp;
            } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
                cli.verbose = true;
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--symlinks")) {
                cli.symlinks = true;
            } else if (std.mem.eql(u8, arg, "-H") or std.mem.eql(u8, arg, "--hidden")) {
                cli.hidden_files = true;
            } else if (std.mem.startsWith(u8, arg, "-")) {
                return error.InvalidOption;
            } else {
                if (seen_path) return error.TooManyArguments;
                cli.path = try allocator.dupe(u8, arg);
                seen_path = true;
            }
        }
        if (!seen_path) cli.path = try allocator.dupe(u8, ".");
        return cli;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cli = Cli.init(allocator) catch |err| switch (err) {
        error.ShowHelp => return,
        else => {
            std.debug.print("error: {s}\n", .{@errorName(err)});
            try printUsage(true);
            std.process.exit(1);
        },
    };
    defer allocator.free(cli.path);
    var dir = std.fs.cwd().openDir(cli.path, .{.iterate = true}) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("error: directory {s} not found.\n", .{cli.path});
            try printUsage(true);
            std.process.exit(1);
        },
        else => return err,
    };
    defer dir.close();
    var iter = dir.iterate();
    while (try iter.next()) |file| {
        std.debug.print("{s}\n", .{file.name});
    }
}

fn printUsage(to_stderr: bool) !void {
    const out = if (to_stderr) std.fs.File.stderr() else std.fs.File.stdout();
    var buf: [256]u8 = undefined;
    var writer = out.writer(&buf);
    try writer.interface.print(usage, .{});
    try writer.interface.flush();
}
