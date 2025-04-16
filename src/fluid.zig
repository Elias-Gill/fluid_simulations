const std = @import("std");
const Grid = @import("lib.zig").Grid;

// Struct that represents the fluid.
pub const Fluid = struct {
    grid_size: i32,
    total_cells: i32,

    density: Grid(f32),
    density_prev: Grid(f32),
    pressure: Grid(f32),
    divergence: Grid(f32),

    velocity_x: Grid(f32),
    velocity_y: Grid(f32),
    velocity_x_prev: Grid(f32),
    velocity_y_prev: Grid(f32),

    pub fn init(rows: i32, columns: i32) Fluid {
        return Fluid{
            .densities = Grid(f64).init(rows, columns),
            .densities_x0 = Grid(f64).init(rows, columns),
            .velocities_x = Grid(f64).init(rows, columns),
            .velocities_x0 = Grid(f64).init(rows, columns),
            .velocities_y = Grid(f64).init(rows, columns),
            .velocities_y0 = Grid(f64).init(rows, columns),
        };
    }

    pub fn deinit(self: Fluid) void {
        self.densities.deinit();
    }

    pub fn simulate_frame(self: *Fluid) void {
        // self.diffuse_velocities();
        // self.project_velocities();
        // // self advection
        // self.advect_vectors(self.velocities_x, self.velocities_x0, self.velocities_y0, self.velocities_x0);
        // self.advect_vectors(self.velocities_y, self.velocities_y0, self.velocities_y0, self.velocities_x0);
        // self.project_velocities();
        //
        // // density step
        self.diffuse_densities();
        // self.advect_vectors(self.densities_x0, self.densities, self.velocities_y, self.velocities_x);
    }

    // ##################
    // #  Density Step  #
    // ##################

    fn diffuse_densities(self: Fluid) void {
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

                    const dividend: f64 = self.densities_x0.get(i, k) + (f_diff * neighbors);
                    const value: f64 = dividend / divisor;

                    self.densities.set(i, k, value);
                }
            }
        }
    }

    pub fn add_density(self: Fluid, row: i32, column: i32) void {
        const new_value: f64 = self.densities_x0.get(row, column) + self.added_density;
        self.densities.set(row, column, new_value);
    }
};
