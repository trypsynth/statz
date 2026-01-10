const std = @import("std");
const Cli = @import("cli.zig").Cli;
const Stats = @import("stats.zig").Stats;

pub fn walk(dir: std.fs.Dir, options: *const Cli, stats: *Stats) !void {
    var path_buf: std.ArrayList(u8) = .{};
    defer path_buf.deinit(options.allocator);
    try walkDir(dir, options, stats, &path_buf);
}

fn walkDir(
    dir: std.fs.Dir,
    options: *const Cli,
    stats: *Stats,
    path_buf: *std.ArrayList(u8),
) !void {
    var iter = dir.iterate();
    while (true) {
        const entry = iter.next() catch |err| {
            if (options.verbose) std.debug.print("warning: iteration error: {s}\n", .{@errorName(err)});
            continue;
        } orelse break;
        if (!options.hidden_files and entry.name.len > 0 and entry.name[0] == '.') continue;
        const start_len = path_buf.items.len;
        if (start_len > 0) try path_buf.append(options.allocator, '/');
        try path_buf.appendSlice(options.allocator, entry.name);
        const full_path = path_buf.items;
        if (entry.kind == .directory) {
            stats.dir_count += 1;
        } else {
            stats.file_count += 1;
            if (dir.statFile(entry.name)) |stat| {
                const size: u64 = @intCast(stat.size);
                stats.total_bytes += size;
                try stats.addExtension(entry.name, size);
            } else |_| {
                try stats.addExtension(entry.name, 0);
            }
        }
        if (entry.kind == .directory) {
            var subdir = dir.openDir(entry.name, .{
                .iterate = true,
                .no_follow = !options.symlinks,
            }) catch |err| {
                if (options.verbose) std.debug.print("warning: cannot open {s}: {s}\n", .{ full_path, @errorName(err) });
                path_buf.shrinkRetainingCapacity(start_len);
                continue;
            };
            defer subdir.close();
            try walkDir(subdir, options, stats, path_buf);
        }
        path_buf.shrinkRetainingCapacity(start_len);
    }
}
