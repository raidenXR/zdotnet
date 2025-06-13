This repository contains a collection of several classes from .NET API implemented with Zig, to make  
working with Zig less frustrating, (i.e have some familiar classes from .NET).   

- ArrayPool
- File
- Numerics
- String
- StringBuilder

the `src/dotnet.zig` is defined as a package in `build.zig` and `build.zig.zon`, so it can be   
easily imported to other zig projects.   

from terminal run `zig build test` to run tests.  

