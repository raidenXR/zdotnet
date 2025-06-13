const std = @import("std");
const File = std.fs.File;


pub fn append (file:File, str:[]const u8) void
{
    file.writeAll(str) catch @panic ("failed to write str");
}

pub fn write (file:File, str:[]const u8) void
{
    file.writeAll(str) catch @panic ("failed to write str");
}

pub fn writeLine (file:File, str:[]const u8) void
{
    file.writeAll(str) catch @panic ("failed to write str");    
    file.writeAll("\n") catch @panic ("failed to write newline");
 }

pub fn create (filename:[]const u8) File 
{
    return std.fs.cwd().createFile(filename, .{.read = true}) catch @panic("failed to create file");
}

pub fn open (filename:[]const u8) File
{
    return std.fs.cwd().openFile(filename, .{}) catch  @panic("failed to open file");
}

pub fn readAll (filename:[]const u8, allocator:std.mem.Allocator) []u8
{
    const size = 12 * 1024 * 1024;   // 12MB
    return std.fs.cwd().readFileAlloc(allocator, filename, size) catch @panic("failed to alloc buffer, for the read bytes");
}

pub fn exists (filename:[]const u8) bool
{
    std.fs.cwd().access(filename, .{}) catch return false;

    return true;
}

pub fn delete (filename:[]const u8) void
{
    std.fs.cwd().deleteFile(filename) catch @panic ("Failed to delete file");
}

test "test File module" {
    const fs = create("some_txt.txt");
    writeLine (fs, "some line 0 ");
    writeLine (fs, "some line 1 ");
    writeLine (fs, "some line 2 ");
    writeLine (fs, "some line 3 ");
    fs.close();


    var gpa = std.heap.GeneralPurposeAllocator(.{}){};    
    const allocator = gpa.allocator();
    const rd = readAll("some_txt.txt", allocator);
    defer allocator.free(rd);

    std.debug.print("{s}\n", .{rd});

    if (exists("some_txt.txt"))
    {
        delete("some_txt.txt");
    }
}
