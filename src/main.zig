const std = @import("std");
const Entry = @import("header.zig").Entry;
const Allocator = std.mem.Allocator;

fn GHashMap(comptime T: type) type {
    return struct {
        const Self = @This();
        buckets: []?*Entry(T),
        nBuckets: u64,

        fn create(allocator: Allocator) !*Self {
            const hashMap = try allocator.create(GHashMap(T));
            errdefer allocator.destroy(hashMap);

            hashMap.nBuckets = 4;
            hashMap.buckets = try allocator.alloc(?*Entry(T), 4);
            hashMap.buckets[0] = null;
            hashMap.buckets[1] = null;
            hashMap.buckets[2] = null;
            hashMap.buckets[3] = null;
            errdefer allocator.free(hashMap.buckets);

            return hashMap;
        }

        fn hash(key: []const u8) u64 {
            var h: u64 = 5381;
            for (key) |c| {
                h = 33 * h + c;
            }
            return h;
        }

        fn get_bucket(self: *Self, key: []const u8) u64 {
            return Self.hash(key) % self.nBuckets;
        }

        fn set(self: *Self, allocator: Allocator, key: []const u8, val: T) !void {
            const bucket = self.get_bucket(key);
            var v = self.buckets[bucket];
            while (v) |_v| {
                var value = _v.*;
                if(std.mem.eql(u8, value.key, key)) {
                    std.debug.print("found", .{ });
                    value.val = val;
                    std.debug.print("{d}", .{ _v.*.val });
                    return;
                }
                v = value.next;
                std.debug.print("{d}", .{ _v.*.val });
            }
            std.debug.print("oh", .{ });
            var newValue = try allocator.create(Entry(T));
            errdefer allocator.destroy(newValue);
            newValue.key = key;
            newValue.val = val;
            newValue.next = self.buckets[bucket];
            self.buckets[bucket] = newValue;
        }
    };
}

const HashMap = GHashMap(u32);

pub fn main() !void {
    var alloc = std.heap.page_allocator;
    const hashMap = try HashMap.create(alloc);
    std.debug.print("{d}\n", .{ hashMap.nBuckets });
    std.debug.print("{d}\n", .{ HashMap.hash("item a") });
    std.debug.print("{d}\n", .{ hashMap.get_bucket("item a") });
    try hashMap.set(alloc, "item a", 1);
    try hashMap.set(alloc, "item a", 2);
    try hashMap.set(alloc, "item e", 3);
    std.debug.print("{d}\n", .{ hashMap.buckets[1].?.*.val });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
