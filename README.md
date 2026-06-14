# Segundo Parcial — Match-3 (Infografía, I/2026)

## NOMBRES: YERY GALLARDO Y DIANA GANDARILLAS

Proyecto **Match-3** hecho en **Godot 4.6** para el segundo parcial de Infografía.

## Cómo correr el juego

1. Instala [Godot 4.6](https://godotengine.org/download).
2. Abre esta carpeta desde el editor de Godot (botón *Import* → selecciona el `project.godot`).
3. Presiona `F5` (o el botón *Play* ▶). La escena principal es `scenes/game.tscn`.

El juego arranca en el nivel 1. Intercambiá piezas deslizando el mouse para formar
combinaciones de 3 o más del mismo color. Llegá al puntaje objetivo antes de que se
acaben los movimientos para avanzar al siguiente nivel.

## Mecánicas implementadas

### Base (B1–B5)
- **B1** — Puntaje + HUD: cada combinación suma puntos, las etiquetas se actualizan en vivo.
- **B2** — Límite de movimientos + contador visible en pantalla.
- **B3** — Pantalla de victoria/derrota con overlay, puntaje final y botón "Jugar de nuevo".
- **B4** — Efectos de sonido para intercambio, combinación y jugada inválida.
- **B5** — Sin errores en consola, bucle base funcional.

### Mecánicas obligatorias (M1–M4)
- **M1 — Sistema de niveles:** 3 niveles con distinta meta de puntaje y límite de
  movimientos, cargados desde archivos `.tres`. Al completar un nivel se avanza al
  siguiente. El HUD muestra el progreso y el objetivo.
- **M2 — Detección de bloqueo + rebarajado:** si no quedan jugadas válidas, el tablero
  se rebaraja automáticamente sin intervención del jugador.
- **M3 — Piezas especiales + combos:**
  - 4 en línea → pieza **ROW** (horizontal) o **COLUMN** (vertical). Al activarse
    limpia toda la fila o columna.
  - 5 en línea → pieza **RAINBOW** (bomba de color). Al activarse elimina todas las
    piezas de ese color.
  - Se activan al intercambiar la especial con una pieza normal.
  - Combos especial+especial: ROW+COLUMN (cruz), RAINBOW+RAINBOW (todo el tablero),
    RAINBOW+ROW/COLUMN/ADJACENT, etc.
- **M4 — Persistencia:** guarda el nivel alcanzado y el mejor puntaje en
  `user://save.json`. Al reabrir el juego se retoma desde el último nivel desbloqueado.la
  ubicacion de ese archivo se muestra en la consola al igual que la informacion que guarda
  EJEMPLO: "C:/Users/User/AppData/Roaming/Godot/app_userdata/match3/save.json
Nivel cargado:1.0
Best score:530.0
"

## Estructura del proyecto

```
scenes/          escenas: game.tscn (principal), piece.tscn y las piezas de color
scripts/
  grid.gd         lógica del tablero (intercambio, match, destruir, colapsar, rellenar)
  piece.gd        pieza individual (color, animación, especiales)
  top_ui.gd       HUD: puntaje, contador y objetivo
  game_over.gd    pantalla de fin de partida
  level_config.gd recurso para definir niveles data-driven
levels/          archivos .tres con la configuración de cada nivel
assets/          sprites de piezas (incluye especiales), fuente, fondo y sonidos
```
