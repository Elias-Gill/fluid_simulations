const std = @import("std");
const Color = @import("raylib").Color;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: std.mem.Allocator = gpa.allocator();

// Struct that represents a matrix using vectors. It offers some useful operations
// to simplify data manipulation.
pub fn Grid(comptime T: type) type {
    return struct {
        columns: usize,
        rows: usize,
        length: usize,
        grid: []T, // Removed length since it's redundant (rows*columns)

        pub fn init(rows: usize, columns: usize) !Grid(T) {
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

        pub fn deinit(self: *Grid(T)) void {
            allocator.free(self.grid);
        }

        pub fn get(self: *Grid(T), row: usize, column: usize) T {
            // Direct access without modulo - bounds checking only in debug
            var index = row * self.columns + column;
            while (index >= self.length) {
                index -= self.length;
            }
            return self.grid[index];
        }

        pub fn set(self: *Grid(T), row: usize, column: usize, value: T) void {
            var index = row * self.columns + column;
            while (index >= self.length) {
                index -= self.length;
            }
            self.grid[index] = value;
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

        fn calculate_position(self: Grid(T), row: usize, column: usize) usize {
            var position = @mod(row * self.columns + column, self.rows * self.columns);
            if (position < 0) {
                position = position + (self.rows * self.columns);
            }
            return position;
        }
    };
}
