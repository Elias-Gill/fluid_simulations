const std = @import("std");
const testing = std.testing;

const Grid = @import("lib.zig").Grid;

test "Grid initialization" {
    const grid = Grid.init(100, 50, 10);
    defer grid.deinit();

    try testing.expect(grid.start_x == 0);
    try testing.expect(grid.end_x == 100);

    try testing.expect(grid.start_y == 0);
    try testing.expect(grid.end_y == 50);

    try testing.expect(grid.rows == 5);
    try testing.expect(grid.columns == 10);
}

test "Memory allocation for zeros" {
    const grid = Grid.init(10, 20, 2);
    defer grid.deinit();

    // Verificar que el array está lleno de ceros
    for (grid.grid) |value| {
        try testing.expect(value == 0);
    }
}

test "Grid access" {
    const grid = Grid.init(10, 20, 2);
    defer grid.deinit();

    // Establecer un valor en una posición específica
    grid.set(1, 1, 42);

    // Verificar el valor establecido
    try testing.expect(grid.get(1, 1) == 42);
}

test "Grid bounds checking" {
    const grid = Grid.init(10, 20, 2);
    defer grid.deinit();

    // Intentar acceder fuera de los límites del grid, no deberia de crashear
    try testing.expect(grid.get(200, 200) == 0);
}
