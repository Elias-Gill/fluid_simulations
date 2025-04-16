const std = @import("std");
const testing = std.testing;

const Grid = @import("lib.zig").Grid;

test "Test Grid initialization" {
    const grid = try Grid(f64).init(100, 50);
    defer grid.deinit();

    // Check rows
    testing.expectEqual(grid.rows, 100) catch |err| {
        std.debug.print("Test failed: Expected grid.rows to be 100, but got {}\n", .{grid.rows});
        return err;
    };

    // Check columns
    testing.expectEqual(grid.columns, 50) catch |err| {
        std.debug.print("Test failed: Expected grid.columns to be 50, but got {}\n", .{grid.columns});
        return err;
    };

    // Verify zero-values initialization
    for (0..100*50) |index| {
        const value = grid.grid[index];
        testing.expectEqual(value, 0) catch |err| {
            std.debug.print("Test failed at index {}: Expected value to be 0, but got {}\n", .{ index, value });
            return err;
        };
    }
}

test "Test Grid access" {
    const grid = try Grid(f64).init(10, 20);
    defer grid.deinit();

    grid.set(1, 1, 42);
    const retrieved_value = grid.get(1, 1);

    testing.expectEqual(retrieved_value, 42) catch |err| {
        std.debug.print("Test failed: Expected grid.get(1, 1) to be 42, but got {}\n", .{retrieved_value});
        return err;
    };
}

test "Test Grid bounds checking" {
    const grid = try Grid(f64).init(10, 20);
    defer grid.deinit();
    grid.set(0, 0, 2);
    grid.set(9, 19, 3);

    // Accessing out-of-bounds indices should wrap around in a circular manner
    const result = grid.get(0, 200);
    testing.expectEqual(2, result) catch |err| {
        std.debug.print("Test failed: Expected value to be 2, but got {}\n", .{result});
        return err;
    };
}
