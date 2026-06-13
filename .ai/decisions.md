# Decisiones arquitectónicas

## B3 — Victoria/Derrota
- **Decisión:** La pantalla de game over se implementa como `CanvasLayer` dentro de `game.tscn`,
  no como escena independiente cargada dinámicamente. Motivo: simplicidad y coherencia con
  `top_ui.tscn` que ya vive como hijo de game.tscn.
- **Condición de victoria:** placeholder de puntaje (5000) que será reemplazado por M1.
- **Reinicio:** función `restart_game()` en `grid.gd` que limpia el array y respawnea piezas.
- **Contador de movimientos:** se descuenta en `swap_pieces()` solo cuando es un intercambio
  inicial (no en swap_back), para evitar doble descuento en jugadas inválidas.

## B4 — Sonidos
- **Decisión:** Los AudioStreamPlayer se agregan como hijos del nodo `grid` para mantener
  el audio vinculado a la lógica del tablero. No se crea un gestor de audio separado todavía.
- **Asignación de sonidos:** 1.ogg → swap, 3.ogg → match, 4.ogg → invalid.
- **Swap sound:** se reproduce en `swap_pieces()` solo en el intercambio inicial.
- **Match sound:** se reproduce en `destroy_matched()` solo si hubo combinación.
- **Invalid sound:** se reproduce en `swap_back()` antes de restaurar estado.

## B5 — Limpieza
- **Decisión:** No refactorizar código existente de B1/B2, solo asegurar que las adiciones
  no introduzcan errores. El flag `move_checked` se usa para distinguir intercambio inicial
  de swap_back.

## Convenciones de código (generales)
- Las señales `score_changed`, `counter_changed` y `game_finished` se declaran en `grid.gd`
- El HUD (`top_ui.gd`) se conecta a estas señales en `_ready()` vía `get_parent().get_node("grid")`
- Estado del juego: `WAIT` (procesando) / `MOVE` (esperando input)
