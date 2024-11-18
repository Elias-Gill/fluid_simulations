const std = @import("std");
const rl = @import("raylib");
const Window = @import("window.zig").Window;

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
    var window = Window.init(w_width, w_height, cell_size);

    // main loop
    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.black);

        // Velocity step
        window.apply_user_inputs();
        
        // Density step
        window.fluid.diffuse_densities();
        // window.fluid.swap_densities();
        // window.fluid.advection();

        rl.beginDrawing();
        window.draw();
        rl.endDrawing();

        // simple trick to make the simulation slowly fade and reset itself
        window.fluid.densities.grid[
            window.fluid.densities.grid.len - 1
        ] = 0;
    }
}
