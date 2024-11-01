const std = @import("std");
const lib = @import("lib.zig");
const rl = @import("raylib");

pub fn main() !void {
    // Initialize the main window
    rl.initWindow(200, 200, "Fluid simulation");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // main loop
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.endDrawing();
    }
}
