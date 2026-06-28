const std = @import("std");

pub fn main() !void
{
    std.debug.print("hello");
}

// Segment example begin
pub fn test_func() i32
{
    var a: i32 = 5;
    a += 7;
    return a;
}
// Segment example end

pub fn autogobble_demo() i32
{
    // Segment autogobble_example begin
        const base: i32 = 40;
        const increment: i32 = 2;
        return base + increment;
    // Segment autogobble_example end
}
