const genAlg = @import("genAlg.zig");

const numerics = @import("numerics.zig");
const Vector3 = numerics.Vector3;
const Vector4 = numerics.Vector4;

const std = @import("std");
const print = std.debug.print;


// fn printP (p:*Population(Vector4), i:usize) void
// {
//     print("{d}, fitness: {d}\n", .{p.population[i], p.fitness[i]});
// }

fn initV (i:usize) Vector4 
{
    const v: f32 = @floatFromInt(i);
    return Vector4{v, 2.8 * v, v - 1.3, v + 0.4};
}

fn mutV (v:Vector4) Vector4 
{
    return Vector4{v[0], v[1], v[1], v[0]};
}

fn consV (v:Vector4) Vector4
{
    return Vector4{
        if (v[0] < 0.0) 0.0 else v[0],
        if (v[1] > 10.0) 10.0 else v[1],
        v[2],
        v[3],
    };
}

fn cross (a:Vector4, b:Vector4) [2]Vector4
{
    const v0 = Vector4{a[0], a[1], b[2], b[3]};
    const v1 = Vector4{b[0], b[1], a[2], a[3]};

    return .{v0,v1};
}

fn fit (v:Vector4) f64
{
    return (v[0] - v[1]) * @sqrt(v[2] / (v[3] + 1.0)); 
}

test "test genAlg" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const Population = genAlg.Population(Vector4, initV, fit, mutV, consV, cross, undefined);
    
    var p = try Population.init(gpa.allocator(), 30);
    var m = try Population.init(gpa.allocator(), 30);
    defer p.deinit();
    defer m.deinit();

    for (0..100) |_| 
    {
        p.initialize ();
        p.mutate ();
        p.crossover (&m);
        p.constraint ();
        p.fit ();
        p.sortByFitness();        
    }

    for (p.population, p.fitness) |g, f|
    {
        print("{d}, fitness: {d}\n", .{g, f});        
    }     
}
