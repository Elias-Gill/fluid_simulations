/* Original implementation written by Jos Stam 2003 */

#define IX(i, j) ((i) + (N + 2) * (j))

// Simulation parameters
#define N 50                     // Grid size (N x N)
#define size ((N + 2) * (N + 2)) // Total array size including boundaries

// Fluid fields
static float u[size], v[size];            // Velocity fields
static float u_prev[size], v_prev[size];  // Previous velocity fields
static float dens[size], dens_prev[size]; // Density fields
static float p[size], div[size];          // Pressure and divergence fields

// Physical parameters
static float visc = 0.0f;    // Viscosity
static float diff = 0.0001f; // Diffusion rate
static float dt = 0.1f;      // Time step

// Helper macro for swapping pointers
#define SWAP(x0, x)                                                            \
{                                                                              \
    float *tmp = x0;                                                           \
    x0 = x;                                                                    \
    x = tmp;                                                                   \
}

void add_source(float *x, float *s, float dt) {
    int i;
    for (i = 0; i < size; i++)
        x[i] += dt * s[i];
}

void set_bnd(int b, float *x) {
    int i;
    for (i = 1; i <= N; i++) {
        x[IX(0, i)] = b == 1 ? -x[IX(1, i)] : x[IX(1, i)];
        x[IX(N + 1, i)] = b == 1 ? -x[IX(N, i)] : x[IX(N, i)];
        x[IX(i, 0)] = b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
        x[IX(i, N + 1)] = b == 2 ? -x[IX(i, N)] : x[IX(i, N)];
    }
    x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
    x[IX(0, N + 1)] = 0.5f * (x[IX(1, N + 1)] + x[IX(0, N)]);
    x[IX(N + 1, 0)] = 0.5f * (x[IX(N, 0)] + x[IX(N + 1, 1)]);
    x[IX(N + 1, N + 1)] = 0.5f * (x[IX(N, N + 1)] + x[IX(N + 1, N)]);
}

void diffuse(int b, float *x, float *x0, float diff, float dt) {
    int i, j, k;
    float a = dt * diff * N * N;
    for (k = 0; k < 20; k++) {
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= N; j++) {
                x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] +
                            x[IX(i, j - 1)] + x[IX(i, j + 1)])) /
                    (1 + 4 * a);
            }
        }
        set_bnd(b, x);
    }
}

void advect(int b, float *d, float *d0, float *u, float *v, float dt) {
    int i, j, i0, j0, i1, j1;
    float x, y, s0, t0, s1, t1, dt0;
    dt0 = dt * N;
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            x = i - dt0 * u[IX(i, j)];
            y = j - dt0 * v[IX(i, j)];
            if (x < 0.5f)
                x = 0.5f;
            if (x > N + 0.5f)
                x = N + 0.5f;
            i0 = (int)x;
            i1 = i0 + 1;
            if (y < 0.5f)
                y = 0.5f;
            if (y > N + 0.5f)
                y = N + 0.5f;
            j0 = (int)y;
            j1 = j0 + 1;
            s1 = x - i0;
            s0 = 1 - s1;
            t1 = y - j0;
            t0 = 1 - t1;
            d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) +
                s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
        }
    }
    set_bnd(b, d);
}

void project(float *u, float *v, float *p, float *div) {
    int i, j, k;
    float h = 1.0f / N;

    // Calculate divergence
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            div[IX(i, j)] = -0.5f * h *
                (u[IX(i + 1, j)] - u[IX(i - 1, j)] + v[IX(i, j + 1)] -
                 v[IX(i, j - 1)]);
            p[IX(i, j)] = 0;
        }
    }
    set_bnd(0, div);
    set_bnd(0, p);

    // Solve pressure equation
    for (k = 0; k < 20; k++) {
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= N; j++) {
                p[IX(i, j)] = (div[IX(i, j)] + p[IX(i - 1, j)] + p[IX(i + 1, j)] +
                        p[IX(i, j - 1)] + p[IX(i, j + 1)]) /
                    4;
            }
        }
        set_bnd(0, p);
    }

    // Subtract pressure gradient
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            u[IX(i, j)] -= 0.5f * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) / h;
            v[IX(i, j)] -= 0.5f * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) / h;
        }
    }
    set_bnd(1, u);
    set_bnd(2, v);
}

void vel_step(float *u, float *v, float *u0, float *v0, float visc, float dt) {
    add_source(u, u0, dt);
    add_source(v, v0, dt);
    SWAP(u0, u);
    diffuse(1, u, u0, visc, dt);
    SWAP(v0, v);
    diffuse(2, v, v0, visc, dt);
    project(u, v, u0, v0);
    SWAP(u0, u);
    SWAP(v0, v);
    advect(1, u, u0, u0, v0, dt);
    advect(2, v, v0, u0, v0, dt);
    project(u, v, u0, v0);
}

void dens_step(float *x, float *x0, float *u, float *v, float diff, float dt) {
    add_source(x, x0, dt);
    SWAP(x0, x);
    diffuse(0, x, x0, diff, dt);
    SWAP(x0, x);
    advect(0, x, x0, u, v, dt);
}

// User interaction functions (to be implemented)
void get_from_UI(float *dens_prev, float *u_prev, float *v_prev) {
    // Add your user input handling here
    // For example, add density/velocity sources based on mouse input
}

void draw_dens(float *dens) {
    // Add your rendering code here
    // Visualize the density field
}

// Main simulation loop
int main() {
    // Initialize all arrays to zero
    for (int i = 0; i < size; i++) {
        u[i] = v[i] = u_prev[i] = v_prev[i] = 0.0f;
        dens[i] = dens_prev[i] = 0.0f;
    }

    int simulating = 1; // Control variable for the simulation loop

    while (simulating) {
        get_from_UI(dens_prev, u_prev, v_prev);
        vel_step(u, v, u_prev, v_prev, visc, dt);
        dens_step(dens, dens_prev, u, v, diff, dt);
        draw_dens(dens);

        // Add some delay or frame rate control if needed
    }

    return 0;
}
