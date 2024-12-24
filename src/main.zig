//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const print = std.debug.print;

const numerics = @import("numerics.zig");


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

const Expr = union(enum) {
    number: f64,
    identifier: []const u8,
    mathop: []const u8,
    binary: struct {l: *Expr, r: *Expr, op: BinaryOp},
    unary:  struct {u: *Expr, op: UnaryOp},
    down:   struct {e: *Expr, d: *Expr},
    assignment: struct {name: []const u8, e: *Expr},    
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
            .binary => |b| {
                string(b.l);
                string(b.r);
            },
            .unary => |u| string(u.u),
            .down  => |d| string(d.d), 
            .assignment => |a| {            
                print("assignment: {s}\n", .{a.name});
                string(a.e);
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
        .identifier => |n| print("identifier: {s}\n", .{n}),
        .mathop => |n| print("mathop: {s}\n", .{n}),
        .binary => |b| {
            string(b.l);
            string(b.r);
        },
        .unary => |u| string(u.u),
        .down  => |d| string(d.d), 
        .assignment => |a| {            
            print("assignment: {s}\n", .{a.name});
            string(a.e);
        },
        .none => {},
    }
}


pub fn main() !void {
    var num = Expr{.number = 456};
    var id  = Expr{.identifier = "Gt"};
    var bin = Expr{.binary = .{.l = &num, .r = &id, .op = .div}};
    const fx = Expr{.assignment = .{.name = "f(x)", .e = &bin}};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const expr = Expr.create(allocator, id);

    string(expr);

    string(&fx);    

    fx.printfn();
}
