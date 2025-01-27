const std = @import("std");
const String = @import("String.zig");
const StringBuilder = @import("StringBuilder.zig");
const print = std.debug.print;
const assert = std.debug.assert;

    
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

test "test String.concat" {
    const str0 = "some line with l0\n";
    const str1 = "some line with l1\n";
    const str2 = "some line with l2\n";
    const str3 = "some line with l3\n";
    
    const str = String.concat(allocator, &[_][]const u8{str0, str1, str2, str3});

    print("{s}\n", .{str});

    allocator.free(str);
}

test "test String.contains and String.endsWith and String.StartsWith" {
    const a = "some bigger string";

    assert (String.contains(a, "igg"));
    assert (String.endsWith(a, "ing"));
    assert (String.startsWith(a, "som"));
}

test "test String.equals and String.isEmpty" {
    const s = String.Empty;
    const b = "";

    assert (String.equals(s,b));
    assert (String.isEmpty(s));
    assert (String.isEmpty(b));
}

test "test String.indexOf and String.lastIndexOf" {
    const s = "0abcdefghig";
    const h = 8;
    assert (String.indexOf(s,'h') == h);
    assert (String.lastIndexOf(s, 'g') == s.len - 1);
}



test "test String.join" {
    const s0 = "s0";
    const s1 = "s1";
    const s2 = "s2";
    const s3 = "s3";
    const s4 = "s3";

    const str = String.join(allocator, "+", &.{s0, s1, s2, s3, s4});
    defer allocator.free(str);
    print ("{s}\n", .{str});
}

test "String.padLeft and String.padRight" {
    const str = "some line string";
    const str_l = String.padLeft(allocator, str, 5, '-');
    const str_r = String.padRight(allocator, str, 5, '-');

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

    const lines = String.split(allocator, str, &[_]u8{'\n','l'}); 
    // defer for (lines) |line| allocator.free(line);   
    
    for (lines) |line|
    {
        print("{s}\n", .{line});
    }
}

test "test String.toLower and String.toUpper" {
    const s = "sOme String with Uppercast and Letters";
    const s_upper = String.toUpper(allocator, s);
    const s_lower = String.toLower(allocator, s);

    print("{s}\n", .{s_upper});
    print("{s}\n", .{s_lower});

    allocator.free(s_upper);
    allocator.free(s_lower);
}

test "test String.trim" {
    const s = "---some string with -- charts---";
    const s_lhs = String.trimStart(allocator, s, '-');
    const s_rhs = String.trimEnd(allocator, s, '-');
    const s_cen = String.trim(allocator, s, '-');

    print("{s}\n", .{s_lhs});
    print("{s}\n", .{s_rhs});
    print("{s}\n", .{s_cen});

    allocator.free(s_lhs);
    allocator.free(s_rhs);
    allocator.free(s_cen);
}

test "test StringBuilder" {
    var sb = StringBuilder.init(allocator, 1024);
    defer sb.deinit();

    sb.appendLine("some line 0");
    sb.appendLine("some line 1");
    sb.appendLine("some line 2");
    sb.appendLine("some line 3");
    sb.appendLine("some line 4");
    sb.appendLine("some line 5");

    sb.remove(10,14);
    sb.insert(7, "insert some substr");
    sb.replace("some", "new_some");
    sb.appendFormat("some formated str: {d:.2}, v:{s}, z{any}\n", .{45.94320, "sss", &[_]u8{1,3,1,7}});

    const str = sb.toString(allocator);
    defer allocator.free(str);
    print("{s}\n", .{str});
}
