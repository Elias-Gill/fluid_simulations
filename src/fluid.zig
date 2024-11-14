const rl = @import("raylib");
const std = @import("std");

const Color = rl.Color;
const Grid = @import("lib.zig").Grid;

// Struct that represents the fluid.
pub const Fluid = struct {
    cell_size: i32,
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
    c_diff: u16 = 255, // diffusion coeficient
    dt: u16 = 2, // delta-time

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
            .cell_size = cell_size,
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

    const colors: [10]rl.Color = .{
        Color.init(14, 14, 34, 120), // Dark blue
        Color.init(14, 14, 50, 120), // Light dark blue
        Color.init(14, 14, 70, 120), // Lighter blue
        Color.init(14, 14, 90, 120), // Mid-range blue
        Color.init(14, 14, 110, 120), // Mid-range blue
        Color.init(14, 14, 130, 120), // Lighter blue
        Color.init(14, 14, 160, 120), // Bright blue
        Color.init(14, 14, 190, 120), // Even brighter blue
        Color.init(14, 14, 220, 120), // Almost white-blue
        Color.init(14, 14, 255, 120), // Full intensity blue (brightest)
    };

    pub fn draw(self: Fluid) void {
        var row: i32 = 0;
        while (row < self.densities.rows) : (row += 1) {
            var column: i32 = 0;
            while (column < self.densities.columns) : (column += 1) {
                const y: i32 = @intCast(row * self.cell_size + self.start_y);
                const x: i32 = @intCast(column * self.cell_size + self.start_x);

                const pos: usize = @intFromFloat(1 * self.densities.get(row, column));
                const color = colors[pos % 10];

                rl.drawRectangle(x, y, self.cell_size, self.cell_size, color);
            }
        }
    }
};
