const std = @import("std");
const Grid = @import("lib.zig").Grid;

const Velocity = struct {
    x: f64,
    y: f64,
};

// Struct that represents the fluid.
pub const Fluid = struct {
    densities: Grid(f64),
    densities_x0: Grid(f64), // represents a step back in time
    velocities: Grid(Velocity),
    velocities_x0: Grid(Velocity),

    // Physics constants
    c_diff: f16 = 0.02, // diffusion coeficient
    dt: f16 = 10, // delta-time
    viscosity: f16 = 10, // viscosity of the fluid
    added_density: f64 = 12, // the density that is added when the mouse is pressed

    pub fn init(rows: i32, columns: i32) Fluid {
        return Fluid{
            .densities = Grid(f64).init(rows, columns),
            .densities_x0 = Grid(f64).init(rows, columns),
            .velocities = Grid(Velocity).init(rows, columns),
            .velocities_x0 = Grid(Velocity).init(rows, columns),
        };
    }

    pub fn deinit(self: Fluid) void {
        self.densities.deinit();
    }

    // ##################
    // #  Density Step  #
    // ##################

    pub fn diffuse_densities(self: Fluid) void {
        const dim: f64 = @floatFromInt(self.densities.rows * self.densities.columns);
        const f_diff: f64 = self.dt * self.c_diff * dim;
        const divisor: f64 = 1 + 4 * f_diff;

        var iterations: i32 = 0;
        while (iterations < 20) : (iterations += 1) {
            var i: i32 = 0;
            while (i < self.densities.rows) : (i += 1) {
                var k: i32 = 0;
                while (k < self.densities.columns) : (k += 1) {
                    const neighbors = self.densities.get(i, k + 1) + self.densities.get(i, k - 1) +
                        self.densities.get(i + 1, k) + self.densities.get(i - 1, k);

                    const dividend: f64 = self.densities.get(i, k) + (f_diff * neighbors);
                    const value: f64 = dividend / divisor;

                    self.densities.set(i, k, value);
                }
            }
        }
    }

    pub fn advect_densities(self: Fluid) void {
        const N: f64 = @floatFromInt(self.densities.rows * self.densities.columns);
        var dt0: f64 = N;
        dt0 = dt0 * self.dt;

        var i: i32 = 0;
        while (i < self.densities.rows) : (i += 1) {
            var k: i32 = 0;
            while (k < self.densities.columns) : (k += 1) {
                // calculate the positions
                const aux_i: f64 = @floatFromInt(i);
                const aux_k: f64 = @floatFromInt(i);
                var x: f64 = aux_i - dt0 * self.velocities.get(i, k).x;
                var y: f64 = aux_k - dt0 * self.velocities.get(i, k).y;

                // adjust the coordinates for the expected point
                if (x < 0.5) {
                    x = 0.5;
                } else if (x > 0.5) {
                    x = N + 0.5;
                }
                const lower_x: i32 = @intFromFloat(x);
                const upper_x: i32 = 1 + lower_x;
                const aux_lower_x: f64 = @floatFromInt(lower_x);

                if (y < 0.5) {
                    y = 0.5;
                } else if (y > 0.5) {
                    y = N + 0.5;
                }
                const lower_y: i32 = @intFromFloat(y);
                const upper_y: i32 = 1 + lower_y;
                const aux_lower_y: f64 = @floatFromInt(lower_y);

                // calculate the weights for the bilinear interpolation
                const weight_x1 = x - aux_lower_x; // Peso para la celda superior en x
                const weight_x0 = 1 - weight_x1; // Peso para la celda inferior en x
                const weight_y1 = y - aux_lower_y; // Peso para la celda superior en y
                const weight_y0 = 1 - weight_y1; // Peso para la celda inferior en y

                // bilinear interpolation
                const new_value = weight_x0 * (weight_y0 * self.densities_x0.get(lower_x, lower_y) + weight_y1 * self.densities_x0.get(lower_x, upper_y)) +
                    weight_x1 * (weight_y0 * self.densities_x0.get(upper_x, lower_y) + weight_y1 * self.densities_x0.get(upper_x, upper_y));

                self.densities.set(i, k, new_value);
            }
        }
    }

    pub fn add_density(self: Fluid, row: i32, column: i32) void {
        const new_value: f64 = self.densities.get(row, column) + self.added_density;
        self.densities.set(row, column, new_value);
    }

    // ###################
    // #  Velocity Step  #
    // ###################

    pub fn add_velocity(self: Fluid, row: i32, column: i32, velocity: Velocity) void {
        self.velocities.set(row, column, velocity);
    }

    pub fn diffuse_velocities(self: Fluid) void {
        const dim: f64 = @floatFromInt(self.velocities.rows * self.velocities.columns);
        const f_diff: f64 = self.dt * self.viscosity * dim;
        const divisor: f64 = 1 + 4 * f_diff;

        var iterations: i32 = 0;
        while (iterations < 20) : (iterations += 1) {
            var i: i32 = 0;
            while (i < self.velocities.rows) : (i += 1) {
                var k: i32 = 0;
                while (k < self.velocities.columns) : (k += 1) {
                    // velocities in the x-coordinates
                    const x_neighbors = self.velocities.get(i, k + 1).x + self.velocities.get(i, k - 1).x +
                        self.velocities.get(i + 1, k).x + self.velocities.get(i - 1, k).x;

                    var dividend: f64 = self.velocities.get(i, k).x + (f_diff * x_neighbors);
                    const x_value: f64 = dividend / divisor;

                    // velocities in the y-coordinates
                    const y_neighbors = self.velocities.get(i, k + 1).y + self.velocities.get(i, k - 1).y +
                        self.velocities.get(i + 1, k).y + self.velocities.get(i - 1, k).y;

                    dividend = self.velocities.get(i, k).y + (f_diff * y_neighbors);
                    const y_value: f64 = dividend / divisor;

                    self.velocities.set(i, k, Velocity{
                        .x = x_value,
                        .y = y_value,
                    });
                }
            }
        }
    }

    // #######################
    // #  Utility functions  #
    // #######################

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

    pub fn swap_densities(self: *Fluid) void {
        const tmp = self.densities;
        self.densities = self.densities_x0;
        self.densities_x0 = tmp;
    }

    pub fn swap_velocities(self: *Fluid) void {
        const tmp = self.velocities;
        self.velocities = self.velocities_x0;
        self.velocities_x0 = tmp;
    }
};
