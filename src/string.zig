const std = @import("std");


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


pub const String = struct {
    ptr: [*]u8,
    len: usize,
    capacity: usize,


    pub const Empty = String{
        .ptr = undefined,
        .len = 0,
        .capacity = 0,
    };
   

    /// Initializes a new instance of the String class to the Unicode characters indicated in the specified character array.
    pub fn init(chars:[]const u8) String
    {
        const buffer = fastAlloc (gpa_allocator, chars.len);
        @memcpy (buffer[0..chars.len], chars);
        total_allocation += chars.len;

        return String{
            .ptr = buffer.ptr,
            .len = chars.len,
            .capacity = buffer.len,
        };
    }

    pub fn deinit(s:String) void
    {
        buffer_stack.append(s.ptr[0..s.buffer_len]) catch @panic ("String.deinit() failed");

        total_allocation -= s.length();
        stack_allocation += s.length();
        string_allocated -= 1;
    }
    

    pub fn toCharsArray (s:String) []const u8
    {
        return s.ptr[0..s.len];
    }

    pub fn length (s:String) usize
    {
        return s.len;
    }

    /// Compares substrings of two specified String objects using the specified rules, 
    /// and returns an integer that indicates their relative position in the sort order.
    pub fn compare (a:String, b:String) i32
    {
        const a_chars = a.toCharsArray();
        const b_chars = b.toCharsArray();
        const len = @min (a.len, b.len);
        
        var i: usize = 0;
        var r: i32 = 0;
        while (i < len and a_chars[i] == b_chars[i]) : (i += 1)
        {
            r = @as(i32, @intCast(a_chars[i])) - @as(i32, @intCast(b_chars[i]));
        }

        return r;
    }

    /// Concatenates the elements of a specified String array.
    pub fn concat (values:[]String) String
    {
        var total_len: usize = 0;
        for (values) |s| total_len += s.length();

        var buffer = fastAlloc (gpa_allocator, total_len);
        var index  = @as(usize, 0);
        for (values) |s| 
        {
            @memcpy(buffer[index..index + s.len], s);    
            index += s.len;
        }

        return String{
            .ptr = buffer.ptr,
            .len = total_len,
            .capacity = buffer.len,
        };      
    }

    /// Returns a value indicating whether a specified string occurs within this string.
    pub fn contains (s:String, a:String) bool
    {
        if (a.len > s.len) return false;

        var n: usize = 0;
        while (n < s.len - n) : (n += 1) 
        {
            if (std.mem.eql(u8, s.ptr[n..a.len], a)) return true;
        }

        return false;
    }

    /// Copies the contents of this string into the destination span.
    pub fn copyTo (s:String, buffer:[]u8) void
    {
        if (buffer.len < s.len) @panic ("buffer is smaller than string.length()");

        @memcpy(buffer, s.ptr[0..s.len]);
    }

    /// Determines whether the end of this string instance matches the specified string.
    pub fn endsWith (s:String, value:[]const u8) bool
    {      
        return if (value.len > s.len) false else std.mem.eql(u8, s.ptr[s.len - value.len..value.len], value.ptr[0..value.len]);
    }

    /// Determines whether two specified String objects have the same value.
    pub fn equals (s:String, value:String) bool
    {
        if (s.len != value.len) 
        {
            return false;
        }
        else if (s.len == value.len and s.ptr[0] == value.ptr[0])
        {
            return std.mem.eql(u8, s.ptr[0..s.len], value.ptr[0..value.len]);    
        }
        else return false;
    }

    /// Replaces one or more format items in a string with the string representation of a specified object.
    pub fn format (s:String, fmt:[]const u8, args:anytype) String
    {
        const size = s.len + 300;                     // ??
        const buffer = fastAlloc (gpa_allocator, size); 

        _ = std.fmt.bufPrintZ(buffer[0..s.len + 300], fmt, args) catch @panic ("format failed");

        return String{
            .ptr = buffer,
            .len = size,
            .capacity = buffer.len,
        };
    }

    /// Reports the zero-based index of the first occurrence of the specified Unicode character in this string.
    pub fn indexOf (s:String, char:u8) isize
    {
        var n: usize = 0;
        while (char != s.ptr[n] and n < s.len) n += 1;
        
        return n;
    }

    /// Returns a new string in which a specified string is inserted at a specified index position in this instance.
    pub fn insert (s:String, position:usize, value:String) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len + value.len);

        const slice0 = buffer[0..position];
        const slice1 = buffer[position..value.len];
        const slice2 = buffer[position + value.len..s.len + value.len];

        @memcpy (slice0, s.ptr[0..position]);
        @memcpy (slice1, value.ptr[0..value.len]);
        @memcpy (slice2, s.ptr[position..s.len]);

        return String{
            .ptr = buffer.ptr,
            .len = s.len + value.len,
            .capacity = buffer.len,
        };
    }
    
    /// Returns a new string in which a specified string is inserted at a specified index position in this instance.
 	pub fn intern (s:String) String
 	{
 	    _ = s; // autofix
 	
 	    noreturn;
 	}

    /// Retrieves a reference to a specified String.
    pub fn isInterned (s:String) bool
    {
        _ = s; // autofix
    
        return false;
    }

    /// Indicates whether the specified string is null or an empty string 
    pub fn isEmpty (s:String) bool
    {
        return s.len == 0;
    }

    /// Concatenates the members of a collection, using the specified separator between each member.
    pub fn join (separator:String, values: []String) String
    {
        var total_len: usize = 0;
        for (values) |s| total_len += s.len + separator.len;

        const buffer = fastAlloc (gpa_allocator, total_len);
        var idx: usize = 0;

        for (values) |s| 
        {
            @memcpy(buffer[idx..s.len], s);    
            @memcpy(buffer[idx + s.len..separator.len], separator);
            idx += s.len + separator.len;
        }

        return String{
            .ptr = buffer.ptr,
            .len = total_len,
            .capacity = buffer.len,
        };
    }   
    
    /// Reports the zero-based index position of the last occurrence of a specified Unicode character within this instance.
    pub fn lastIndexOf (s:String, char:u8) usize 
    {
        var n: usize = s.len;
        while (n > 0 and s.ptr[n] != char) n -= 1;

        return n;     
    }

    /// Returns a new string that right-aligns the characters in this instance by padding them 
    /// on the left with a specified Unicode character, for a specified total length.
    pub fn padLeft (s:String, n:usize, pad:u8) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len + n);

        for (0..n) |i| buffer[i] = pad;
        @memcpy (buffer[n..s.len], s.ptr[0..s.len]);

        return String{
            .ptr = buffer,
            .len = s.len + n,
            .capacity = buffer.len,
        };
    }

    /// Returns a new string that right-aligns the characters in this instance by padding them 
    /// on the right with a specified Unicode character, for a specified total length.
    pub fn padRight (s:String, n:usize, pad:u8) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len + n);

        @memcpy (buffer[0..s.len], s.toCharsArray());
        for (n..s.len + n) |i| buffer[i] = pad;

        return String{
            .ptr = buffer,
            .len = s.len + n,
            .capacity = buffer.len,
        };
    }


    /// Returns a new string in which a specified number of characters in the current instance beginning at a specified position have been deleted.
    pub fn remove (s:String, start:usize, end:usize) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len - (end - start));

        @memcpy (buffer[0..start], s.ptr[0..start]);
        @memcpy (buffer[start..s.len - end], s.ptr[end..s.len]);

        return String{
            .ptr = buffer.ptr,
            .len = s.len - (end - start),
            .capacity = buffer.len,
        };
    }

    /// Returns a new string in which all occurrences of a specified string in the current instance are replaced with another specified string.
    pub fn replace (s:String, old_value:String, new_value:String) String
    {
        var n: usize = 0;
        var i: usize = 0;
        while (i < s.len - old_value.len) : (i += 1)
        {
            if (std.mem.eql(s.ptr[i..old_value.len], old_value.toCharsArray()))
            {
                n += 1;
                i += old_value.len;
            }
        }

        const size = if (old_value.len > new_value.len) s.len - n * (old_value.len - new_value.len) else s.len + n * (new_value.len - old_value);
        const buffer = fastAlloc (gpa_allocator, size);

        i = 0;
        n = 0;
        while (i < s.len - old_value.len) : (i += 1)
        {
            if (std.mem.eql(s.ptr[i..old_value.len], old_value.toCharsArray()))
            {
                @memcpy (buffer[i..new_value.len], new_value.toCharsArray());
                i += old_value.len;
            }
        }

        return String{
            .ptr = buffer.ptr,
            .len = size,
            .capacity = buffer.len,
        };
    }

    /// Splits a string into substrings based on a specified delimiting string and, optionally, options.
    pub fn split (s:String, options:[]const[]const u8) []String
    {
        var n: usize = 0;
        var i: usize = 0;
        while (i < s.len) : (i += 1)
        {
            for (options) |option|
            {
                if (std.mem.eql(s.ptr[i..option.len], option))
                {
                    n += 1;
                    i += option.len;
                }
                
            }
        }
                
        n = 0;
        i = 0;
        var j: usize = 0;
        const array = gpa_allocator.alloc(String, n) catch @panic ("allocator failed in String.split()");
        while (i < s.len) : (i += 1)
        {
            for (options) |option|
            {
                if (std.mem.eql(s.ptr[i..option.len], option))
                {
                    array[n] = String.init(s.ptr[j..i]);
                    n += 1;
                    i += option.len;
                    j = i; 
                }
                
            }
        }

        return array;
    }

    /// Determines whether the beginning of this string instance matches the specified string.
    pub fn startsWith (s:String, value:[]const u8) bool 
    {
        return if (value.len > s.len) false else std.mem.eql(s.ptr[0..value.len], value);
    }
    
    /// Returns a copy of this string converted to lowercase.
    pub fn toLower (s:String) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len);
        _ = std.ascii.lowerString(buffer, s.toCharsArray());

        return String{
            .ptr = buffer.ptr,
            .len = s.len,
            .capacity = buffer.len,
        };
    }
    
    /// Returns a copy of this string converted to uppercase.
    pub fn toUpper (s:String) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len);
        _ = std.ascii.upperString(buffer, s.toCharsArray());

        return String{
            .ptr = buffer.ptr,
            .len = s.len,
            .capacity = buffer.len,
        };
    }

    /// Removes all leading and trailing instances of a character from the current string.
    pub fn trim (s:String, char:u8) String
    {
        var l: usize = 0;
        var r: usize = s.len;

        while (l < s.len and s.ptr[l] == char) l += 1;
        while (r > 0 and s.ptr[r] == char) r -= 1;
        

        const len = s.len - (l + r);
        const buffer = fastAlloc (gpa_allocator, len);
        @memcpy (buffer[0..len], s.ptr[l..s.len - r]);

        return String{
            .ptr = buffer.ptr,
            .len = len,
            .capacity = buffer.len,
        };
    }

    /// Removes all the trailing occurrences of a set of characters specified in an array from the current string.
    pub fn trimEnd (s:String, char:u8) String 
    {
        var r: usize = s.len;

        while (r > 0 and s.ptr[r] == char) r -= 1;
        
        const len = s.len - (r);
        const buffer = fastAlloc (gpa_allocator, len);
        @memcpy (buffer[0..len], s.ptr[0..s.len - r]);

        return String{
            .ptr = buffer.ptr,
            .len = len,
            .capacity = buffer.len,
        };
        
    }

    /// Removes all the leading occurrences of a specified character from the current string.
    pub fn trimStart (s:String, char:u8) String
    {
        var l: usize = 0;

        while (l < s.len and s.ptr[l] == char) l += 1;

        const len = s.len - (l);
        const buffer = fastAlloc (gpa_allocator, len);
        @memcpy (buffer[0..len], s.ptr[l..s.len]);

        return String{
            .ptr = buffer.ptr,
            .len = len,
            .capacity = buffer.len,
        };        
    }
    
    pub fn asSpan (s:String, start:usize, _length:usize) []const u8
    {
        return s.ptr[start.._length];
    }

    pub fn add (s:String, value:String) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len + value.len);

        @memcpy (buffer[0..s.len], s.toCharsArray());
        @memcpy (buffer[s.len..s.len + value.len], value.toCharsArray());

        return String{
            .ptr = buffer.ptr,
            .len = s.len + value.len,
            .capacity = buffer.len,
        };
    }
    
    pub fn append (s:String, value:[]const u8) String
    {
        const buffer = fastAlloc (gpa_allocator, s.len + value.len);

        @memcpy (buffer[0..s.len], s.toCharsArray());
        @memcpy (buffer[s.len..s.len + value.len], value.toCharsArray());

        return String{
            .ptr = buffer.ptr,
            .len = s.len + value.len,
            .capacity = buffer.len,
        };
    }
};



pub const StringBuilder = struct
{
    ptr: [*]u8,
    len: usize,
    capacity: usize,

    /// Initializes a new instance of the StringBuilder class using the specified capacity.
    pub fn init (capacity:usize) StringBuilder
    {
        const buffer = gpa_allocator.alloc(u8, capacity) catch @panic ("StringBuilder.init() failed");
        
        return StringBuilder{
            .ptr = buffer.ptr,
            .len = 0,
            .capacity = capacity,
        };      
    }    

    pub fn deinit (sb:StringBuilder) void
    {
        gpa_allocator.free(sb.ptr[0..sb.capacity]);
    }

    fn resize (sb:*StringBuilder, new_capacity:usize) void
    {
        const buffer = gpa_allocator.alloc(u8, new_capacity) catch @panic ("StringBuilder.append() failed");
        
        @memcpy (buffer[0..sb.len], sb.ptr[0..sb.len]);
        gpa_allocator.free(sb.ptr[0..sb.capacity]);

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
    pub fn appendFormat (sb:*StringBuilder, fmt:[]const u8, args:anytype) void 
    {
        const buffer = fastAlloc (gpa_allocator, 1024);
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
        if (sb.capacity < sb.len + chars.len) sb.resize(sb.capacity + chars.len * 2);

        const temp = fastAlloc (gpa_allocator, sb.len - position);
        defer fastFree (temp);

        @memcpy (temp, sb.ptr[position..sb.len - position]);
        @memcpy (sb.ptr[position..sb.len + chars.len], chars);
        @memcpy (sb.ptr[position + chars.len..temp.len], temp);
    }

    /// Removes the specified range of characters from this instance.
    pub fn remove (sb:*StringBuilder, start:usize, end:usize) void
    {
        const temp = fastAlloc (gpa_allocator, end - start);
        defer fastFree (temp);

        @memcpy (temp, sb.ptr[end..sb.len - end]);
        @memcpy (sb.ptr[start..end], temp);
    }

    /// Replaces all occurrences of a specified string in this instance with another specified string.
    pub fn replace (sb:*StringBuilder, old_value:[]const u8, new_value:[]const u8) void
    {
        const temp0 = fastAlloc (gpa_allocator, old_value.len + new_value.len);
        const temp1 = fastAlloc (gpa_allocator, new_value.len + old_value.len);
        defer fastFree (temp0);
        defer fastFree (temp1);
        
        var i: usize = 0;
        while (i < sb.len - old_value.len) : (i += 1)
        {
            if (std.mem.eql(u8, sb.ptr[i..old_value.len], old_value))
            {
                @memcpy (temp0, sb.ptr[i..new_value.len]);
                @memcpy (sb.ptr[i..sb.capacity - i], new_value);
                i += new_value.len;
            }
        }
    }
    
    pub fn toString (sb:StringBuilder) String
    {
        return String.init(sb.ptr[0..sb.len]);
    }

    pub fn toCharsArray (sb:StringBuilder) []const u8
    {
        return sb.ptr[0..sb.len];
    }
};

