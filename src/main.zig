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
    var win = Window.init(screenWidth, screenHeight, 4);
    std.debug.print("Grid: {}x{}\n", .{ win.rows, win.columns });

    // Fluid instantiation
    var fl: fluids.Fluid = try fluids.Fluid.init(win.rows, win.columns);
    defer fl.deinit();

    // Main loop
    rl.clearBackground(.black);
    var last_time: f32 = 0;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        const curr_time: f32 = @floatCast(rl.getTime());
        const lapsed_time = curr_time - last_time;
        defer last_time = @floatCast(rl.getTime());

        applyUserInput(win, &fl);
        fluids.density_step(&fl, lapsed_time);

        win.draw_frame(&fl);
    }
}

fn applyUserInput(win: Window, fl: *fluids.Fluid) void {
    if (rl.isMouseButtonDown(.left)) {
        const position = win.find_cell() catch {
            return;
        };
        fl.add_density(position[0], position[1]);
        fl.velocity_x.set(position[0], position[1], 20);
    }
}
