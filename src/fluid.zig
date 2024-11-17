const std = @import("std");
const Grid = @import("lib.zig").Grid;

// Struct that represents the fluid.
pub const Fluid = struct {
    // the grid that represents the content of the fluid
    densities: Grid,
    densities_x0: Grid,

    // Physics constants
    c_diff: f16 = 0.02, // diffusion coeficient
    dt: f16 = 10, // delta-time
    added_density: f64 = 12, // the dentity that is added when the mouse is pressed

    pub fn init(rows: i32, columns: i32) Fluid {
        return Fluid{
            .densities = Grid.init(rows, columns),
            .densities_x0 = Grid.init(rows, columns),
        };
    }

    pub fn deinit(self: Fluid) void {
        self.densities.deinit();
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

    pub fn add_density(self: Fluid, row: i32, column: i32) void {
        const new_value: f64 = self.densities.get(row, column) + self.added_density;
        self.densities.set(row, column, new_value);
    }
};
