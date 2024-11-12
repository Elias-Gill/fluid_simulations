const std = @import("std");

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

// Struct that represents a matrix using vectors. It offers some useful operations
// to simplify data manipulation.
pub const Grid = struct {
    // x-coordinates where the grid starts and ends in the screen
    start_x: u32,
    end_x: u32,
    // y-coordinates where the grid starts and ends in the screen
    start_y: u32,
    end_y: u32,

    // the actual array of points that composes the grid.
    columns: u32,
    rows: u32,
    grid: []u32, // single array of bools to be more "performant" (actually just for fun).

    pub fn init(screenWidth: u32, screenHeight: u32, cell_size: u32) Grid {
        // Grid initialization.
        // Calculate some padding to not "overflow" the UI when drawing.
        var x_padding: u32 = @mod(screenWidth, cell_size);
        var y_padding: u32 = @mod(screenHeight, cell_size);

        // Calculate the actual amount of rows and columns for the grid, using the actual padding
        // and dividing by the size of a single particle.
        const rows: u32 = @divFloor(screenHeight - y_padding, cell_size);
        const columns: u32 = @divFloor(screenWidth - x_padding, cell_size);

        // apply the padding and change the position of the grid drawing limits.
        var grid_start_x: u32 = 0;
        var grid_end_x: u32 = screenWidth;

        if (@mod(x_padding, 2) == 0) {
            grid_start_x += @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        } else { // uneven padding
            x_padding -= 1;
            grid_start_x += 1 + @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        }

        var grid_start_y: u32 = 0;
        var grid_end_y: u32 = screenHeight;

        if (@mod(y_padding, 2) == 0) {
            grid_start_y += @divFloor(y_padding, 2);
            grid_end_y -= @divFloor(y_padding, 2);
        } else {
            y_padding -= 1;
            grid_start_y += 1 + @divFloor(y_padding, 2);
            grid_end_y -= @divFloor(y_padding, 2);
        }

        // initialize the array with all cells with default value as "0"
        const array = allocator.alloc(u32, rows * columns) catch {
            std.debug.panic("Failed to allocate memory", .{});
        };
        @memset(array, 0);

        return Grid{
            .start_x = grid_start_x,
            .end_x = grid_end_x,
            .start_y = grid_start_y,
            .end_y = grid_end_y,
            .rows = rows,
            .columns = columns,
            .grid = array,
        };
    }

    pub fn deinit(self: Grid) void {
        allocator.free(self.grid);
    }

    pub fn get(self: Grid, row: u32, column: u32) u32 {
        const position = @mod(row * (self.rows - 1) + column, self.rows * self.columns);
        return self.grid[position];
    }

    pub fn set(self: Grid, row: u32, column: u32, value: u32) void {
        const position = @mod(row * (self.rows - 1) + column, self.rows * self.columns);
        self.grid[position] = value;
    }
};
