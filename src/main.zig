const std = @import("std");
const rl = @import("raylib");
const Fluid = @import("fluid.zig").Fluid;

pub fn main() !void {
    const cell_size = 4; // in pixels
    const fps = 120;
    const w_width = 800; // in pixels
    const w_height = 800; // in pixels

    // Initialize the main window
    rl.initWindow(w_width, w_height, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(fps);

    // fluid grids
    const fluid = Fluid.init(w_width, w_height, cell_size);

    // test data
    fluid.densities.set(101, 100, 1234);
    fluid.densities.set(105, 100, 1234);
    fluid.densities.set(107, 100, 1234);
    fluid.densities.set(109, 100, 1234);
    fluid.densities.set(111, 100, 1234);
    fluid.densities.set(121, 100, 1236);
    fluid.densities.set(133, 100, 1234);
    fluid.densities.set(143, 100, 1236);

    // main loop
    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.black);

        fluid.diffuse();

        rl.beginDrawing();
        fluid.draw();
        rl.endDrawing();

    }
}
