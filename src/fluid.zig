const std = @import("std");
const Grid = @import("lib.zig").Grid;

const LINEAR_SOLVE_ITERATIONS = 10;
const DIFFUSION_RATE: f32 = 0.001;  // Para densidad
const VISCOSITY: f32 = 0.001;       // Para velocidad

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
        // First clear previous values if needed
        self.density_prev.set(row, column, 0);

        // Then add new density
        const added_density: f32 = 10;
        self.density.set(row, column, added_density);
        self.density.set(row, column, added_density);
    }

    pub fn add_velocity(self: *Fluid, row: usize, column: usize, x_velocity: f32, y_velocity: f32) void {
        self.velocity_x.set(row, column, x_velocity);
        self.velocity_y.set(row, column, y_velocity);
    }

    pub fn swap_density_fields(self: *Fluid) void {
        std.mem.swap(*Grid(f32), &self.density, &self.density_prev);
    }

    pub fn swap_velocity_x(self: *Fluid) void {
        std.mem.swap(Grid(f32), &self.velocity_x, &self.velocity_x_prev);
    }
    pub fn swap_velocity_y(self: *Fluid) void {
        std.mem.swap(Grid(f32), &self.velocity_y, &self.velocity_y_prev);
    }
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
        for (1..fluid.rows + 1) |i| {
            for (1..fluid.columns + 1) |j| {
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

    for (1..fluid.rows + 1) |i| {
        for (1..fluid.columns + 1) |j| {
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

fn project(fluid: *Fluid, vel_x: *Grid(f32), vel_y: *Grid(f32), pressure: *Grid(f32), divergence: *Grid(f32)) void {
    const h = 1.0 / @as(f32, @floatFromInt(fluid.cells_number));

    // Calculate divergence
    for (1..fluid.rows) |i| {
        for (1..fluid.columns) |j| {
            const div = -0.5 * h * (vel_x.get(i + 1, j) - vel_x.get(i - 1, j) +
                vel_y.get(i, j + 1) - vel_y.get(i, j - 1));
            divergence.set(i, j, div);
            pressure.set(i, j, 0);
        }
    }

    // setBoundaryConditions(fluid, FieldType.scalar, divergence);
    // setBoundaryConditions(fluid, FieldType.scalar, pressure);

    // Solve pressure using Gauss-Seidel
    for (0..LINEAR_SOLVE_ITERATIONS) |_| {
        for (1..fluid.rows) |i| {
            for (1..fluid.columns) |j| {
                const p = (divergence.get(i, j) +
                    pressure.get(i - 1, j) +
                    pressure.get(i + 1, j) +
                    pressure.get(i, j - 1) +
                    pressure.get(i, j + 1)) / 4.0;
                pressure.set(i, j, p);
            }
        }
        // setBoundaryConditions(fluid, FieldType.scalar, pressure);
    }

    // Update velocity field
    for (1..fluid.rows) |i| {
        for (1..fluid.columns) |j| {
            const vel_x_update = 0.5 * (pressure.get(i + 1, j) - pressure.get(i - 1, j)) / h;
            const vel_y_update = 0.5 * (pressure.get(i, j + 1) - pressure.get(i, j - 1)) / h;

            vel_x.set(i, j, vel_x.get(i, j) - vel_x_update);
            vel_y.set(i, j, vel_y.get(i, j) - vel_y_update);
        }
    }

    // setBoundaryConditions(fluid, FieldType.velocity, vel_x);
    // setBoundaryConditions(fluid, FieldType.velocity, vel_y);
}

fn velocity_step(fluid: *Fluid, dt: f32) void {
    // Diffuse velocity X
    fluid.swap_velocity_x();
    diffuse(fluid, &fluid.velocity_x, &fluid.velocity_x_prev, dt, VISCOSITY);

    // Diffuse velocity Y
    fluid.swap_velocity_y();
    diffuse(fluid, &fluid.velocity_y, &fluid.velocity_y_prev, dt, VISCOSITY);

    project(fluid, &fluid.velocity_x, &fluid.velocity_y, &fluid.pressure, &fluid.divergence);

    // Advect velocity X
    fluid.swap_velocity_x();
    advect(fluid, &fluid.velocity_x, &fluid.velocity_x_prev, &fluid.velocity_x_prev, &fluid.velocity_y_prev, dt);

    // Advect velocity Y
    fluid.swap_velocity_y();
    advect(fluid, &fluid.velocity_y, &fluid.velocity_y_prev, &fluid.velocity_x_prev, &fluid.velocity_y_prev, dt);

    project(fluid, &fluid.velocity_x, &fluid.velocity_y, &fluid.pressure, &fluid.divergence);
}

fn density_step(fluid: *Fluid, dt: f32) void {
    diffuse(fluid, &fluid.density_prev, &fluid.density, dt, DIFFUSION_RATE);
    advect(fluid, &fluid.density, &fluid.density_prev, &fluid.velocity_x, &fluid.velocity_y, dt);
}

pub fn simulateFrame(fluid: *Fluid, dt: f32) void {
    // add_velocity_source();
    velocity_step(fluid, dt);
    // add_density_source();
    density_step(fluid, dt);
}
