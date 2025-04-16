const std = @import("std");
const testing = std.testing;

const Grid = @import("lib.zig").Grid;
const Fluid = @import("fluid.zig").Fluid;

test "Test Grid initialization" {
    var grid = try Grid(f64).init(100, 50);
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
    for (0..100 * 50) |index| {
        const value = grid.grid[index];
        testing.expectEqual(value, 0) catch |err| {
            std.debug.print("Test failed at index {}: Expected value to be 0, but got {}\n", .{ index, value });
            return err;
        };
    }
}

test "Test Grid access" {
    var grid = try Grid(f64).init(10, 20);
    defer grid.deinit();

    grid.set(1, 1, 42);
    const retrieved_value = grid.get(1, 1);

    testing.expectEqual(retrieved_value, 42) catch |err| {
        std.debug.print("Test failed: Expected grid.get(1, 1) to be 42, but got {}\n", .{retrieved_value});
        return err;
    };
}

test "Test Grid bounds checking" {
    var grid = try Grid(f64).init(10, 20);
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

test "Test Fluid initialization and destruction" {
    // Initialize fluid grid with reasonable size
    const rows = 64;
    const columns = 64;
    var fluid = try Fluid.init(rows, columns);

    defer fluid.deinit();

    // Test basic properties
    const size: usize = rows * columns;
    const resolution: f32 = 1/4096;

    try std.testing.expectEqual(size, fluid.cells_number);
    try std.testing.expectEqual(resolution, fluid.resolution);

    // Test all grids were properly initialized
    try testGridIsZeroInitialized(&fluid.density, rows, columns);
    try testGridIsZeroInitialized(&fluid.density_prev, rows, columns);
    try testGridIsZeroInitialized(&fluid.pressure, rows, columns);
    try testGridIsZeroInitialized(&fluid.divergence, rows, columns);
    try testGridIsZeroInitialized(&fluid.velocity_x, rows, columns);
    try testGridIsZeroInitialized(&fluid.velocity_y, rows, columns);
    try testGridIsZeroInitialized(&fluid.velocity_x_prev, rows, columns);
    try testGridIsZeroInitialized(&fluid.velocity_y_prev, rows, columns);
}

fn testGridIsZeroInitialized(grid: *Grid(f32), rows: i32, columns: i32) !void {
    for (0..@intCast(rows)) |i| {
        for (0..@intCast(columns)) |j| {
            const value = grid.get(@intCast(i), @intCast(j));
            try std.testing.expectEqual(@as(f32, 0.0), value);
        }
    }
}
