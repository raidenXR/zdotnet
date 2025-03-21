//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const print = std.debug.print;

const numerics = @import("dotnet_classes/numerics.zig");


var v4 = numerics.Vector4{};

pub const Camera = struct 
{
    proj: numerics.Matrix4x4,
    view: numerics.Matrix4x4,

    pos: numerics.Vector3,
    dir: numerics.Vector3,

    pub fn default() Camera 
    {
        return Camera{
            
        };
    }

    pub fn update(c:*Camera) void 
    {
        inline for (0..3) |i| c.pos[i] += 1.0;    
    }
};

const UnaryOp = enum {
    mult,
    id,
    div,
    neg
};

const BinaryOp = enum {
    div,
    sub,
    add,
    mult,
};

const Expr = union(enum) 
{
    number: f64,
    identifier: []const u8,
    mathop: []const u8,
    binary: struct {l: *Expr, r: *Expr, op: BinaryOp},
    unary:  struct {u: *Expr, op: UnaryOp},
    down:   struct {e: *Expr, d: *Expr},
    assignment: struct {name: []const u8, e: *Expr},    
    diff:   struct {*Expr, *Expr},
    prod:   struct {*Expr, *Expr, *Expr},
    none,

    /// insert typle and return an *Expr that is of appropriate union
    pub fn create(allocator: std.mem.Allocator, arg: Expr) *Expr {
        const e = allocator.create(Expr) catch @panic("allocator failed on Expr.create\n");
        e.* = arg;
        return e;
    }

    pub fn printfn(e:*const Expr) void 
    {
        switch (e.*) 
        {
            .identifier => |n| print("identifier: {s}\n", .{n}),
            .number => |n| print("number: {d}\n", .{n}),
            .mathop => |n| print("mathop: {s}\n", .{n}),
            .binary => |b| 
            {
                string(b.l);
                string(b.r);
            },
            .unary => |u| string(u.u),
            .down  => |d| string(d.d), 
            .assignment => |a| 
            {            
                print("assignment: {s}\n", .{a.name});
                string(a.e);
            },
            .diff => |d| 
            {
                string (d[0]);
                string (d[1]);
            },
            .prod => |d| 
            {
                string (d[0]);
                string (d[1]);
                string (d[2]);
            },
            .none => {},            
        }
    }
};

fn string (e: *const Expr) void {
    switch (e.*) {
        .number => |n| {
            print("number: {d}\n", .{n});
        },
        .binary => |b| {
            string(b.l);
            string(b.r);
        },
        .identifier => |n| print("identifier: {s}\n", .{n}),
        .mathop => |n| print("mathop: {s}\n", .{n}),
        .unary => |u| string(u.u),
        .down  => |d| string(d.d), 
        .assignment => |a| {            
            print("assignment: {s}\n", .{a.name});
            string(a.e);
        },
        .diff => |d|
        {
            string (d[0]);
            string (d[1]);
        },
        .prod => |p|
        {
            string (p[0]);
        },
        .none => {},
    }
}


// interface struct
const Subject = struct {
    ctx: *anyopaque,

    dostuff0fn: *const fn (*anyopaque) bool,
    dostuff1fn: *const fn (*anyopaque) void,

    pub fn dostuff0 (s:Subject) bool {
        return s.dostuff0fn (s.ctx);
    }

    pub fn dostuff1 (s:Subject) void {
        s.dostuff1fn (s.ctx);
    }
};


const ConcreteSubject = struct {
    a: u32,
    b: u32,
    i: usize,

    pub fn dostuff0 (s:*ConcreteSubject) bool {
        return if (s.a < 10) true else false;
    }

    pub fn dostuff1 (s:*ConcreteSubject) void {
        const z = s.a + s.b;
        const idx = s.i * s.i - 4;
        std.debug.print("{},  {}\n", .{z, idx});
    }

    // pub fn subject (s:*ConcreteSubject) Subject {
    //     return .{
    //         .ctx = s,
    //         .dostuff0fn = dostuff0,
    //         .dostuff1fn = dostuff1,
    //     };
    // }
};


pub fn main() !void {
    var num = Expr{.number = 456};
    var num2 = Expr{.number = 123};
    var id  = Expr{.identifier = "Gt"};
    var id2  = Expr{.identifier = "id2"};
    var dif  = Expr{.diff = .{&num, &id}};
    var dif2 = Expr{.diff = .{&num2, &id2}};
    var bin = Expr{.binary = .{.l = &dif, .r = &dif2, .op = .div}};
    const fx = Expr{.assignment = .{.name = "f(x)", .e = &bin}};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const expr = Expr.create(allocator, id);

    string(expr);

    string(&fx);    

    fx.printfn();


    // var concreate_subj = ConcreteSubject{.a = 1, .b = 5, .i = 9};
    // const subject = concreate_subj.subject();
    // _ = subject.dostuff0();
    // subject.dostuff1();

    const v0 = std.mem.zeroes(numerics.Vector4);
    print("vector: {any}\n", .{v0});

    const b0 = std.mem.zeroes([10]u8);
    print("buffer: {any}\n", .{b0});

    const v = numerics.vec2.transformNormal(numerics.vec2.Zero, numerics.mat3x2.identity);
    _ = v;
}
