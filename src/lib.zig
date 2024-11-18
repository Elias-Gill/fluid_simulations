const std = @import("std");
const Color = @import("raylib").Color;

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: Allocator = gpa.allocator();

// Struct that represents a matrix using vectors. It offers some useful operations
// to simplify data manipulation.
pub fn Grid(comptime T: type) type {
    return struct {
        // the actual array of points that composes the grid.
        columns: i32,
        rows: i32,
        grid: []T, // single array of bools to be more "performant" (actually just for fun).

        pub fn init(rows: i32, columns: i32) Grid(T) {
            const size: usize = @intCast(rows * columns);
            const array = allocator.alloc(T, size) catch {
                std.debug.panic("Failed to allocate memory", .{});
            };

            return .{
                .rows = rows,
                .columns = columns,
                .grid = array,
            };
        }

        pub fn deinit(self: Grid(T)) void {
            allocator.free(self.grid);
        }

        fn calculate_position(self: Grid(T), row: i32, column: i32) i32 {
            var position = @mod(row * self.columns + column, self.rows * self.columns);
            if (position < 0) {
                position = position + (self.rows * self.columns);
            }
            return position;
        }

        pub fn get(self: Grid(T), row: i32, column: i32) T {
            const position: usize = @intCast(self.calculate_position(row, column));
            return self.grid[position];
        }

        pub fn set(self: Grid(T), row: i32, column: i32, value: T) void {
            const position: usize = @intCast(self.calculate_position(row, column));
            self.grid[position] = value;
        }
    };
}
