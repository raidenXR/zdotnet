A collection of src code files for general use.   
Inside the `\dotnet` directory are some class from .NET API implemented with Zig, to make working
with Zig less frustrating, (i.e have some familiar classes from .NET).   

- String
- StringBuilder
- Numerics
- ArrayPool

the `\dotnet` directory is defined as a package in `build.zig` and `build.zig.zon`, so it can be   
easily imported to other zig projects.   