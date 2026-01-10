const std = @import("std");

pub const ExtensionStats = struct {
    count: usize,
    total_bytes: u64,
};

pub const Stats = struct {
    file_count: usize = 0,
    dir_count: usize = 0,
    total_bytes: u64 = 0,
    by_extension: std.StringHashMap(ExtensionStats),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Stats {
        return .{
            .by_extension = std.StringHashMap(ExtensionStats).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Stats) void {
        var iter = self.by_extension.keyIterator();
        while (iter.next()) |key| {
            self.allocator.free(key.*);
        }
        self.by_extension.deinit();
    }

    pub fn addExtension(self: *Stats, filename: []const u8, size: u64) !void {
        const ext = getExtension(filename);
        const result = self.by_extension.getOrPut(ext) catch |err| return err;
        if (result.found_existing) {
            result.value_ptr.count += 1;
            result.value_ptr.total_bytes += size;
        } else {
            result.key_ptr.* = try self.allocator.dupe(u8, ext);
            result.value_ptr.* = .{
                .count = 1,
                .total_bytes = size,
            };
        }
    }
};

fn getExtension(filename: []const u8) []const u8 {
    var i: usize = filename.len;
    while (i > 0) {
        i -= 1;
        if (filename[i] == '.') {
            if (i == 0) return "(no ext)";
            return filename[i..];
        }
    }
    return "(no ext)";
}
