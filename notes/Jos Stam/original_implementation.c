#include <stdlib.h>

#define GRID_SIZE 50
#define TIME_STEP 0.1f
#define DIFFUSION_RATE 0.001f
#define VISCOSITY 0.2f
#define LINEAR_SOLVE_ITERATIONS 20

typedef enum {
    FIELD_SCALAR = 0,
    FIELD_VELOCITY = 1,
} FieldType;

typedef struct {
    int grid_size;
    int total_cells;

    float *density, *density_prev;
    float *velocity_x, *velocity_y;
    float *velocity_x_prev, *velocity_y_prev;
    float *pressure, *divergence;
} FluidGrid;

// Calculates the one-dimensional grid index from a 2d-coordinate (i, j).
int calculate_index(int i, int j, int grid_size) {
    return i + (grid_size + 2) * j;
}

float clamp(float value, float min_val, float max_val) {
    if (value < min_val)
        return min_val;
    if (value > max_val)
        return max_val;
    return value;
}

inline void swap_pointers(float **a, float **b) {
    float *tmp = *a;
    *a = *b;
    *b = tmp;
}

FluidGrid create_grid(int size) {
    FluidGrid grid;

    grid.grid_size = size;
    grid.total_cells = (size + 2) * (size + 2);

    grid.density = calloc(grid.total_cells, sizeof(float));
    grid.density_prev = calloc(grid.total_cells, sizeof(float));

    grid.velocity_x = calloc(grid.total_cells, sizeof(float));
    grid.velocity_y = calloc(grid.total_cells, sizeof(float));
    grid.velocity_x_prev = calloc(grid.total_cells, sizeof(float));
    grid.velocity_y_prev = calloc(grid.total_cells, sizeof(float));

    grid.pressure = calloc(grid.total_cells, sizeof(float));
    grid.divergence = calloc(grid.total_cells, sizeof(float));

    return grid;
}

void free_grid(FluidGrid *grid) {
    free(grid->density);
    free(grid->density_prev);
    free(grid->velocity_x);
    free(grid->velocity_y);
    free(grid->velocity_x_prev);
    free(grid->velocity_y_prev);
    free(grid->pressure);
    free(grid->divergence);
}

void add_source(float *field, float *source, float dt, int size) {
    for (int i = 0; i < size; i++) {
        field[i] += dt * source[i];
    }
}

/*
   Boundary conditions affect how the simulation behaves at the edges of the
   grid.

   For scalar fields (like smoke density):
   - We want the values to "stick" to the wall or reflect symmetrically.
   - No flow across the boundary (Neumann condition), so we mirror values at
   edges.

   For velocity fields (vector fields):
   - We simulate solid boundaries (like walls).
   - Velocity component perpendicular to the wall is inverted (bounced),
   simulating a collision.
   - Velocity component parallel to the wall is mirrored (unchanged).

   Field type mapping:
   - FIELD_SCALAR     (0): mirror all edges (used for things like density).
   - FIELD_VELOCITY_X (1): flip horizontal component at left/right (vertical)
   walls.
   - FIELD_VELOCITY_Y (2): flip vertical component at top/bottom (horizontal)
   walls.

Note: in this simple version I'm not diferentite between vertical and horizontal
boundaries behavior.
*/
void set_boundary_conditions(FieldType type, float *field, int grid_size) {
    for (int i = 1; i <= grid_size; i++) {
        // Para campos de velocidad, invertir la velocidad en los bordes (rebote
        // en paredes)
        if (type == FIELD_VELOCITY) {
            field[calculate_index(0, i, grid_size)] =
                -field[calculate_index(1, i, grid_size)];
            field[calculate_index(grid_size + 1, i, grid_size)] =
                -field[calculate_index(grid_size, i, grid_size)];
        } else {
            // Para campos escalares (como densidad), reflejar valores en los bordes
            field[calculate_index(0, i, grid_size)] =
                field[calculate_index(1, i, grid_size)];
            field[calculate_index(grid_size + 1, i, grid_size)] =
                field[calculate_index(grid_size, i, grid_size)];
        }
    }

    // Esquinas
    field[calculate_index(0, 0, grid_size)] =
        0.5f * (field[calculate_index(1, 0, grid_size)] +
                field[calculate_index(0, 1, grid_size)]);
    field[calculate_index(0, grid_size + 1, grid_size)] =
        0.5f * (field[calculate_index(1, grid_size + 1, grid_size)] +
                field[calculate_index(0, grid_size, grid_size)]);
    field[calculate_index(grid_size + 1, 0, grid_size)] =
        0.5f * (field[calculate_index(grid_size, 0, grid_size)] +
                field[calculate_index(grid_size + 1, 1, grid_size)]);
    field[calculate_index(grid_size + 1, grid_size + 1, grid_size)] =
        0.5f * (field[calculate_index(grid_size, grid_size + 1, grid_size)] +
                field[calculate_index(grid_size + 1, grid_size, grid_size)]);
}

void diffuse(FieldType type, float *field, float *field_prev, float diff,
        float dt, int grid_size) {
    float a = dt * diff * grid_size * grid_size;

    for (int k = 0; k < LINEAR_SOLVE_ITERATIONS; k++) {
        for (int i = 1; i <= grid_size; i++) {
            for (int j = 1; j <= grid_size; j++) {
                field[calculate_index(i, j, grid_size)] =
                    (field_prev[calculate_index(i, j, grid_size)] +
                     a * (field[calculate_index(i - 1, j, grid_size)] +
                         field[calculate_index(i + 1, j, grid_size)] +
                         field[calculate_index(i, j - 1, grid_size)] +
                         field[calculate_index(i, j + 1, grid_size)])) /
                    (1 + 4 * a);
            }
        }
        set_boundary_conditions(type, field, grid_size);
    }
}

void advect(FieldType field_type, float *current_field, float *previous_field,
        float *velocity_x, float *velocity_y, float time_step,
        int grid_size) {
    float scaled_time_step = time_step * grid_size;

    for (int cell_i = 1; cell_i <= grid_size; cell_i++) {
        for (int cell_j = 1; cell_j <= grid_size; cell_j++) {
            // Calcular nueva posición siguiendo el flujo del fluido
            float traced_x =
                cell_i - scaled_time_step *
                velocity_x[calculate_index(cell_i, cell_j, grid_size)];
            float traced_y =
                cell_j - scaled_time_step *
                velocity_y[calculate_index(cell_i, cell_j, grid_size)];

            // Asegurar que la posición trazada esté dentro de los límites
            traced_x = clamp(traced_x, 0.5f, grid_size + 0.5f);
            traced_y = clamp(traced_y, 0.5f, grid_size + 0.5f);

            // Obtener las coordenadas enteras para la interpolación
            int base_x = (int)traced_x;
            int next_x = base_x + 1;

            int base_y = (int)traced_y;
            int next_y = base_y + 1;

            // Calcular pesos de interpolación
            float x_weight = traced_x - base_x;
            float inverse_x_weight = 1.0f - x_weight;

            float y_weight = traced_y - base_y;
            float inverse_y_weight = 1.0f - y_weight;

            // Interpolación bilineal
            current_field[calculate_index(cell_i, cell_j, grid_size)] =
                inverse_x_weight *
                (inverse_y_weight *
                 previous_field[calculate_index(base_x, base_y, grid_size)] +
                 y_weight *
                 previous_field[calculate_index(base_x, next_y, grid_size)]) +
                x_weight *
                (inverse_y_weight *
                 previous_field[calculate_index(next_x, base_y, grid_size)] +
                 y_weight *
                 previous_field[calculate_index(next_x, next_y, grid_size)]);
        }
    }

    set_boundary_conditions(field_type, current_field, grid_size);
}

void project(float *vel_x, float *vel_y, float *pressure, float *divergence,
        int grid_size) {

    float h = 1.0f / grid_size; // grid cell size (resolution)

    for (int i = 1; i <= grid_size; i++) {
        for (int j = 1; j <= grid_size; j++) {
            divergence[calculate_index(i, j, grid_size)] =
                -0.5f * h *
                (vel_x[calculate_index(i + 1, j, grid_size)] -
                 vel_x[calculate_index(i - 1, j, grid_size)] +
                 vel_y[calculate_index(i, j + 1, grid_size)] -
                 vel_y[calculate_index(i, j - 1, grid_size)]);
            pressure[calculate_index(i, j, grid_size)] = 0;
        }
    }

    set_boundary_conditions(FIELD_SCALAR, divergence, grid_size);
    set_boundary_conditions(FIELD_SCALAR, pressure, grid_size);

    for (int k = 0; k < LINEAR_SOLVE_ITERATIONS; k++) {
        for (int i = 1; i <= grid_size; i++) {
            for (int j = 1; j <= grid_size; j++) {
                pressure[calculate_index(i, j, grid_size)] =
                    (divergence[calculate_index(i, j, grid_size)] +
                     pressure[calculate_index(i - 1, j, grid_size)] +
                     pressure[calculate_index(i + 1, j, grid_size)] +
                     pressure[calculate_index(i, j - 1, grid_size)] +
                     pressure[calculate_index(i, j + 1, grid_size)]) /
                    4;
            }
        }
        set_boundary_conditions(FIELD_SCALAR, pressure, grid_size);
    }

    for (int i = 1; i <= grid_size; i++) {
        for (int j = 1; j <= grid_size; j++) {
            vel_x[calculate_index(i, j, grid_size)] -=
                0.5f *
                (pressure[calculate_index(i + 1, j, grid_size)] -
                 pressure[calculate_index(i - 1, j, grid_size)]) /
                h;
            vel_y[calculate_index(i, j, grid_size)] -=
                0.5f *
                (pressure[calculate_index(i, j + 1, grid_size)] -
                 pressure[calculate_index(i, j - 1, grid_size)]) /
                h;
        }
    }

    set_boundary_conditions(FIELD_VELOCITY, vel_x, grid_size);
    set_boundary_conditions(FIELD_VELOCITY, vel_y, grid_size);
}

void simulate_velocity_step(FluidGrid *grid, float viscosity, float dt) {
    add_source(grid->velocity_x, grid->velocity_x_prev, dt, grid->total_cells);
    add_source(grid->velocity_y, grid->velocity_y_prev, dt, grid->total_cells);

    // Diffuse velocity X
    swap_pointers(&grid->velocity_x_prev, &grid->velocity_x);
    diffuse(FIELD_VELOCITY, grid->velocity_x, grid->velocity_x_prev, viscosity,
            dt, grid->grid_size);

    // Diffuse velocity Y
    swap_pointers(&grid->velocity_y_prev, &grid->velocity_y);
    diffuse(FIELD_VELOCITY, grid->velocity_y, grid->velocity_y_prev, viscosity,
            dt, grid->grid_size);

    project(grid->velocity_x, grid->velocity_y, grid->pressure, grid->divergence,
            grid->grid_size);

    // Advect velocity X
    swap_pointers(&grid->velocity_x_prev, &grid->velocity_x);
    advect(FIELD_VELOCITY, grid->velocity_x, grid->velocity_x_prev,
            grid->velocity_x_prev, grid->velocity_y_prev, dt, grid->grid_size);

    // Advect velocity Y
    swap_pointers(&grid->velocity_y_prev, &grid->velocity_y);
    advect(FIELD_VELOCITY, grid->velocity_y, grid->velocity_y_prev,
            grid->velocity_x_prev, grid->velocity_y_prev, dt, grid->grid_size);

    project(grid->velocity_x, grid->velocity_y, grid->pressure, grid->divergence,
            grid->grid_size);
}

void simulate_density_step(FluidGrid *grid, float diffusion, float dt) {
    add_source(grid->density, grid->density_prev, dt, grid->total_cells);

    // Diffuse density
    swap_pointers(&grid->density_prev, &grid->density);
    diffuse(FIELD_SCALAR, grid->density, grid->density_prev, diffusion, dt,
            grid->grid_size);

    // Advect density
    swap_pointers(&grid->density_prev, &grid->density);
    advect(FIELD_SCALAR, grid->density, grid->density_prev, grid->velocity_x,
            grid->velocity_y, dt, grid->grid_size);
}

int main() {
    FluidGrid fluid = create_grid(GRID_SIZE);

    while (1) {
        // Agregar entrada del usuario (ejemplo, agregando densidad o velocidades)
        simulate_velocity_step(&fluid, VISCOSITY, TIME_STEP);
        simulate_density_step(&fluid, DIFFUSION_RATE, TIME_STEP);
        // Render de la simulacion
    }

    free_grid(&fluid);
    return 0;
}
