const std = @import("std");

const regular = [_][]const u8
{
    "fonts/KaTeX_AMS-Regular.ttf",
    "fonts/KaTeX_Main-Regular.ttf",
    "fonts/KaTeX_Size1-Regular.ttf",
    "fonts/KaTeX_Size2-Regular.ttf",
    "fonts/KaTeX_Size3-Regular.ttf",
    "fonts/KaTeX_Size4-Regular.ttf",
    "fonts/KaTeX_Script-Regular.ttf",
    "fonts/KaTeX_Fraktur-Regular.ttf",
    "fonts/KaTeX_SansSerif-Regular.ttf",
    "fonts/KaTeX_Typewriter-Regular.ttf",        
    "fonts/KaTeX_Caligraphic-Regular.ttf",        
};    

const italic = [_][]const u8
{
    "fonts/KaTeX_Main-Italic.ttf",
    "fonts/KaTeX_Math-Italic.ttf",
    "fonts/KaTeX_SansSerif-Italic.ttf",  
};

const bold = [_][]const u8
{
    "fonts/KaTeX_Main-Bold.ttf",        
    "fonts/KaTeX_Fraktur-Bold.ttf",
    "fonts/KaTeX_SansSerif-Bold.ttf",
    "fonts/KaTeX_Caligraphic-Bold.ttf",   
};

const bolditalic = [_][]const u8
{
    "fonts/KaTeX_Main-BoldItalic.ttf",
    "fonts/KaTeX_Math-BoldItalic.ttf",
};

const allfonts = regular ++ italic ++ bold ++ bolditalic;

const fontsize  = 18.0;
const binoffset = 4.0;


pub const Size = struct {w:f32, h:f32};
pub const HBox = struct {dy1:f32, dy2:f32};

pub const SKPoint = struct {x:f32, y:f32};

inline fn transform (x:f32, y:f32, size:Size) SKPoint
{
    return SKPoint{.x = x, .y = size.h - y};
}

fn selectfont (fonts: []*c.SKTypeface, str:[]const u8) *c.SKTypeFace 
{
    for (fonts) |font|
    {
        if (c.SKTypeface.ContainsGlyph(font, str)) return font;
    }

    return selectfont (allfonts, str);
}

const paint = c.SKPaint_new();


pub const Expr = union(enum)
{
    number:     f64,
    identifier: []const u8,
    mathop:     []const u8,
    unary:      struct {rhs:*Expr, op:enum{div, mult, add}},
    binary:     struct {lhs:*Expr, rhs:*Expr},    
};

const Measure = struct
{
    pub fn width (str:[]const u8, font:*c.Typeface) f32
    {
        return c.SKPaint_measure (paint, font, str);
    }

    pub fn size (expr:*const Expr, s:f32) Size
    {
        return switch (expr.*)
        {
            .number => |n| blk:
            {
                const t = regular[1];
                const w = s * width (n, t);
                const h = s * fontsize;
                break :blk Size{.w = w, .h = h};
            },
            .identifier => |n| blk:
            {
                const t = selectfont (italic, n);
                const w = s * width (n, t);
                const h = s * fontsize;
                break :blk Size{.w = w, .h = h};                
            },
            .mathop => |n| blk:
            {
                const t = selectfont (regular, n);
                const w = s * width (n, t);
                const h = s * fontsize;
                break :blk Size{.w = w, .h = h};
            },
            .binary => |e| blk:
            {
                const l_size = size (e.lhs, s);
                const r_size = size (e.rhs, s);
                const w = @max (l_size.w, r_size.w);
                const h = l_size.h + r_size.h + 4;
                break :blk Size{.w = w, .h = h};
            }
        };
    }    


    pub fn hbox (expr:*const Expr, s:f32) HBox
    {
        
    }
};
