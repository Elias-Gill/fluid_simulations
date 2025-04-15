# **Interpolación Bilineal:

La **interpolación bilineal** es una extensión de la interpolación lineal para funciones de
**dos variables (2D)**.

Se usa comúnmente en:
- Procesamiento de imágenes (escalado, rotación)
- Simulación de fluidos (como en el código de Jos Stam)
- Texturizado 3D
- Mapeo de datos científicos

---

## **Concepto Básico**

Dados **4 puntos conocidos** que forman un cuadrado en una grilla 2D, la interpolación bilineal
estima un valor intermedio dentro de ese cuadrado mediante un promedio ponderado.

### **Fórmula General** 

Si tenemos los valores en las esquinas:
- $ Q_{11} = (x_1, y_1)$
- $ Q_{12} = (x_1, y_2)$
- $ Q_{21} = (x_2, y_1)$
- $ Q_{22} = (x_2, y_2)$

Y queremos interpolar el valor en $P = (x, y)$, el cálculo se realiza en **dos pasos**:

1. **Interpolación lineal en el eje X** (para filas superior e inferior):
   $$ y = y_1$$ $$ f(x, y_1) = \frac{x_2 - x}{x_2 - x_1} Q_{11} + \frac{x - x_1}{x_2 - x_1}
   Q_{21} $$

   $$ y = y_2 $$ $$ f(x, y_2) = \frac{x_2 - x}{x_2 - x_1} Q_{12} + \frac{x - x_1}{x_2 - x_1}
   Q_{22} $$

2. **Interpolación lineal en el eje Y** (combinando los resultados anteriores):
   $$ f(x, y) = \frac{y_2 - y}{y_2 - y_1} f(x, y_1) + \frac{y - y_1}{y_2 - y_1} f(x, y_2) $$

---

## **Ejemplo Gráfico**

```
(y₂) Q₁₂ *-------------* Q₂₂
         |             |
         |      • P    |
         |   (x,y)     |
(y₁) Q₁₁ *-------------* Q₂₁
       x₁            x₂
```
- **Paso 1**:
  Se interpolan $Q_{11}$ y $Q_{21}$ para estimar $f(x, y_1)$.
- **Paso 2**:
  Se interpolan $Q_{12}$ y $Q_{22}$ para estimar $f(x, y_2)$.
- **Paso 3**:
  Se interpolan verticalmente $f(x, y_1)$ y $f(x, y_2)$ para obtener $f(x, y)$.

---

## **Aplicación en el Código de Jos Stam** En la función `advect`, se usa interpolación
   bilineal para calcular cómo se mueve la densidad (o velocidad) siguiendo el flujo del
   fluido:

```c
// Cálculo de la posición previa (backtraced) 
x = i - dt0 * u[IX(i,j)]; y = j - dt0 * v[IX(i,j)];  

// Aseguramos que no salga de los límites 
if (x < 0.5) x = 0.5; 
if (x > N+0.5) x = N+0.5; 
if (y < 0.5) y = 0.5; if (y > N+0.5) y = N+0.5;  

// Coordenadas enteras y fraccionales 
i0 = (int)x; i1 = i0 + 1; j0 = (int)y; j1 = j0 + 1; 
s1 = x - i0; s0 = 1 - s1; t1 = y - j0; t0 = 1 - t1;  

// Interpolación bilineal 
d[IX(i,j)] = s0 * (t0 * d0[IX(i0,j0)] + t1 * d0[IX(i0,j1)]) + s1 * (t0 * d0[IX(i1,j0)] + t1 * d0[IX(i1,j1)]);  
```

---

## **Resumen**

- **Interpola en 2D** usando 4 puntos vecinos.
- **Primero interpola horizontalmente**, luego verticalmente (o viceversa).
- **Muy usado en gráficos** para suavizar imágenes y en simulaciones de fluidos para advección.
- **Más preciso que la interpolación lineal simple**, pero menos costoso que métodos cúbicos.
