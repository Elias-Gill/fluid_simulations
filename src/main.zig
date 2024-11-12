const std = @import("std");
const rl = @import("raylib");
const lib = @import("lib.zig");

const Grid = lib.Grid;

pub fn main() !void {
    const cell_size = 2; // in pixels
    const fps = 60;
    const w_width = 200; // in pixels
    const w_height = 200; // in pixels

    // Initialize the main window
    rl.initWindow(w_width, w_height, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(fps);

    // Physics constants
    // const c_dif = 2; // diffusion coeficient
    // const dt = 2; // delta-time

    // fluid grids
    const densities = Grid.init(w_width, w_height, cell_size);

    // main loop
    while (!rl.windowShouldClose()) {
        std.debug.print("\nold value: {}", .{densities.get(2, 2)});
        densities.set(2, 2, 1234);
        std.debug.print("\nnew value{}\n", .{densities.get(2, 2)});
    }
}
