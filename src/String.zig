const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const assert = std.debug.assert;


pub const Empty: []const u8 = &[0]u8{};

/// Compares substrings of two specified String objects using the specified rules, 
/// and returns an integer that indicates their relative position in the sort order.
pub fn compare (a:[]const u8, b:[]const u8) i32
{
    const len = @min (a.len, b.len);    
    var i: usize = 0;
    var r: i32 = 0;
    while (i < len and a[i] == b[i]) : (i += 1)
    {
        r = @as(i32, @intCast(a[i])) - @as(i32, @intCast(b[i]));
    }

    return r;
}

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
    if (a.len == s.len) return std.mem.eql(u8, s, a);
    
    if (a.len > s.len) return false;

    var n: usize = 0;
    while (n + a.len <= s.len) : (n += 1) 
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

/// Concatenates the members of a collection, using the specified separator between each member.
pub fn join (allocator:Allocator, separator:[]const u8, values: []const[]const u8) []const u8
{
    var total_len: usize = 0;
    for (values) |s| total_len += s.len + separator.len;

    const buffer = allocator.alloc(u8, total_len) catch @panic("String.join failed");
    // var idx: usize = 0;
    var ptr = buffer.ptr;

    for (values) |s| 
    {
        @memcpy(ptr[0..s.len], s);
        ptr += s.len;
        @memcpy(ptr[0..separator.len], separator);
        ptr += separator.len;
    }

    return buffer;
}   

/// Reports the zero-based index position of the last occurrence of a specified Unicode character within this instance.
pub fn lastIndexOf (s:[]const u8, char:u8) usize 
{
    var n = s.len - 1;
    while (n > 0 and s[n] != char) n -= 1;

    return n;     
}

/// Returns a new string that right-aligns the characters in this instance by padding them 
/// on the left with a specified Unicode character, for a specified total length.
pub fn padLeft (allocator:Allocator, s:[]const u8, n:usize, pad:u8) []const u8
{
    const buffer = allocator.alloc(u8, s.len + n) catch @panic("String.padLeft failed");

    for (0..n) |i| buffer[i] = pad;
    @memcpy (buffer[n..n + s.len], s);

    return buffer;
}

/// Returns a new string that right-aligns the characters in this instance by padding them 
/// on the right with a specified Unicode character, for a specified total length.
pub fn padRight (allocator:Allocator, s:[]const u8, n:usize, pad:u8) []const u8
{
    const buffer = allocator.alloc(u8, s.len + n) catch @panic("String.padLeft failed");

    @memcpy (buffer[0..s.len], s);
    for (s.len..s.len + n) |i| buffer[i] = pad;

    return buffer;
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

/// Determines whether the beginning of this string instance matches the specified string.
pub fn startsWith (s:[]const u8, value:[]const u8) bool 
{
    return if (value.len > s.len) false else std.mem.eql(u8, s[0..value.len], value);
}

/// Returns a copy of this string converted to lowercase.
pub fn toLower (allocator:Allocator, s:[]const u8) []const u8
{
    const buffer = allocator.alloc(u8, s.len) catch @panic("String.toLower failed");
    
    return std.ascii.lowerString(buffer, s);
}

/// Returns a copy of this string converted to uppercase.
pub fn toUpper (allocator:Allocator, s:[]const u8) []const u8 
{
    const buffer = allocator.alloc(u8, s.len) catch @panic("String.toUpper failed");
    
    return std.ascii.upperString(buffer, s);
}

/// Removes all leading and trailing instances of a character from the current string.
pub fn trim (allocator:Allocator, s:[]const u8, char:u8) []const u8
{
    var l: usize = 0;
    var r: usize = s.len - 1;

    while (l < s.len and s[l] == char) l += 1;
    while (r > 0 and s[r] == char) r -= 1;    

    const buffer = allocator.alloc(u8, r - l) catch @panic("String.trim failed");
    @memcpy (buffer, s[l..r]);

    return buffer;
}


/// Removes all leading and trailing instances of a character from the current string.
pub fn trimNoAlloc (s:[]const u8, char:u8) []const u8
{
    var l: usize = 0;
    var r: usize = s.len - 1;

    while (l < s.len and s[l] == char) l += 1;
    while (r > 0 and s[r] == char) r -= 1;   

    return s[l..r + 1];
}

/// Removes all the trailing occurrences of a set of characters specified in an array from the current string.
pub fn trimEnd (allocator:Allocator, s:[]const u8, char:u8) []const u8 
{
    var r: usize = s.len - 1;

    while (r > 0 and s[r] == char) r -= 1;
    
    const buffer = allocator.alloc(u8, r) catch @panic("String.trimEnd failed");
    @memcpy (buffer, s[0..r]);
    
    return buffer;
}


/// Removes all the trailing occurrences of a set of characters specified in an array from the current string.
pub fn trimEndNoAlloc (s:[]const u8, char:u8) []const u8 
{
    var r: usize = s.len - 1;

    while (r > 0 and s[r] == char) r -= 1;
    
    return s[0..r + 1];
}

/// Removes all the leading occurrences of a specified character from the current string.
pub fn trimStart (allocator:Allocator, s:[]const u8, char:u8) []const u8
{
    var l: usize = 0;

    while (l < s.len and s[l] == char) l += 1;

    const len = s.len - (l);
    const buffer = allocator.alloc(u8, len) catch @panic("String.trimEnd failed");
    @memcpy (buffer, s[l..]);

    return buffer;
}


/// Removes all the leading occurrences of a specified character from the current string.
pub fn trimStartNoAlloc (s:[]const u8, char:u8) []const u8
{
    var l: usize = 0;

    while (l < s.len and s[l] == char) l += 1;

    return s[l..];
}

pub fn asSpan (s:[]const u8, start:usize, len:usize) []const u8
{
    return s[start..start + len];
}


// tests

test "test trim" {
    const str = "   some string   ";
    const s = trimNoAlloc(str, ' ');
    std.debug.print("-{s}-\n", .{s});
    
    const num = " -34.124 ";
    const sn = trimNoAlloc(num, ' ');
    const n = try std.fmt.parseFloat(f32, sn);
    std.debug.print("|{d}|\n", .{n});    
}

test "test contains" {
    const str = "TriangleList";
    if (contains(str, "TriangleList"))
    {
        std.debug.print("contains is fine.\n", .{});
    }
    else
    {
        std.debug.print("contains failed, len: {d}\n", .{str.len});
    }
}


test "test String.concat" {
    const str0 = "some line with l0\n";
    const str1 = "some line with l1\n";
    const str2 = "some line with l2\n";
    const str3 = "some line with l3\n";
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const str = concat(allocator, &[_][]const u8{str0, str1, str2, str3});

    print("{s}\n", .{str});

    allocator.free(str);
}

test "test String.contains and String.endsWith and String.StartsWith" {
    const a = "some bigger string";

    assert (contains(a, "igg"));
    assert (endsWith(a, "ing"));
    assert (startsWith(a, "som"));
}

test "test String.equals and String.isEmpty" {
    const s = Empty;
    const b = "";

    assert (equals(s,b));
    assert (isEmpty(s));
    assert (isEmpty(b));
}

test "test String.indexOf and String.lastIndexOf" {
    const s = "0abcdefghig";
    const h = 8;
    assert (indexOf(s,'h') == h);
    assert (lastIndexOf(s, 'g') == s.len - 1);
}



test "test String.join" {
    const s0 = "s0";
    const s1 = "s1";
    const s2 = "s2";
    const s3 = "s3";
    const s4 = "s3";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const str = join(allocator, "+", &.{s0, s1, s2, s3, s4});
    defer allocator.free(str);
    print ("{s}\n", .{str});
}

test "String.padLeft and String.padRight" {
    const str = "some line string";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const str_l = padLeft(allocator, str, 5, '-');
    const str_r = padRight(allocator, str, 5, '-');

    print("pad left: {s}\n", .{str_l});
    print("pad right: {s}\n", .{str_r});

    allocator.free(str_l);
    allocator.free(str_r);
}

test "test String.split" {
    const str =
        \\ some line with l0
        \\ some line with l1
        \\ some line with l2    
        \\ some line with l2
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const lines = split(allocator, str, &[_]u8{'\n','l'}); 
    // defer for (lines) |line| allocator.free(line);   
    
    for (lines) |line|
    {
        print("{s}\n", .{line});
    }
}

test "test String.toLower and String.toUpper" {
    const s = "sOme String with Uppercast and Letters";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const s_upper = toUpper(allocator, s);
    const s_lower = toLower(allocator, s);

    print("{s}\n", .{s_upper});
    print("{s}\n", .{s_lower});

    allocator.free(s_upper);
    allocator.free(s_lower);
}

test "test String.trim" {
    const s = "---some string with -- charts---";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const s_lhs = trimStart(allocator, s, '-');
    const s_rhs = trimEnd(allocator, s, '-');
    const s_cen = trim(allocator, s, '-');

    print("{s}\n", .{s_lhs});
    print("{s}\n", .{s_rhs});
    print("{s}\n", .{s_cen});

    allocator.free(s_lhs);
    allocator.free(s_rhs);
    allocator.free(s_cen);
}
