const std = @import("std");
const String = @import("String.zig");
const StringBuilder = @import("StringBuilder.zig");
const print = std.debug.print;
const assert = std.debug.assert;

    
test "test String.concat" {
    const str0 = "some line with l0\n";
    const str1 = "some line with l1\n";
    const str2 = "some line with l2\n";
    const str3 = "some line with l3\n";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const str = String.concat(allocator, &[_][]const u8{str0, str1, str2, str3});
    print("{s}\n", .{str});
}

test "test String.contains and String.endsWith" {
    const a = "some bigger string";
    const b = "igg";
    const c = "string";

    assert (String.contains(a, b));
    assert (String.endsWith(a, c));
}

test "test String.equals and String.isEmpty" {
    const s = String.Empty;
    const b = "";

    assert (String.equals(s,b));
    assert (String.isEmpty(s));
    assert (String.isEmpty(b));
}

test "test String.indexOf" {
    const s = "0abcdefghig";
    const h = 8;
    assert (String.indexOf(s,'h') == h);
}

test "test String.split" {
    const str =
        \\ some line with l0
        \\ some line with l1
        \\ some line with l2    
        \\ some line with l2
    ;


    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    for (String.split(allocator, str, &[_]u8{'\n','l'})) |line|
    {
        print("{s}\n", .{line});
    }
}


test "test StringBuilder" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var sb = StringBuilder.init(gpa.allocator(), 1024);
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

    const str = sb.toString(gpa.allocator());
    defer gpa.allocator().free(str);
    print("{s}\n", .{str});
}
