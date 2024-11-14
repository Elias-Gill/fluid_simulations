const std = @import("std");
const Color = @import("raylib").Color;

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

// Struct that represents a matrix using vectors. It offers some useful operations
// to simplify data manipulation.
pub const Grid = struct {
    // the actual array of points that composes the grid.
    columns: i32,
    rows: i32,
    grid: []f64, // single array of bools to be more "performant" (actually just for fun).

    pub fn init(rows: i32, columns: i32) Grid {
        // initialize the array with all cells with default value as "0"
        const size: usize = @intCast(rows * columns);
        const array = allocator.alloc(f64, size) catch {
            std.debug.panic("Failed to allocate memory", .{});
        };
        @memset(array, 0);

        return Grid{
            .rows = rows,
            .columns = columns,
            .grid = array,
        };
    }

    pub fn deinit(self: Grid) void {
        allocator.free(self.grid);
    }

    fn calculate_position(self: Grid, row: i32, column: i32) i32 {
        var position = @mod(row * self.columns + column, self.rows * self.columns);
        if (position < 0) {
            position = position + (self.rows * self.columns);
        }
        return position;
    }

    pub fn get(self: Grid, row: i32, column: i32) f64 {
        const position: usize = @intCast(self.calculate_position(row, column));
        return self.grid[position];
    }

    pub fn set(self: Grid, row: i32, column: i32, value: f64) void {
        const position: usize = @intCast(self.calculate_position(row, column));
        self.grid[position] = value;
    }
};
