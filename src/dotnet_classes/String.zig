const std = @import("std");
const Allocator = std.mem.Allocator;

const trim_head = 0;
const trim_tail = 1;
const trim_both = 2;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const gpa_allocator = gpa.allocator();
var no_of_strings: usize = 0;

var intern_table  = std.StringHashMap(void).init(gpa_allocator);
var buffer_stack  = std.ArrayList([]u8).init(gpa_allocator); 

var total_allocation: usize = 0;   // counts the total allocation of strings NOT contained in string_stack
var stack_allocation: usize = 0;   // counts the total allocation of strings contained in string_stack
var string_allocated: usize = 0;   // counts the number of string NOT in stack/pool


fn fastAlloc (allocator:std.mem.Allocator, size:usize) []u8 
{
    return buffer: {
        for (buffer_stack.items, 0..) |buf, i| 
        {
            if (buf.len >= size)
            {
                stack_allocation -= size;
                break :buffer buffer_stack.orderedRemove(i);
            }
            else {
                total_allocation += size;
                string_allocated += 1;
                break :buffer allocator.alloc(u8, size) catch @panic ("allocator failed to alloc buffer for string");                   
            }
        }
    }; 
}

fn fastFree (buffer:[]u8) void
{
    buffer_stack.append(buffer) catch @panic ("fastFree() failed");
    stack_allocation += buffer.len;
}

pub const Empty: []const u8 = &[0]u8{};

/// Concatenates the elements of a specified String array.
pub fn concat (allocator:Allocator, values:[]const[]const u8) []const u8
{
    var total_len: usize = 0;
    for (values) |s| total_len += s.len;

    var buffer = allocator.alloc(u8, total_len) catch @panic("String.concat() panicked");
    var index: usize = 0;

    for (values) |s| 
    {
        @memcpy(buffer[index..index + s.len], s);    
        index += s.len;
    }

    return buffer;
}

/// Returns a value indicating whether a specified string occurs within this string.
pub fn contains (s:[]const u8, a:[]const u8) bool
{
    if (a.len > s.len) return false;

    var n: usize = 0;
    while (n + a.len < s.len) : (n += 1) 
    {
        if (std.mem.eql(u8, s[n..n + a.len], a)) return true;
    }

    return false;
}

/// Determines whether the end of this string instance matches the specified string.
pub fn endsWith (s:[]const u8, value:[]const u8) bool
{      
    return if (value.len > s.len) false else std.mem.eql(u8, s[s.len - value.len..], value);
}

/// Determines whether two specified String objects have the same value.
pub fn equals (s:[]const u8, value:[]const u8) bool
{
    if (s.len != value.len) 
    {
        return false;
    }
    else if (s.len == value.len and s.len == 0)
    {
        return true;
    } 
    else if (s.len == value.len and s[0] == value[0])
    {
        return std.mem.eql(u8, s, value);    
    }
    else return false;
}


/// Reports the zero-based index of the first occurrence of the specified Unicode character in this string.
pub fn indexOf (s:[]const u8, char:u8) usize
{
    var n: usize = 0;
    while (char != s[n] and n < s.len) n += 1;

    return n;
}

/// Indicates whether the specified string is null or an empty string 
pub fn isEmpty (s:[]const u8) bool
{
    return s.len == 0;
}

pub fn split (allocator:Allocator, str:[]const u8, chars:[]const u8) []const[]const u8
{
    var a: usize = 0;
    var b: usize = 0;
    var list = std.ArrayListUnmanaged([]const u8){};

    while (b < str.len) : (b += 1)
    {
        for (chars) |c|
        {
            if (str[b] == c)
            {
                list.append(allocator, str[a..b]) catch @panic("String.split() panicked");
                b += 1;
                a = b;
            }
        }
    }

    return list.items;
}

