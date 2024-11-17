const rl = @import("raylib");
const std = @import("std");
const Color = rl.Color;
const Fluid = @import("fluid.zig").Fluid;

pub const MouseToGridError = error{InvalidPosition};

pub const Window = struct {
    fluid: Fluid,
    cell_size: i32,
    // coordinates to place the draw of the fluid in the screen
    start_x: i32,
    end_x: i32,
    start_y: i32,
    end_y: i32,

    // Transpolates the mouse position to a cell of the fluid
    fn find_cell(self: Window) ![2]i32 {
        const mouse_x: i32 = rl.getMouseX();
        const mouse_y: i32 = rl.getMouseY();

        // check out of bounds position
        if (mouse_x < self.start_x or mouse_y < self.start_y) {
            return MouseToGridError.InvalidPosition;
        }

        if (mouse_x > self.end_x or mouse_y > self.end_y) {
            return MouseToGridError.InvalidPosition;
        }

        const row: i32 = @divFloor(mouse_y - self.start_y, self.cell_size);
        const column: i32 = @divFloor(mouse_x - self.start_x, self.cell_size);

        return .{ row, column };
    }

    pub fn apply_user_inputs(self: Window) void {
        if (!rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
            return;
        }

        const positions = self.find_cell() catch {
            std.debug.print("\nMouse out of bounds", .{});
            return;
        };

        const row = positions[0];
        const column = positions[1];

        self.fluid.add_density(row, column);
    }

    fn calculate_color(density: f64) rl.Color {
        // A intensity gradient of white tones
        const intensity: u8 = @intFromFloat(255 * density);
        return rl.Color.init(255, 255, 255, intensity);
    }

    pub fn draw(self: Window) void {
        var row: i32 = 0;
        while (row < self.fluid.densities.rows) : (row += 1) {
            var column: i32 = 0;
            while (column < self.fluid.densities.columns) : (column += 1) {
                const y: i32 = @intCast(row * self.cell_size + self.start_y);
                const x: i32 = @intCast(column * self.cell_size + self.start_x);

                const density = self.fluid.densities.get(row, column);
                const color = calculate_color(density);

                rl.drawRectangle(x, y, self.cell_size, self.cell_size, color);
            }
        }
    }

    pub fn init(h: i32, w: i32, cell_size: i32) Window {
        // Grid initialization.
        // Calculate some padding to not "overflow" the UI when drawing.
        var x_padding: i32 = @mod(w, cell_size);
        var y_padding: i32 = @mod(h, cell_size);

        // Calculate the actual amount of rows and columns for the grid, using the padding
        // and dividing by the size of a single particle.
        const rows: i32 = @divFloor(h - y_padding, cell_size);
        const columns: i32 = @divFloor(w - x_padding, cell_size);

        // Apply the padding and change the position of the drawing limits.
        var fluid_start_x: i32 = 0;
        var fluid_end_x: i32 = w;

        if (@mod(x_padding, 2) == 0) {
            fluid_start_x += @divFloor(x_padding, 2);
            fluid_end_x -= @divFloor(x_padding, 2);
        } else { // uneven padding
            x_padding -= 1;
            fluid_start_x += 1 + @divFloor(x_padding, 2);
            fluid_end_x -= @divFloor(x_padding, 2);
        }

        var fluid_start_y: i32 = 0;
        var fluid_end_y: i32 = h;

        if (@mod(y_padding, 2) == 0) {
            fluid_start_y += @divFloor(y_padding, 2);
            fluid_end_y -= @divFloor(y_padding, 2);
        } else {
            y_padding -= 1;
            fluid_start_y += 1 + @divFloor(y_padding, 2);
            fluid_end_y -= @divFloor(y_padding, 2);
        }

        return Window{
            .start_x = fluid_start_x,
            .end_x = fluid_end_x,
            .start_y = fluid_start_y,
            .end_y = fluid_end_y,
            .fluid = Fluid.init(rows, columns),
            .cell_size = cell_size,
        };
    }
};
