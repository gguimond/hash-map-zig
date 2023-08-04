pub fn Entry(comptime T: type) type {
    return struct{
        key: []const u8,
        val: T,
        next: ?*Entry(T)
    };
}
