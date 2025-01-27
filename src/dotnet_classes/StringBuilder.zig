const std = @import("std");
const Allocator = std.mem.Allocator;
const String = @import("String.zig");

ptr: [*]u8,
len: usize,
capacity: usize,
allocator: Allocator,


const StringBuilder = @This();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const gpa_allocator = gpa.allocator();
var buffer_stack  = std.ArrayList([]u8).init(gpa_allocator); 

var total_allocation: usize = 0;   // counts the total allocation of strings NOT contained in string_stack
var stack_allocation: usize = 0;   // counts the total allocation of strings contained in string_stack
var string_allocated: usize = 0;   // counts the number of string NOT in stack/pool

fn fastAlloc (size:usize) []u8 
{
    for (buffer_stack.items, 0..) |buf, i| 
    {
        if (buf.len >= size)
        {
            stack_allocation -= size;
            return buffer_stack.swapRemove(i);
        }
    }

    total_allocation += size;
    string_allocated += 1;
    return gpa_allocator.alloc(u8, size) catch @panic ("allocator failed to alloc buffer for string");                   
}

fn fastFree (buffer:[]u8) void
{
    buffer_stack.append(buffer) catch @panic ("fastFree() failed");
    stack_allocation += buffer.len;
}

/// Initializes a new instance of the StringBuilder class using the specified capacity.
pub fn init (allocator:Allocator, capacity:usize) StringBuilder
{
    const buffer = allocator.alloc(u8, capacity) catch @panic ("StringBuilder.init() failed");
    
    return StringBuilder{
        .ptr = buffer.ptr,
        .len = 0,
        .capacity = capacity,
        .allocator = allocator,
    };      
}    

pub fn deinit (sb:StringBuilder) void
{
    sb.allocator.free(sb.ptr[0..sb.capacity]);
}

fn resize (sb:*StringBuilder, new_capacity:usize) void
{
    const buffer = sb.allocator.alloc(u8, new_capacity) catch @panic ("StringBuilder.append() failed");
    
    @memcpy (buffer[0..sb.len], sb.ptr[0..sb.len]);
    sb.allocator.free(sb.ptr[0..sb.capacity]);

    sb.ptr = buffer.ptr;
    sb.len = sb.len;
    sb.capacity = new_capacity;          
}

/// Appends the string representation of a specified read-only character span to this instance.
pub fn append (sb:*StringBuilder, chars:[]const u8) void
{
    if (sb.capacity < sb.len + chars.len)
    {
        const new_capacity = sb.capacity + 2 * chars.len;
        sb.resize(new_capacity);
    }
    @memcpy (sb.ptr[sb.len..sb.len + chars.len], chars);
    sb.len += chars.len; 
}

/// Appends a copy of the specified string followed by the default line terminator to the end of the current StringBuilder object.
pub fn appendLine (sb:*StringBuilder, chars:[]const u8) void
{
    sb.append(chars);
    sb.append("\n");
}

/// Appends the string returned by processing a composite format string, which contains zero or more format 
/// items, to this instance. Each format item is replaced by the string representation of a single argument.
pub fn appendFormat (sb:*StringBuilder, comptime fmt:[]const u8, args:anytype) void 
{
    const buffer = fastAlloc (1024);
    defer fastFree (buffer);
    const line = std.fmt.bufPrintZ(buffer, fmt, args) catch @panic ("StringBuilder.appendFormat() failed");    

    sb.append(line);
}

/// Copies the characters from a specified segment of this instance to a destination Char span.
pub fn copyTo (sb:StringBuilder, buffer:[]u8) []const u8
{
    @memcpy (buffer, sb.toCharsArray());

    return buffer[0..sb.len];
}

/// Removes all characters from the current StringBuilder instance.
pub fn clear (sb:*StringBuilder) void
{
    sb.len = 0;
}

/// Inserts the string representation of a specified array of Unicode characters into this instance at the specified character position.
pub fn insert (sb:*StringBuilder, position:usize, chars:[]const u8) void
{
    if (sb.capacity < position + chars.len) sb.resize(sb.capacity * 2);

    const len  = chars.len + sb.len - position;
    const temp = fastAlloc (len);
    defer fastFree (temp);

    @memcpy (temp[0..chars.len], chars);
    // std.debug.print("len1: {}, len2: {}\n", .{len - chars.len, sb.slice(position).len});
    @memcpy (temp[chars.len..chars.len + sb.slice(position).len], sb.slice(position));
    @memcpy (sb.ptr[position..], temp[0..len]);
    sb.len = position + len;
}

/// Removes the specified range of characters from this instance.
pub fn remove (sb:*StringBuilder, position:usize, end:usize) void
{
    const len = sb.len - end;
    const temp = fastAlloc (len);
    defer fastFree (temp);

    @memcpy (temp[0..len], sb.ptr[end..sb.len]);
    @memcpy (sb.ptr[position..], temp[0..len]);
    sb.len = sb.len - (end - position);
}

/// Replaces all occurrences of a specified string in this instance with another specified string.
pub fn replace (sb:*StringBuilder, old_value:[]const u8, new_value:[]const u8) void
{
    var i: usize = 0;
    while (i + old_value.len < sb.len) : (i += 1)
    {
        if (String.equals(sb.ptr[i..i + old_value.len], old_value))
        {
            sb.remove(i, i + old_value.len);
            sb.insert(i, new_value);
            i += new_value.len;
        }
    }
}
    
pub fn toString (sb:StringBuilder, allocator:Allocator) []const u8
{
    const buffer = allocator.alloc(u8, sb.len) catch @panic("StringBuilder.toString panicked");
    @memcpy (buffer, sb.toCharsArray());

    return buffer;
}

pub fn toCharsArray (sb:StringBuilder) []const u8
{
    return sb.ptr[0..sb.len];
}

fn slice (sb:StringBuilder, position:usize) []const u8
{
    return sb.ptr[position..sb.len];
}

fn string (ctx:anytype) []const u8
{
    return ctx.toString();
}
