# Farkle — Busche & Neller (2017) reglas “mínimas”

Resumen de referencia del conjunto de reglas utilizado en *Juego óptimo del juego de dados Farkle* (ACG 2017). Los autores eligieron deliberadamente una **pequeña tabla de puntuación** (sólo **1s/5s** y **tres iguales**) sin **ninguna** escalera, tres pares, cuatro/cinco/seis iguales u otras bonificaciones combinadas. Eso lo convierte en una **implementación de referencia** útil cuando desea el núcleo Farkle común más simple sin fusiones adicionales.

**Fuente:** Matthew Busche y Todd W. Neller, “Optimal Play of the Farkle Dice Game”, en *Advances in Computer Games* (ACG 2017), LNCS 10664, Springer, 2017.
**PDF de acceso abierto (alojamiento del autor):** [cs.gettysburg.edu — acg2017.pdf](http://cs.gettysburg.edu/~tneller/papers/acg2017.pdf)
**DOI:** [10.1007/978-3-319-71649-7_6](https://doi.org/10.1007/978-3-319-71649-7_6)

## Objetivo

Sé el **primer jugador en alcanzar una puntuación acumulada de 10 000 o más** (redacción del artículo; el análisis es para **dos** jugadores, pero el juego se generaliza).

## Equipo

Seis dados estándar de seis caras; lápiz y papel (o equivalente) para las partituras.

## Estructura de giro

1. **Inicio del turno:** Tira los seis dados.
2. **Puntuación:** Identifica **combinaciones** de **esta tirada únicamente** (ver tabla). Cada dado se puede utilizar en **como máximo una** combinación. Puedes tomar **múltiples** combinaciones que no se superpongan del mismo rollo.
3. **Reservar:** Si existe alguna combinación, **debes** reservar **al menos una** combinación y puedes reservar más. Añade esos puntos a tu **total de turnos**.
4. **Elige:** Volver a tirar los dados que no estén en combinaciones, o **acumular** (suma el total del turno a la puntuación acumulada y finaliza el turno).
5. **Farkle:** Si la tirada **no** tiene una combinación legal, **obtienes 0 puntos para el turno**; la puntuación acumulada no cambia; pasar los dados.
6. **Dados calientes:** Si las combinaciones usan **los seis** dados, tira **los seis nuevamente** y continúa el mismo turno (el mismo total de turno está en riesgo hasta que hagas banca o farkle).

## Combinaciones de puntuación (lista completa en papel)

Estos son los **únicos** patrones de puntuación en esta variante:

| Combinación | Puntos |
|-------------|--------|
| Uno **1** | 100 |
| Uno **5** | 50 |
| Tres **1**s | 1.000 |
| Tres **2**s | 200 |
| Tres **3**s | 300 |
| Tres **4**s | 400 |
| Tres **5**s | 500 |
| Tres **6**s | 600 |

**No** hay puntos por una carrera de 1 a 6, tres parejas, dos tripletes o más de cuatro del mismo tipo en este conjunto de reglas.

## Nota de equidad opcional (del documento)

Para las posiciones iniciales “más justas” de **dos jugadores**, los autores **recomiendan 200 puntos de compensación** para el **segundo** jugador al inicio del juego (consulte el resumen y el cuerpo del artículo). Este es un ajuste de investigación/torneo, no forma parte de la mayoría de las hojas de reglas informales.

## Relación con otros archivos en este repositorio

Esta variante es **estrictamente más limitada** que `FARKLE_RULES.md` (Cardgames.io), `FARKLE_RULES_WIKIPEDIA_ARNOLD.md` y `FARKLE_RULES_PLAYMONSTER.md`, que agregan escaleras, múltiplos adicionales, pares, etc. Utilice Busche & Neller cuando desee una puntuación **mínima** y una libertad **máxima** para **qué** dados de puntuación conservar (el documento enfatiza que objetivo de diseño).
