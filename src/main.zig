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
            std.debug.print("\n set: {d}", .{ val });
            const bucket = self.get_bucket(key);
            var v = self.buckets[bucket];
            while (v) |_v| {
                if(std.mem.eql(u8, _v.key, key)) {
                    std.debug.print("\n found", .{ });
                    _v.val = val;
                    std.debug.print("\n {d}", .{ _v.val });
                    return;
                }
                v = _v.next;
                std.debug.print("\n {d}", .{ _v.val });
            }
            std.debug.print("oh", .{ });
            var newValue = try allocator.create(Entry(T));
            errdefer allocator.destroy(newValue);
            newValue.key = key;
            newValue.val = val;
            newValue.next = self.buckets[bucket];
            self.buckets[bucket] = newValue;
        }

        fn get(self: *Self, key: []const u8) ?T {
            const bucket = self.get_bucket(key);
            var v = self.buckets[bucket];
            while (v) |_v| {
                if(std.mem.eql(u8, _v.key, key)) {
                    return _v.val;
                }
                v = _v.next;
            }
            return null;
        }

        fn delete(self: *Self, allocator: Allocator, key: []const u8) void {
            const bucket = self.get_bucket(key);
            var prev: ?*Entry(T) = null;
            var v = self.buckets[bucket];
            while (v) |_v| {
                if(std.mem.eql(u8, _v.key, key)) {
                    if(prev) |_prev|{
                        _prev.next = _v.next;
                    } else {
                        self.buckets[bucket] = _v.next;
                    }
                    allocator.destroy(_v);
                    return;
                }
                prev = _v;
                v = _v.next;
            }
        }

        fn free(self: *Self, allocator: Allocator) void {
            for(self.buckets) |val| {
                var v = val;
                while (v) |_v| {
                    var next = _v.next;
                    std.debug.print("\n destroy \n {d}", .{ _v.val });
                    allocator.destroy(_v);
                    v = next;
                }
            }
            allocator.free(self.buckets);
            allocator.destroy(self);
        }
    };
}

const HashMap = GHashMap(u32);

pub fn main() !void {
    var alloc = std.heap.page_allocator;
    const hashMap = try HashMap.create(alloc);
    std.debug.print("{d}\n", .{ hashMap.nBuckets });
    std.debug.print("{d}\n", .{ HashMap.hash("item a") });
    std.debug.print("bucket: {d}\n", .{ hashMap.get_bucket("item a") });
    std.debug.print("bucket: {d}\n", .{ hashMap.get_bucket("item e") });

    try hashMap.set(alloc, "item a", 1);
    try hashMap.set(alloc, "item a", 2);
    try hashMap.set(alloc, "item e", 3);
    try hashMap.set(alloc, "item z", 7);
    std.debug.print("\nvalue raw : {d}\n", .{ hashMap.buckets[1].?.*.val });
    if(hashMap.get("item a")) |val|{
        std.debug.print("\nvalue a get : {d}\n", .{ val });
    }
    if(hashMap.get("item e")) |val|{
        std.debug.print("\nvalue e get : {d}\n", .{ val });
    }
    hashMap.delete(alloc, "item e");
    if(hashMap.get("item e")) |val|{
        std.debug.print("\nvalue e get : {d}\n", .{ val });
    }
    hashMap.free(alloc);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
