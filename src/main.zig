const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

const lib = @import("lib.zig");
const Grid = lib.Grid;
const Fluid = lib.Fluid;

pub fn main() !void {
    const cell_size = 20; // in pixels
    const fps = 60;
    const w_width = 200; // in pixels
    const w_height = 200; // in pixels

    // Initialize the main window
    rl.initWindow(w_width, w_height, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(fps);

    // fluid grids
    const fluid = Fluid.init(w_width, w_height, cell_size);

    // main loop
    // while (!rl.windowShouldClose()) {
    fluid.densities.set(1, 1, 20);
    fluid.print();

    std.debug.print("\n\n", .{});
    fluid.diffuse();
    fluid.print();
    // }
}
