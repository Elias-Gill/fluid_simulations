const std = @import("std");

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

// Struct that represents the fluid.
pub const Fluid = struct {
    // x-coordinates where the grid starts and ends in the screen
    start_x: i32,
    end_x: i32,
    // y-coordinates where the grid starts and ends in the screen
    start_y: i32,
    end_y: i32,

    // the grid that represents the content of the fluid
    densities: Grid,
    densities_x0: Grid,

    // Physics constants
    c_diff: u16 = 2, // diffusion coeficient
    dt: u16 = 24, // delta-time

    pub fn deinit(self: Fluid) void {
        self.densities.deinit();
    }

    pub fn init(h: i32, w: i32, cell_size: i32) Fluid {
        // Grid initialization.
        // Calculate some padding to not "overflow" the UI when drawing.
        var x_padding: i32 = @mod(w, cell_size);
        var y_padding: i32 = @mod(h, cell_size);

        // Calculate the actual amount of rows and columns for the grid, using the padding
        // and dividing by the size of a single particle.
        const rows: i32 = @divFloor(h - y_padding, cell_size);
        const columns: i32 = @divFloor(w - x_padding, cell_size);

        // Apply the padding and change the position of the drawing limits.
        var grid_start_x: i32 = 0;
        var grid_end_x: i32 = rows;

        if (@mod(x_padding, 2) == 0) {
            grid_start_x += @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        } else { // uneven padding
            x_padding -= 1;
            grid_start_x += 1 + @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        }

        var grid_start_y: i32 = 0;
        var grid_end_y: i32 = columns;

        if (@mod(y_padding, 2) == 0) {
            grid_start_y += @divFloor(y_padding, 2);
            grid_end_y -= @divFloor(y_padding, 2);
        } else {
            y_padding -= 1;
            grid_start_y += 1 + @divFloor(y_padding, 2);
            grid_end_y -= @divFloor(y_padding, 2);
        }

        return Fluid{
            .start_x = grid_start_x,
            .end_x = grid_end_x,
            .start_y = grid_start_y,
            .end_y = grid_end_y,
            .densities = Grid.init(rows, columns),
            .densities_x0 = Grid.init(rows, columns),
        };
    }

    pub fn diffuse(self: Fluid) void {
        const f_diff: f64 = @floatFromInt(self.dt * self.c_diff * self.densities.rows *
            self.densities.columns);

        var iterations: i32 = 0;
        while (iterations < 20) : (iterations += 1) {
            var i: i32 = 0;
            while (i < self.densities.rows) : (i += 1) {
                var k: i32 = 0;
                while (k < self.densities.columns) : (k += 1) {
                    const neighbors = self.densities.get(i, k + 1) + self.densities.get(i, k - 1) +
                        self.densities.get(i + 1, k) + self.densities.get(i - 1, k);

                    const dividend: f64 = self.densities.get(i, k) + (f_diff * neighbors);
                    const divisor: f64 = 1 + 4 * f_diff;
                    const value: f64 = dividend / divisor;

                    self.densities.set(i, k, value);
                }
            }
        }
    }

    pub fn print(self: Fluid) void {
        var row: i32 = 0;
        while (row < self.densities.rows) : (row += 1) {
            std.debug.print(" | ", .{});

            var column: i32 = 0;
            while (column < self.densities.columns) : (column += 1) {
                std.debug.print("{} | ", .{self.densities.get(row, column)});
            }

            std.debug.print("\n", .{});
        }
    }
};
