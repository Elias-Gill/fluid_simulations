Aqui yacen todas las notas que fui tomando a lo largo de la investigacion para implementar el
simulador de fluidos propuesto por Jos Stam en su paper "Real-Time Fluid Dynamics for Games".

Cabe resaltar de que mi objetivo con este proyecto no era el de comprender a fondo las
matematicas por debajo del metodo presentado por el paper, si no el de explorar el mundo de
simulacioin de fluidos, recordar y practicar algunos conceptos matematicos que estudie en la
universidad, asi como comprender su uso en aplicaciones reales.

Tambien veo este desafio como una oportunidad para probar mis habilidades como desarrollador,
implementando una representacion grafica de la simulacion de manera autonoma, evitando en lo
posible utilizar tutoriales o codigo fuente de otros desarrolladores.

# Simulacion de fluidos

- [Video explicativo de como funciona la simulacion](https://www.youtube.com/watch?v=qsYE1wMEMPA)

El metodo que nos propone Jos Stam se basa en representar la superficie del fluido como dos
campos vectoriales:
el campo de velocidades y el campo de densidades.

Para representar estas campos del fluido se utilizan dos mallas, donde cada selda de la grilla
corresponde a un punto del campo vectorial.

NOTA:
para representar dichas mallas se puede utilizar una matriz, o se puede utilizar un vector.
La ventaja del vector es que el liquido nunca saldra de los limites del vector, ademas de ser
un poco mas eficiente en terminos computacionales.

La implementacion del algoritmo se divide en tres pasos escenciales:

### El Calculo de la difusion del liquido:

> "Through diffusion each cell exchanges density with its direct neighbors"

Este paso implica calcular la distribucion de las densidades en la malla de densidades.
La densidad de una celda especifica en el instante en el tiempo es igual al promedio entre las
densidades de sus vecinos.

Esto se realiza sumando a la celda actual el producto de un factor de densidad por, las
densidades de las celdas vecinas (aportan densidad) menos 4 veces el valor de la celda actual
(se cede densidad).

Pero esta implementacion no podria realizarse de manera directa, ya que dicha sistema de
ecuaciones es un sistema inestable, lo que significa que para factores de tiempo grande los
resultados creceran de manera descontrolada.

El acercamiento de Jos Stam para resolver este problema es calcular la solucion del sistema de
ecuaciones de forma inversa, es decir, hallar los valores para los cuales al "difuminar" hacia
atras nos den como resultado los valores iniciales.

Este nuevo sistema lineal (en pseudo-codigo) nos queda asi:

```txt
x0[i, j] = x[i, j] - f_dif * ( x[i-1, j] + x[i+1, j] + x[i, j-1] + x[i, j+1] - 4 * x[i, j] )

Donde "x0" es la matriz "actual" y "x" es el estado que queremos calcular, el cual representa
el estado que difuminado inversamente nos da como resultado el estado actual.

"f_dif" es el factor de difusion. No confundir con el valor del "coeficiente" de difusion del
liquido.
```

Para poder hallar las soluciones de este sistema de ecuaciones lineales con valores
desconocidos, Jos Stam utiliza el metodo de aproximacion de Gauss-Seidel, el cual es una
alternativa computacionalmente simple y eficiente para resolver dicho sistema.

La implementacion del metodo de Gauss-Seidel en pseudo-codigo nos quedaria de la siguiente
forma:

```txt
f_dif = dt * c_dif * ancho * largo; // dimensiones de la matriz de densidades

from k=1 to k=20 {  // iteraciones de Gauss-Seidel. Mas iteraciones, mas exacto.
    from i=1 to i=ancho { 
        from j=1 to j=largo { 
            x[i,j] = ( x0[i,j] + f_dif * (x[i-1, j] + x[i+1, j] + 
                        x[i, j-1] + x[i, j+1]) ) / (1 + 4 * f_dif); 
        } 
    } 

    // Aqui se puede anadir una funcion que agregue bordes y elementos solidos dentro de la
    // simulacion. Jos Stam no nos da informacion de como implementar dicha funcion, quedando 
    // a criterio del implementador.
    set_bnd ( N, b, x ); 
} 

// Donde "x0" es la matriz resultado y "x" es la matrtiz actual.
// "c_diff" es el coeficiente de difusion del liquido.
// "dt" es el tiempo transcurrido.
// Esto por la forma en la que trabaja el metodo de Gauss-Seidel.
```

### El Calculo de la adveccion del liquido:

> "The advection step moves the density through a static velocity field"

El calculo de la adveccion implica el calculo del movimiento de las densidades dentro del
fluido causado por las fuerzas aplicadas.

Supongamos que una celda del fluido sufre una aceleracion, esto resultara en un movimiento de
las densidades de dicha celda hacia otra posicion en el fluido.

El problema es que el vector que representa el movimiento de esas densidades casi nunca apunta
desde el centro de una celda al centro de otra celda.
En cambio, al realizar el moviemiento de las densidades afectaremos a un conjunto de celdas,
afectando a cada celda de manera distinta.

EL calculo de la adveccion resultaria casi trivial si contaramos con un conjunto de particulas,
pero esto conlleva su propio desafio, el cual es calcular la densidad que se translada a cada
celda segun las particulas que caigan en la misma, lo cual requiere tener registro de
particulas dentro del liquido, ademas de el calculo extra para calcular la densidad de la
celda.

Para sobreponernos ante dicho problema, Jos Stam propone reutilizar la estrategia para el
calculo de la difusion de densidades.
En vez de movernos hacia adelante en el tiempo, calculando el lugar desde donde la nueva
densidad llegaria si es que esta cayese en el centro de la celda.

Para poder ver de que celda se viene se utiliza la tecnica de interpolacion bilineal.
La interpolacion bilineal utilza los vecinos del punto.

Asi en pseudo-codigo tendriamos:
```
dt0 = dt * ancho * largo;

from i=1 to j=ancho {
    from j=1 to j=largo {
        // Calcular las posiciones ajustadas por velocidad
        x = i - dt0 * velocidades[i, j].horizontal;
        y = j - dt0 * velocidades[i, j].vertical;

        // Ajustar valores de "x" e "y" a los límites del dominio
        if (x < 0.5) 
            x = 0.5;
        if (x > N + 0.5) 
            x = N + 0.5;
        lower_x = (int)x;
        upper_x = lower_x + 1;

        if (y < 0.5) 
            y = 0.5;
        if (y > N + 0.5) 
            y = N + 0.5;
        lower_y = (int)y;
        upper_y = lower_y + 1;

        // Calcular los pesos de interpolación
        weight_x1 = x - lower_x;   // Peso para la celda superior en x
        weight_x0 = 1 - weight_x1; // Peso para la celda inferior en x
        weight_y1 = y - lower_y;   // Peso para la celda superior en y
        weight_y0 = 1 - weight_y1; // Peso para la celda inferior en y

        // Interpolación bilineal
        densidades[(i, j)] =
            weight_x0 * (weight_y0 * densidades_x0[lower_x, lower_y] + weight_y1 * densidades_x0[lower_x, upper_y]) +
            weight_x1 * (weight_y0 * densidades_x0[upper_x, lower_y] + weight_y1 * densidades_x0[upper_x, upper_y]);
    }
}

// Aplicar condiciones de frontera
set_bnd(N, b, d);
```
