const std = @import("std");
const rl = @import("raylib");
const Window = @import("window.zig").Window;
const fluids = @import("fluid.zig");

pub fn main() anyerror!void {
    // Raylib Initialization
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setTargetFPS(60);
    rl.initWindow(screenWidth, screenHeight, "Jos Stam - Fluid Simulation");
    defer rl.closeWindow();

    // Window renderer instantiation
    var win = Window.init(screenWidth, screenHeight, 12);
    std.debug.print("Grid: {}x{}\n", .{win.rows, win.columns});

    // Fluid instantiation
    var fl: fluids.Fluid = try fluids.Fluid.init(win.rows, win.columns);
    defer fl.deinit();

    // Main loop
    rl.clearBackground(.black);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        fl.add_density(40, 40);
        fluids.density_step(&fl);
        win.draw_frame(&fl);

        rl.endDrawing();
    }
}
