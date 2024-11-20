const std = @import("std");
const rl = @import("raylib");
const Window = @import("window.zig").Window;

pub fn main() !void {
    const cell_size = 20; // in pixels
    const fps = 120;
    const w_width = 600; // in pixels
    const w_height = 400; // in pixels

    // Initialize the main window
    rl.initWindow(w_width, w_height, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(fps);

    // fluid grids
    var window = Window.init(w_width, w_height, cell_size);

    // main loop
    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.black);

        // Velocity step
        window.simulate();

        // rl.beginDrawing();
        // window.draw();
        window.fluid.velocities_x.print();
        // rl.endDrawing();

        // simple trick to make the simulation slowly fade and reset itself
        window.fluid.densities.grid[
            window.fluid.densities.grid.len - 1
        ] = 0;
    }
}
