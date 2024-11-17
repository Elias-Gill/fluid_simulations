const rl = @import("raylib");
const std = @import("std");

const Color = rl.Color;
const Grid = @import("lib.zig").Grid;

pub const MouseToGridError = error{InvalidPosition};

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
    c_diff: f16 = 0.02, // diffusion coeficient
    dt: f16 = 10, // delta-time
    added_density: f64 = 12, // the dentity that is added when the mouse is pressed

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
        var grid_end_x: i32 = w;

        if (@mod(x_padding, 2) == 0) {
            grid_start_x += @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        } else { // uneven padding
            x_padding -= 1;
            grid_start_x += 1 + @divFloor(x_padding, 2);
            grid_end_x -= @divFloor(x_padding, 2);
        }

        var grid_start_y: i32 = 0;
        var grid_end_y: i32 = h;

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
        const dim: f64 = @floatFromInt(self.densities.rows * self.densities.columns);
        const f_diff: f64 = self.dt * self.c_diff * dim;

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

    const colors: [29]rl.Color = .{
        Color.init(14, 14, 34, 120), // Dark blue
        Color.init(14, 14, 38, 120), // Slightly lighter dark blue
        Color.init(14, 14, 42, 120), // Lighter dark blue
        Color.init(14, 14, 46, 120), // Slightly lighter blue
        Color.init(14, 14, 50, 120), // Light dark blue
        Color.init(14, 14, 54, 120), // Light blue (a bit brighter)
        Color.init(14, 14, 58, 120), // Slightly lighter blue
        Color.init(14, 14, 62, 120), // Brighter blue
        Color.init(14, 14, 66, 120), // Lighter blue
        Color.init(14, 14, 70, 120), // Lighter blue
        Color.init(14, 14, 80, 120), // Mid-range blue
        Color.init(14, 14, 90, 120), // Mid-range blue
        Color.init(14, 14, 100, 120), // Bright blue
        Color.init(14, 14, 110, 120), // Lighter blue
        Color.init(14, 14, 120, 120), // Even brighter blue
        Color.init(14, 14, 130, 120), // Bright blue
        Color.init(14, 14, 140, 120), // Lighter bright blue
        Color.init(14, 14, 150, 120), // Brighter blue
        Color.init(14, 14, 160, 120), // Bright blue
        Color.init(14, 14, 170, 120), // Lighter bright blue
        Color.init(14, 14, 180, 120), // Even lighter blue
        Color.init(14, 14, 190, 120), // Very bright blue
        Color.init(14, 14, 200, 120), // Almost white blue
        Color.init(14, 14, 210, 120), // Almost white-blue
        Color.init(14, 14, 220, 120), // Almost white-blue
        Color.init(14, 14, 230, 120), // Very light blue
        Color.init(14, 14, 240, 120), // Very light blue
        Color.init(14, 14, 250, 120), // Near full intensity blue
        Color.init(14, 14, 255, 120), // Full intensity blue (brightest)
    };

    // Transpolates the mouse position to a cell of the fluid
    fn find_cell(self: Fluid) ![2]i32 {
        const mouse_x: i32 = rl.getMouseX();
        const mouse_y: i32 = rl.getMouseY();

        // check out of bounds position
        if (mouse_x < self.start_x or mouse_y < self.start_y) {
            return MouseToGridError.InvalidPosition;
        }

        if (mouse_x > self.end_x or mouse_y > self.end_y) {
            return MouseToGridError.InvalidPosition;
        }

        const row: i32 = @divFloor(mouse_y - self.start_y, self.cell_size);
        const column: i32 = @divFloor(mouse_x - self.start_x, self.cell_size);

        return .{ row, column };
    }

    pub fn add_forces(self: Fluid) void {
        if (!rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
            return;
        }

        const positions = self.find_cell() catch {
            std.debug.print("\nMouse out of bounds", .{});
            return;
        };

        const row = positions[0];
        const column = positions[1];
        const new_value: f64 = self.densities.get(row, column) + self.added_density;
        self.densities.set(row, column, new_value);
    }

    pub fn draw(self: Fluid) void {
        var row: i32 = 0;
        while (row < self.densities.rows) : (row += 1) {
            var column: i32 = 0;
            while (column < self.densities.columns) : (column += 1) {
                const y: i32 = @intCast(row * self.cell_size + self.start_y);
                const x: i32 = @intCast(column * self.cell_size + self.start_x);

                const pos: usize = @intFromFloat(1 * self.densities.get(row, column) * 100);
                const color = colors[pos % 29];

                rl.drawRectangle(x, y, self.cell_size, self.cell_size, color);
            }
        }
    }
};
