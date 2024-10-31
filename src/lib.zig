const std = @import("std");

pub fn hola() void {
    std.debug.print("hola {s}", .{"codebase"});
}
