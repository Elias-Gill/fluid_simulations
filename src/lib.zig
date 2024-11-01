const std = @import("std");

pub fn hola() void {
    std.debug.print("Probando {s}", .{"codebase"});
}
