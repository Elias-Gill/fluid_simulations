const std = @import("std");
const Grid = @import("lib.zig").Grid;

// Struct that represents the fluid.
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

    pub fn add_density(self: Fluid, row: i32, column: i32) void {
        const new_value: f64 = self.densities_x0.get(row, column) + self.added_density;
        self.densities.set(row, column, new_value);
    }
};

// Fluid simulation functions
