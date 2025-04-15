# Explicación Paso a Paso del Simulador de Fluidos de Jos Stam

Voy a explicarte el algoritmo de simulación de fluidos de Jos Stam de manera abstracta, sin
atarte a la implementación en C, para que puedas implementarlo en otro lenguaje.
Me enfocaré en los conceptos matemáticos, las entradas/salidas de cada función y su propósito.

## Estructura General

El simulador tiene 3 componentes principales:
1. **Campo de velocidad** (u, v):
   Representa el movimiento del fluido 
2. **Campo de densidad** (dens):
   Representa sustancias en el fluido (como humo o tinte) 
3. **Proyección**:
   Mantiene el fluido incompresible

## Funciones Clave

### 1. `set_bnd(N, b, x)`

**Propósito**:
Aplicar condiciones de frontera a un campo (velocidad o densidad).

**Entradas**:
- `N`:
  Tamaño de la grilla (N×N)
- `b`:
  Tipo de condición de frontera (1=horizontal, 2=vertical, 0=densidad)
- `x`:
  Campo al que aplicar las condiciones (se modifica in-place)

**Lógica**:
- Para fronteras laterales (i=0, i=N+1):
- Si b=1 (velocidad horizontal), refleja invertido
- Si b=2 (velocidad vertical) o 0 (densidad), refleja normal
- Para esquinas:
  promedio de los vecinos adyacentes

### 2. `diffuse(N, b, x, x0, diff, dt)`

**Propósito**:
Difundir un campo (velocidad o densidad) según coeficiente de difusión.

**Entradas**:
- `N`, `b`:
  Como en set_bnd
- `x`:
  Campo resultante (salida)
- `x0`:
  Campo inicial (entrada)
- `diff`:
  Coeficiente de difusión
- `dt`:
  Paso de tiempo

**Proceso**:
1. Calcula `a = dt * diff * N²`
2. Aplica 20 iteraciones de Gauss-Seidel para suavizar el campo
3. Aplica condiciones de frontera después de cada iteración

### 3. `advect(N, b, d, d0, u, v, dt)`

**Propósito**:
Mover un campo (densidad o velocidad) según el campo de velocidad.

**Entradas**:
- `N`, `b`:
  Como antes
- `d`:
  Campo resultante (salida)
- `d0`:
  Campo inicial (entrada)
- `u`, `v`:
  Componentes de velocidad
- `dt`:
  Paso de tiempo

**Proceso**:
1. Para cada punto, calcula su posición previa siguiendo el flujo inverso
2. Interpola bilinealmente el valor de d0 en esa posición previa
3. Asigna ese valor interpolado a la posición actual

### 4. `project(N, u, v, p, div)`

**Propósito**:
Hacer el campo de velocidad incompresible (divergencia cero).

**Entradas**:
- `N`:
  Tamaño de la grilla
- `u`, `v`:
  Componentes de velocidad (se modifican in-place)
- `p`, `div`:
  Campos temporales para cálculos

**Proceso**:
1. Calcula divergencia del campo de velocidad (almacena en `div`) 2.
   Inicializa `p` a cero 3.
   Resuelve la ecuación de Poisson para presión con 20 iteraciones de Gauss-Seidel 4.
   Ajusta las velocidades para eliminar la divergencia

### 5. `vel_step(N, u, v, u0, v0, visc, dt)`

**Propósito**:
Paso completo para actualizar el campo de velocidad.

**Entradas**:
- `u`, `v`:
  Velocidades actuales (salida)
- `u0`, `v0`:
  Fuentes de velocidad (entrada) y almacenamiento temporal
- `visc`:
  Viscosidad
- `dt`:
  Paso de tiempo

**Pasos**:
1. Añadir fuentes (add_source)
2. Difundir velocidad (diffuse)
3. Proyectar para hacer incompresible (project)
4. Advectar velocidad (advect) 5.
   Proyectar nuevamente

### 6. `dens_step(N, x, x0, u, v, diff, dt)`

**Propósito**:
Paso completo para actualizar el campo de densidad.

**Entradas**:
- `x`:
  Densidad actual (salida)
- `x0`:
  Fuentes de densidad (entrada) y almacenamiento temporal
- `u`, `v`:
  Campo de velocidad
- `diff`:
  Coeficiente de difusión
- `dt`:
  Paso de tiempo

**Pasos**:
1. Añadir fuentes (add_source)
2. Difundir densidad (diffuse)
3. Advectar densidad (advect)

## Bucle Principal (Pseudocódigo abstracto)

```
mientras simulando:
# Obtener interacción del usuario
dens_prev, u_prev, v_prev ← get_from_UI()

# Actualizar física
vel_step(N, u, v, u_prev, v_prev, visc, dt)
dens_step(N, dens, dens_prev, u, v, diff, dt)

# Visualización
draw_dens(N, dens) 
```

## Tipos Necesarios

Como tu lenguaje no soporta genéricos, necesitarás versiones específicas para:

1. **Campos escalares** (densidad, presión, divergencia):
    - Array 2D de números flotantes
    - Funciones que operan sobre ellos:
      set_bnd_scalar, diffuse_scalar, advect_scalar

2. **Campos vectoriales** (velocidad):
    - Dos arrays 2D (uno para componente u, otro para v)
    - Funciones específicas:
      set_bnd_velocity, diffuse_velocity, project

## Consejos para Implementación

1. **Estructura de datos**:
   Usa arrays 2D para cada campo (densidad, u, v, etc.)
2. **Indexación**:
   Implementa una función IX(i,j) que convierta coordenadas 2D a índice lineal
3. **Condiciones de frontera**:
   Implementa versiones separadas para densidad y velocidad
4. **Interpolación**:
   La advección requiere interpolación bilineal precisa
