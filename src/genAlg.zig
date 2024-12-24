const std = @import("std");


pub fn Population(comptime T:type) type
{
    return struct 
    {
        population: []T,
        generation: []i32,
        fitness:    []f64,
        
        capacity: usize,
        count:    usize,   

        const Self = @This();

        pub fn init (allocator: std.mem.Allocator, n:usize) !Self
        {
            return .{
                .population = try allocator.alloc(T, n),
                .generation = try allocator.alloc(i32, n),
                .fitness = try allocator.alloc(f64, n),
                .count = 0,
                .capacity = n,
            }; 
        }  

        inline fn swap (s:*Self, a:usize, b:usize) void
        {
            const pa = s.population[a];
            const pb = s.population[b];
            const ga = s.generation[a];
            const gb = s.generation[b];
            const fa = s.fitness[a];
            const fb = s.fitness[b];

            s.population[a] = pb;
            s.population[b] = pa;
            s.generation[a] = gb;
            s.generation[b] = ga;
            s.fitness[a] = fb;
            s.fitness[b] = fa;
        }

        pub fn sortByFitness (s:*Self) void
        {
            for (0..s.count - 1) |i|
            {
                for (i..s.count) |j|
                {
                    if (s.fitness[i] < s.fitness[j]) swap(s, i, j);
                }
            }
        }
        
        pub fn sortByFitnessDescending (s:*Self) void
        {
            for (0..s.count - 1) |i|
            {
                for (i..s.count) |j|
                {
                    if (s.fitness[i] > s.fitness[j]) swap(s, i, j);
                }
            }
        }

        pub fn iteri (s:*Self, f:*const fn(*Self, usize) void) void
        {
            for (0..s.count) |i| f(s, i);            
        }

        pub const initialfn    = *const fn (usize) T;
        pub const fitnessfn    = *const fn (T) f64;
        pub const mutationfn   = *const fn (T) T;
        pub const constraintfn = *const fn (T) T;
        pub const crossoverfn  = *const fn (T, T) [2]T;
        pub const selectionfn  = *const fn (Population(T), Population(T)) void; 

        pub fn initialize (s:*Self, f:initialfn) void
        {
            for (0..s.capacity) |i| s.population[i] = f (i);
            s.count = s.capacity;
        }

        pub fn fit (s:*Self, f:fitnessfn) void
        {
            for (0..s.count) |i| s.fitness[i] = f (s.population[i]);
        }

        pub fn mutate (s:*Self, f:mutationfn) void
        {
            for (0..s.count) |i| s.population[i] = f (s.population[i]);
        }

        pub fn constraint (s:*Self, f:constraintfn) void
        {
            for (0..s.count) |i| s.population[i] = f (s.population[i]);
        }

        pub fn crossover (a:*Self, b:*Self, f:crossoverfn) void
        {
            const len = if (b.count % 2 == 0) b.count else b.count - 1;
            var i: usize = 0;
            while (i < len) : (i += 2) 
            {
                const pA = b.population[i + 0];
                const pB = b.population[i + 1];
                const cs = f (pA, pB);
                
                a.population[i + 0] = cs[0];
                a.population[i + 1] = cs[1];
            }
        }

        pub fn selection (a:*Self, b:*Self, f:selectionfn) void
        {
            f (a, b);
        }
    };
}
