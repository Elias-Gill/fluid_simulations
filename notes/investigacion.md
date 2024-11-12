# Usefull Links: 

- [Lattice Boltzman Methods](https://www.youtube.com/watch?v=JKQ0XdjLo7M)
- [Demo - Lattice Boltzman](https://www.youtube.com/watch?v=GiIEEe9rSqA)
- [Eulerian vs Lagrangian methods](https://quangduong.me/notes/eulerian_fluid_sim_p1/)

# Conceptos fisicos

## Metodos numericos de aproximacion

### Metodo de Gauss-Seidel

Este metodo nos permite realizar aproximaciones numericas a las soluciones de un sistema de
ecuaciones lineales de manera iterativa.
Este metodo es tremendamente poderoso para aplicaciones computacionales.

El metodo requiere de que el sistema de ecuaciones lineales (ecuaciones con exponente 1)
primeramente sea estrictamente diagonal, es decir, que los valores de la diagonal principal
sean los mayores tanto de su fila como de su columna.

Luego se despejan las variables de manera a contar con las ecuaciones que describen a la
variable.

Posteriormente se realizan la resolucion de cada una de las ecuaciones, utilizando los valores
ya encontrados con cada ecuacion, es decir:

```txt
x = y + z + 1
y = x - z
z = x + y

En la primera iteracion los valores de (x,y,z) son (0,0,0):

x = 0 + 0 + 1 = 1

Ahora para resolver "y" ya utilizamos el valor de "x" que recien calculamos:

y = 1 - 0 = 1

Ahora para "z" utilizamos los valores de "x" e "y" recien calculados:

z = 1 + 1

Terminando la primera iteracion con (x,y,z) = (1,1,1). Continuamos del mismo
modo para el resto de iteraciones necesarias. 
```

Cuantas mas iteraciones se realicen mas se aproximaran los valores a las soluciones reales del
sistema de ecuaciones propuesto.

## Conceptos fisicos

### Adveccion

La advección es el proceso de transporte de una propiedad o sustancia por el movimiento de un
fluido.

A fines de la simulacion, la adveccion debe ser calculada dado que los liquidos transportan
masa en su movimiento.

En terminos matematicos se define como el cambio de una magnitud escalar dada por el cambio
dentro de un campo vectorial.

## Vectores y Campos vectoriales

### Campos Vectoriales

#### Gradiente

El vector gradiente en un punto de un campo vectorial representa la fuerza y la direccion de
variacion del campo en ese punto especifico.

El gradiente es una generalizacion de la derivada aplicada a funciones multi-variable, donde se
calcula como el vector resultante de las derivadas parciales de los componentes de la funcion:
`gradiente(F(x)) = (derivada parcial de X1; .... ;derivada parcial de Xn)`

#### Divergencia:

La divergencia de un punto de un espacio vectorial nos dice cuanto fluido tiende a fluir hacia
fuera o hacia el punto.
O en otras palabras, nos dice que tanto un campo tiende a expandirse o a contraerse en un punto
dado.

Cuando la divergencia es positiva el fluido tiende a fluir "lejos" del fluido, cuando es
negativa tiene a fluir "hacia" el punto.
Que la divergencia sea positiva tambien puede significar que el fluido que el fluido que entra
es mas rapido que el fluido que sale de ese punto.

La divergencia es una funcion que recibe los valores (x, y) de un punto y retorna un valor que
simboliza cuanto un punto actua como un "agujero" o como una "fuente" en el campo vectorial.

Para un fluido incompresible la divergencia debe de ser siempre 0 en todos los puntos.

#### Rizos (curls)

Parecido a la divergencia, pero representa que tanto tiende un punto de un fluido a rotar y
formar remolinos.

Su signo representa si el giro es horario (positivo) o antihorario (negativo); su magnitud
representa que tan fuertemente el fluido tendera a girar alrededor del punto.

Un punto que se encontrara en medio de dos flujos con distinta velocidad tendra un nivel de
"curling" NO negativo, esto ya que la influencia de esta diferencia de velocidades tiende a
generar un movimiento de rotacion:

```txt
fast flow   -----> ------> ------> ------>
            ----> -----> -----> ----->
                    (punto)
slow flow   --> --> --> --> --> --> --> -->
            -> -> -> -> -> -> -> ->
```

