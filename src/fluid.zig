const std = @import("std");
const Grid = @import("lib.zig").Grid;

const LINEAR_SOLVE_ITERATIONS = 2;

pub const Fluid = struct {
    cells_number: usize,
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
            .resolution = resolution,
            .cells_number = size,
            .density = density,
            .density_prev = density_prev,
            .pressure = pressure,
            .divergence = divergence,
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
        const added_density: f32 = 20;
        const new_value: f32 = self.density_prev.get(row, column) + added_density;
        self.density.set(row, column, new_value);
    }

    // pub fn add_velocity(self: Fluid, row: i32, column: i32) void {
    //     // TODO: add velocity based on mouse movement
    // }
};

// ------------------------------
// | Fluid simulation functions |
// ------------------------------

// NOTE: not used yet, at least in this context where the "box" is open, like space invaders
// const FieldType = enum {};
// set_boundary_conditions(type, field, grid_size);

// NOTE: we must add a "fieldtype" parameter if the set set_boundaries is used
fn diffuse(fluid: *Fluid, field: *Grid(f32), field_prev: *Grid(f32), dt: f32, diff: f32) void {
    const float_cells = @as(f32, @floatFromInt(fluid.cells_number));
    const a = dt * diff * float_cells;

    for (0..LINEAR_SOLVE_ITERATIONS) |_| {
        for (1..fluid.cells_number) |i| {
            for (1..fluid.cells_number) |j| {
                // Asegurar que no accedemos fuera de los límites
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

pub fn density_step(fluid: *Fluid) void {
    std.debug.print("Difussing... ", .{});
    diffuse(fluid, &fluid.density, &fluid.density_prev, 1, 2); // Valores más razonables
    std.debug.print("Density step terminated\n", .{});
}
