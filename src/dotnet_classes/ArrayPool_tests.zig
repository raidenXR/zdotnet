const ArrayPool = @import("ArrayPool.zig");
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

test "test ArrayPool" {
    const U32Pool = ArrayPool.create(u32, 100, 10);
    const array = U32Pool.rentT(20);
    defer _ = U32Pool.returnT(array, false);

    // assert (array.len <= 20);
    print("array len: {}\n", .{array.len});   
}
