const std = @import("std");
const ArrayPool = @import("ArrayPool.zig");
const numerics = @import("numerics.zig");
const assert = std.debug.assert;
const print = std.debug.print;

// utilities
inline fn selectBucketIndex (bufferSize:usize) usize
{
    return std.math.log2(bufferSize - @as(usize, 1) | @as(usize, 15)) - @as(usize, 3);
}

inline fn getMaxSizeForBucket (binIndex:usize) usize
{
    const n: u6 = @intCast(binIndex);
    const max_size: usize = @as(usize, 16) << n;
    std.debug.assert(max_size >= 0);
    return max_size;
}

// fn clear (comptime T:type, array:[]T) void {
//     const ptr: [*]u8 = @ptrCast(@alignCast(array.ptr));
//     const len = array.len * @sizeOf(T);
//     @memset(ptr[0..len], 0);    
// }

inline fn id (ptr:anytype) usize
{
    const _ptr: [*]const u8 = @ptrCast(ptr);
    return @intFromPtr(_ptr);
}

pub const Error = error
{
    OutOfRange,
    BufferNotFromPool,
};


const default_max_array_length = 1024 * 1024;
const default_max_number_of_buckets = 50;


pub fn create(comptime T:type, maxArrayLenght:usize, maxArraysPerBucket:usize) type
{
    return struct
    {
        // Our bucketing algorithm has a min length of 2^4 and a max length of 2^30.
        // Constrain the actual max used to those values.
        const min_array_len = 0x10;
        const max_array_len = 0x40000000;
        const _max_array_len = std.math.clamp(maxArrayLenght, min_array_len, max_array_len);


        var gpa_allocator = std.heap.DebugAllocator(.{}){};
        const allocator = gpa_allocator.allocator();

        var is_initialized = false;
        var _buckets: []Bucket = undefined;

        /// run this function only once on initialization
        fn init() void 
        {
            // get hashcode()
            const pool_id = id(&@This());
            const max_buckets = selectBucketIndex(_max_array_len);
            const buckets = allocator.alloc(Bucket, max_buckets + 1) catch @panic("allocator failed");
            for (buckets, 0..) |*bucket, i| {
                bucket.* = Bucket.init(getMaxSizeForBucket(i), maxArraysPerBucket, pool_id);
            }
            _buckets = buckets;            
        }

        pub fn rentT (minimumLength:usize) []T
        {
            if (!is_initialized) {
                init();
                is_initialized = true;    
            }
            
            if (minimumLength == 0) {
                // No need for events with the empty array.  Our pool is effectively infinite
                // and we'll never allocate for rents and never store for returns.
                return &[0]T{};
            }

            var buffer: []T = undefined;
            
            const index = selectBucketIndex(minimumLength);
            if (index < _buckets.len) {
                // Search for an array starting at the 'index' bucket. If the bucket is empty, bump up to the
                // next higher bucket and try that one, but only try at most a few buckets.
                const max_buckets_to_try = 2;
                var i = index;

                while (i < _buckets.len and i != index + max_buckets_to_try) : (i += 1) {
                    if (_buckets[i].rentT()) |_buffer| {
                        return _buffer;
                    }
                }

                // The pool was exhausted for this buffer size.  Allocate a new buffer with a size corresponding
                // to the appropriate bucket.
                buffer = allocator.alloc(T, _buckets[index].buffer_len) catch @panic("allocator failed to alloc");
            }
            else {
                // The request was for a size too large for the pool.  Allocate an array of exactly the requested length.
                // When it's returned to the pool, we'll simply throw it away.
                buffer = allocator.alloc(T, minimumLength) catch @panic("allocator failed to alloc");
            }

            // if (log.IsEnabled) {...}

            return buffer;
        }


        pub fn returnT(array:[]T, clearArray:bool) void
        {
            if (array.len == 0) {
                // Ignore empty arrays.  When a zero-length array is rented, we return a singleton
                // rather than actually taking a buffer out of the lowest bucket.
                return;
            }
            // Determine with what bucket this array length is associated
            const bucket = selectBucketIndex(array.len);
            
            // If we can tell that the buffer was allocated, drop it. Otherwise, check if we have space in the pool
            const have_bucket = bucket < _buckets.len;
            if (have_bucket) {
                // Clear the array if the user requests
                if (clearArray) {
                    const ptr: [*]u8 = @ptrCast(@alignCast(array.ptr));
                    const len = array.len * @sizeOf(T);
                    @memset(ptr[0..len], 0);    
                }
                // Return the buffer to its bucket.  In the future, we might consider having Return return false
                // instead of dropping a bucket, in which case we could try to return to a lower-sized bucket,
                // just as how in Rent we allow renting from a higher-sized bucket.
                _buckets[bucket].returnT(array) catch @panic("returnT failed");
            }

            // log that the buffer was returned
            // const log = ...
        }

        
        const Bucket = struct 
        {
            buffer_len: usize = 128,
            buffers: []?[]T,
            pool_id: usize = 0,
            index: usize = 0,
            // spinlock: SpinLock,


            pub fn init (bufferLength:usize, numberOfBuffers:usize, poolId:usize) Bucket
            {
                const buffers = allocator.alloc(?[]T, numberOfBuffers) catch @panic("allocator failed");
                @memset(buffers, null);
                
                return Bucket{
                    .buffers = buffers,
                    .buffer_len = bufferLength,
                    .pool_id = poolId,
                    .index = 0,
                };
            }

            pub fn rentT (s:*Bucket) ?[]T 
            {
                var buffer: ?[]T = null;
                var allocate_buffer = false;

                if (s.index < s.buffers.len) {
                    buffer = s.buffers[s.index];
                    s.buffers[s.index] = null;
                    s.index += 1;
                    allocate_buffer = buffer == null;
                }
                
                // While we were holding the lock, we grabbed whatever was at the next available index, if
                // there was one.  If we tried and if we got back null, that means we hadn't yet allocated
                // for that slot, in which case we should do so now.
                if (allocate_buffer) {
                    buffer = allocator.alloc(T, s.buffer_len) catch @panic("allocator failed");

                    // if log enabled log = ....
                }

                return buffer;
            }

            /// Attempts to return the buffer to the bucket.  If successful, the buffer will be stored
            /// in the bucket and true will be returned; otherwise, the buffer won't be stored, and false
            /// will be returned.
            pub fn returnT (s:*Bucket, array:[]T) Error!void
            {
                // Check to see if the buffer is the correct size for this bucket
                if (array.len != s.buffer_len) {
                    return Error.BufferNotFromPool;
                }

                const returned = s.index != 0;
                if (returned) {
                    s.index -= 1;
                    s.buffers[s.index] = array;
                }     
                if (!returned) {
                    // if log is enabled
                }                   
            }
        };        
    };
}



test "test ArrayPool" {
    const Vec3Pool = ArrayPool.create(numerics.Vector3, 100, 10);
    const vecs = Vec3Pool.rentT(50);
    
    for (0..10) |i| vecs[i] = numerics.vec3.unitX;
    for (10..20) |i| vecs[i] = numerics.vec3.unitY;
    for (20..30) |i| vecs[i] = numerics.vec3.unitZ;
    
    defer _ = Vec3Pool.returnT(vecs, false);

    print("array len: {d}\n", .{vecs.len});   
    for (vecs[0..30]) |v| std.debug.print("vec: {any}\n", .{v}); 
}

