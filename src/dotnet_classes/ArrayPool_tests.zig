const ArrayPool = @import("ArrayPool.zig");
const numerics = @import("numerics.zig");
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

test "test ArrayPool" {
    const Vec3Pool = ArrayPool.create(numerics.Vector3, 100, 10);
    const vecs = Vec3Pool.rentT(50);
    
    for (0..10) |i| vecs[i] = numerics.vec3.UnitX;
    for (10..20) |i| vecs[i] = numerics.vec3.UnitY;
    for (20..30) |i| vecs[i] = numerics.vec3.UnitZ;
    
    defer _ = Vec3Pool.returnT(vecs, false);

    print("array len: {d}\n", .{vecs.len});   
    for (vecs[0..30]) |v| std.debug.print("vec: {any}\n", .{v}); 
}
