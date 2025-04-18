const std = @import("std");
const Grid = @import("lib.zig").Grid;

const LINEAR_SOLVE_ITERATIONS = 20;
const DIFFUSION_RATE: f32 = 2;
const VISCOSITY: f32 = 0.3;

pub const Fluid = struct {
    cells_number: usize,
    rows: usize,
    columns: usize,

    resolution: f32,

    density: Grid(f32),
    density_prev: Grid(f32),
    pressure: Grid(f32),
    divergence: Grid(f32),

    velocity_x: Grid(f32),
    velocity_y: Grid(f32),
    velocity_x_prev: Grid(f32),
    velocity_y_prev: Grid(f32),

    pub fn init(rows: usize, columns: usize) !Fluid {
        const size = rows * columns;

        const size_float: f32 = @floatFromInt(size);
        const resolution: f32 = @divExact(1.0, size_float);

        // Initialize all grids with proper error handling
        var density = try Grid(f32).init(rows, columns);
        errdefer density.deinit();

        var density_prev = try Grid(f32).init(rows, columns);
        errdefer density_prev.deinit();

        var pressure = try Grid(f32).init(rows, columns);
        errdefer pressure.deinit();

        var divergence = try Grid(f32).init(rows, columns);
        errdefer divergence.deinit();

        var velocity_x = try Grid(f32).init(rows, columns);
        errdefer velocity_x.deinit();

        var velocity_y = try Grid(f32).init(rows, columns);
        errdefer velocity_y.deinit();

        var velocity_x_prev = try Grid(f32).init(rows, columns);
        errdefer velocity_x_prev.deinit();

        var velocity_y_prev = try Grid(f32).init(rows, columns);
        errdefer velocity_y_prev.deinit();

        return Fluid{
            .rows = rows,
            .columns = columns,
            .resolution = resolution,
            .cells_number = size,

            .pressure = pressure,
            .divergence = divergence,

            .density = density,
            .density_prev = density_prev,

            .velocity_x = velocity_x,
            .velocity_y = velocity_y,
            .velocity_x_prev = velocity_x_prev,
            .velocity_y_prev = velocity_y_prev,
        };
    }

    pub fn deinit(self: *Fluid) void {
        self.density.deinit();
        self.density_prev.deinit();
        self.pressure.deinit();
        self.divergence.deinit();
        self.velocity_x.deinit();
        self.velocity_y.deinit();
        self.velocity_x_prev.deinit();
        self.velocity_y_prev.deinit();
    }

    pub fn add_density(self: *Fluid, row: usize, column: usize) void {
        const added_density: f32 = 10;
        const new_value: f32 = self.density_prev.get(row, column) + added_density;
        self.density.set(row, column, new_value);
    }

    pub fn swap_fields(self: *Fluid) void {
        std.mem.swap(*Grid(f32), &self.density, &self.density_prev);
        std.mem.swap(*Grid(f32), &self.velocity_x, &self.velocity_x_prev);
        std.mem.swap(*Grid(f32), &self.velocity_y, &self.velocity_y_prev);
    }

    // pub fn add_velocity(self: Fluid, row: i32, column: i32) void {
    //     // TODO: add velocity based on mouse movement
    // }
};

// ------------------------------
// | Fluid simulation functions |
// ------------------------------

// NOTE: We must add a "fieldtype" parameter if the set set_boundaries is used
// not used yet, at least in this context where the "box" is open, like space invaders.
// const FieldType = enum {};
// set_boundary_conditions(type, field, grid_size);

fn diffuse(fluid: *Fluid, field: *Grid(f32), field_prev: *Grid(f32), dt: f32, diff: f32) void {
    const float_cells = @as(f32, @floatFromInt(fluid.cells_number));
    const a = dt * diff * float_cells;

    // Gauss-Seidel aproximation solver
    for (0..LINEAR_SOLVE_ITERATIONS) |_| {
        for (1..fluid.rows) |i| {
            for (1..fluid.columns) |j| {
                const center = field_prev.get(i, j);
                const left = field.get(i - 1, j);
                const right = field.get(i + 1, j);
                const top = field.get(i, j - 1);
                const bottom = field.get(i, j + 1);

                const new_value = (center + a * (left + right + top + bottom)) / (1.0 + 4.0 * a);
                field.set(i, j, new_value);
            }
        }
    }
}

fn advect(fluid: *Fluid, current_field: *Grid(f32), previous_field: *Grid(f32), velocity_x: *Grid(f32), velocity_y: *Grid(f32), dt: f32) void {
    const float_cells = @as(f32, @floatFromInt(fluid.cells_number));
    const scaled_time_step = dt * float_cells;

    for (1..fluid.rows) |i| {
        for (1..fluid.columns) |j| {
            // Calculate new position following fluid flow
            const traced_x = @as(f32, @floatFromInt(i)) - scaled_time_step * velocity_x.get(i, j);
            const traced_y = @as(f32, @floatFromInt(j)) - scaled_time_step * velocity_y.get(i, j);

            // Clamp traced position to grid bounds
            const clamped_x = @max(0.5, @min(traced_x, @as(f32, @floatFromInt(fluid.cells_number)) + 0.5));
            const clamped_y = @max(0.5, @min(traced_y, @as(f32, @floatFromInt(fluid.cells_number)) + 0.5));

            // Get integer coordinates for interpolation
            const base_x = @as(usize, @intFromFloat(clamped_x));
            const next_x = base_x + 1;

            const base_y = @as(usize, @intFromFloat(clamped_y));
            const next_y = base_y + 1;

            // Calculate interpolation weights
            const x_weight = clamped_x - @as(f32, @floatFromInt(base_x));
            const inverse_x_weight = 1.0 - x_weight;

            const y_weight = clamped_y - @as(f32, @floatFromInt(base_y));
            const inverse_y_weight = 1.0 - y_weight;

            // Bilinear interpolation
            const value =
                inverse_x_weight * (inverse_y_weight * previous_field.get(base_x, base_y) +
                    y_weight * previous_field.get(base_x, next_y)) +
                x_weight * (inverse_y_weight * previous_field.get(next_x, base_y) +
                    y_weight * previous_field.get(next_x, next_y));

            current_field.set(i, j, value);
        }
    }

    // setBoundaryConditions(fluid, field_type, current_field);
}

pub fn density_step(fluid: *Fluid, dt: f32) void {
    diffuse(fluid, &fluid.density_prev, &fluid.density, dt, DIFFUSION_RATE);
    advect(fluid, &fluid.density, &fluid.density_prev, &fluid.velocity_x, &fluid.velocity_y, dt);
}
