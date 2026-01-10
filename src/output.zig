const std = @import("std");
const Stats = @import("stats.zig").Stats;
const FileEntry = @import("stats.zig").FileEntry;

pub fn printSummary(stats: *const Stats) !void {
    var buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buf);
    const w = &writer.interface;
    try w.print("Statz:\n", .{});
    try w.print("  Total files counted: {d}.\n", .{stats.file_count});
    try w.print("  Total directories counted: {d}.\n", .{stats.dir_count});
    try w.print("  Total size: ", .{});
    try writeBytes(w, stats.total_bytes);
    try w.print("\n", .{});
    try w.flush();
}

fn writeBytes(w: *std.Io.Writer, bytes: u64) !void {
    const units = [_][]const u8{ "B", "KB", "MB", "GB", "TB" };
    var size: f64 = @floatFromInt(bytes);
    var unit_idx: usize = 0;
    while (size >= 1024 and unit_idx < units.len - 1) {
        size /= 1024;
        unit_idx += 1;
    }
    if (unit_idx == 0) {
        try w.print("{d} {s}", .{ bytes, units[unit_idx] });
    } else {
        try w.print("{d:.1} {s}", .{ size, units[unit_idx] });
    }
}
