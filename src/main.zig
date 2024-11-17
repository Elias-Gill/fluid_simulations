const std = @import("std");
const rl = @import("raylib");
const Fluid = @import("fluid.zig").Fluid;

pub fn main() !void {
    const cell_size = 7; // in pixels
    const fps = 120;
    const w_width = 600; // in pixels
    const w_height = 600; // in pixels

    // Initialize the main window
    rl.initWindow(w_width, w_height, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(fps);

    // fluid grids
    const fluid = Fluid.init(w_width, w_height, cell_size);

    // main loop
    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.black);

        fluid.add_forces();
        fluid.diffuse();
        // fluid.advection();

        rl.beginDrawing();
        fluid.draw();
        rl.endDrawing();
    }
}
