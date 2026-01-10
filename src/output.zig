const std = @import("std");
const Stats = @import("stats.zig").Stats;
const SizeFormat = @import("cli.zig").SizeFormat;

pub fn printSummary(stats: *const Stats, size_format: SizeFormat) !void {
    var buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buf);
    const w = &writer.interface;
    try w.print("Statz:\n", .{});
    try w.print("  Total files counted: {d}.\n", .{stats.file_count});
    try w.print("  Total directories counted: {d}.\n", .{stats.dir_count});
    try w.print("  Total size: ", .{});
    try writeBytes(w, stats.total_bytes, size_format);
    try w.print("\n", .{});
    try w.flush();
}

fn writeBytes(w: *std.Io.Writer, bytes: u64, format: SizeFormat) !void {
    switch (format) {
        .raw => try w.print("{d} B", .{bytes}),
        .binary, .decimal => {
            const units = switch (format) {
                .binary => [_][]const u8{ "B", "KiB", "MiB", "GiB", "TiB" },
                .decimal => [_][]const u8{ "B", "KB", "MB", "GB", "TB" },
                .raw => unreachable,
            };
            const divisor: f64 = if (format == .binary) 1024 else 1000;
            var size: f64 = @floatFromInt(bytes);
            var unit_idx: usize = 0;
            while (size >= divisor and unit_idx < units.len - 1) {
                size /= divisor;
                unit_idx += 1;
            }
            if (unit_idx == 0) {
                try w.print("{d} {s}", .{ bytes, units[unit_idx] });
            } else {
                try w.print("{d:.1} {s}", .{ size, units[unit_idx] });
            }
        },
    }
}
