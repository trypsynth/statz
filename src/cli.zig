const std = @import("std");

pub const SizeFormat = enum {
    binary,
    decimal,
    raw,
};

pub const usage =
    \\statz - fast folder analysis tool.
    \\
    \\usage: sz [<path>] [<options>...]
    \\
    \\Arguments:
    \\  <path> the path to analyze, defaults to the CWD
    \\
    \\Options:
    \\  -f, --format <format> set size display format: binary (default), decimal, or raw
    \\  -H, --hidden include hidden files in the analysis
    \\  -s, --symlinks follow symlinks when analyzing (use with care to avoid circular symlinks)
    \\  -v, --verbose show much more detailed analysis results
    \\
;

pub const Cli = struct {
    path: []const u8,
    hidden_files: bool = false,
    symlinks: bool = false,
    verbose: bool = false,
    size_format: SizeFormat = .binary,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Cli {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();
        if (!args.skip()) return error.MissingProgramName;
        var cli = Cli{
            .path = "",
            .allocator = allocator,
        };
        var seen_path = false;
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                printUsage(false);
                return error.ShowHelp;
            } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
                cli.verbose = true;
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--symlinks")) {
                cli.symlinks = true;
            } else if (std.mem.eql(u8, arg, "-H") or std.mem.eql(u8, arg, "--hidden")) {
                cli.hidden_files = true;
            } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--format")) {
                const fmt_arg = args.next() orelse return error.MissingFormatValue;
                cli.size_format = std.meta.stringToEnum(SizeFormat, fmt_arg) orelse return error.InvalidFormatValue;
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

    pub fn deinit(self: *const Cli) void {
        self.allocator.free(self.path);
    }
};

pub fn printUsage(to_stderr: bool) void {
    const file = if (to_stderr) std.fs.File.stderr() else std.fs.File.stdout();
    file.writeAll(usage) catch {};
}
