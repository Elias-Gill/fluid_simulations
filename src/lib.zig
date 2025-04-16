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
        columns: usize,
        rows: usize,
        length: usize,
        grid: []T, // single array of bools to be more "performant" (actually just for fun).

        pub fn init(rows: u32, columns: u32) !Grid(T) {
            const size = std.math.mul(usize, rows, columns) catch return error.Overflow;
            const array = allocator.alloc(T, size) catch {
                std.debug.panic("Failed to allocate memory", .{});
            };

            // Zero-initialize the entire array
            const zero = std.mem.zeroes(T);
            for (array) |*item| {
                item.* = zero;
            }

            return .{
                .rows = rows,
                .columns = columns,
                .length = size,
                .grid = array,
            };
        }

        pub fn deinit(self: Grid(T)) void {
            allocator.free(self.grid);
        }

        fn calculate_position(self: Grid(T), row: usize, column: usize) usize {
            var position = @mod(row * self.columns + column, self.rows * self.columns);
            if (position < 0) {
                position = position + (self.rows * self.columns);
            }
            return position;
        }

        pub fn get(self: Grid(T), row: usize, column: usize) T {
            const position: usize = @intCast(self.calculate_position(row, column));
            return self.grid[position];
        }

        pub fn set(self: Grid(T), row: usize, column: usize, value: T) void {
            const position: usize = @intCast(self.calculate_position(row, column));
            self.grid[position] = value;
        }

        pub fn print(self: Grid(T)) void {
            var row: i32 = 0;
            while (row < self.rows) : (row += 1) {
                std.debug.print(" | ", .{});

                var column: i32 = 0;
                while (column < self.columns) : (column += 1) {
                    std.debug.print("{} | ", .{self.get(row, column)});
                }

                std.debug.print("\n", .{});
            }
        }
    };
}
