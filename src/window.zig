const rl = @import("raylib");
const std = @import("std");

const Color = rl.Color;
const Fluid = @import("fluid.zig").Fluid;

pub const MouseToGridError = error{InvalidPosition};

pub const Window = struct {
    cell_size: i32,
    rows: usize,
    columns: usize,

    // coordinates to place the draw of the fluid in the screen
    start_x: i32,
    end_x: i32,
    start_y: i32,
    end_y: i32,

    pub fn init(h: i32, w: i32, cell_size: i32) Window {
        // Grid initialization.
        // Calculate some padding to not "overflow" the UI when drawing.
        const x_padding: i32 = @mod(w, cell_size);
        const y_padding: i32 = @mod(h, cell_size);

        // Calculate the actual amount of rows and columns for the grid
        const rows: usize = @intCast(@divFloor(h - y_padding, cell_size));
        const columns: usize = @intCast(@divFloor(w - x_padding, cell_size));

        // Apply the padding and change the position of the drawing limits.
        var fluid_start_x: i32 = 0;
        var fluid_end_x: i32 = w;

        const x_pad_half = if (@mod(x_padding, 2) == 0)
            @divFloor(x_padding, 2)
        else
            @divFloor(x_padding - 1, 2) + 1;

        fluid_start_x += x_pad_half;
        fluid_end_x -= @divFloor(x_padding, 2);

        var fluid_start_y: i32 = 0;
        var fluid_end_y: i32 = h;

        const y_pad_half = if (@mod(y_padding, 2) == 0)
            @divFloor(y_padding, 2)
        else
            @divFloor(y_padding - 1, 2) + 1;

        fluid_start_y += y_pad_half;
        fluid_end_y -= @divFloor(y_padding, 2);

        return Window{
            .start_x = fluid_start_x,
            .end_x = fluid_end_x,
            .start_y = fluid_start_y,
            .end_y = fluid_end_y,
            .cell_size = cell_size,
            .rows = rows,
            .columns = columns,
        };
    }

    // Transpolates the mouse position to a cell of the fluid
    fn find_cell(self: Window) ![2]usize {
        const mouse_x = rl.getMouseX();
        const mouse_y = rl.getMouseY();

        // check out of bounds position
        if (mouse_x < self.start_x or mouse_y < self.start_y or
            mouse_x > self.end_x or mouse_y > self.end_y)
        {
            return MouseToGridError.InvalidPosition;
        }

        const row: usize = @intCast(@divFloor(mouse_y - self.start_y, self.cell_size));
        const column: usize = @intCast(@divFloor(mouse_x - self.start_x, self.cell_size));

        return .{ row, column };
    }

    fn calculate_color(density: f32, velocity: f32) rl.Color {
        // A intensity gradient of white tones
        const intensity = @as(u8, @intFromFloat(@min(255.0, 255.0 * density)));
        const color = @as(u8, @intFromFloat(@mod(velocity, 255.0)));

        return rl.Color.init(255, color, 255, intensity);
    }

    pub fn draw_frame(self: Window, fluid: Fluid) void {
        std.debug.print("\nRendering Frame", .{});
        var row: usize = 0;
        while (row < fluid.density.rows) : (row += 1) {
            var column: usize = 0;
            while (column < fluid.density.columns) : (column += 1) {
                const y = @as(i32, @intCast(row)) * self.cell_size + self.start_y;
                const x = @as(i32, @intCast(column)) * self.cell_size + self.start_x;

                const density = fluid.density.get(row, column);
                const velocity = fluid.velocity_x.get(row, column) + 
                               fluid.velocity_y.get(row, column);
                const color = calculate_color(density, velocity);

                rl.drawRectangle(
                    @intCast(x),
                    @intCast(y),
                    self.cell_size,
                    self.cell_size,
                    color
                );
            }
        }
    }

    // NOTE: example implementation on how to get user input
    // fn apply_user_inputs(self: Window) void {
    //     if (!rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
    //         return;
    //     }
    //
    //     const positions = self.find_cell() catch {
    //         std.debug.print("\nMouse out of bounds", .{});
    //         return;
    //     };
    //
    //     const row = positions[0];
    //     const column = positions[1];
    //
    //     self.fluid.add_density(row, column);
    //     self.fluid.add_velocity(row, column, 14, 14);
    // }
};
