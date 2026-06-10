class_name LevelConfig
extends Resource

# TODO (PARCIAL · M1/M4): punto de partida para niveles dirigidos por datos.
# Crea un archivo .tres por nivel (en el Inspector: New Resource → LevelConfig) y
# carga la lista de niveles desde grid.gd. Puedes añadir, quitar o renombrar campos
# según el diseño de tus objetivos; esto es solo una sugerencia de estructura.

enum Objetivo { PUNTAJE, RECOLECTAR_COLOR }

@export var nombre: String = "Nivel 1"
@export var objetivo_tipo: Objetivo = Objetivo.PUNTAJE
@export var objetivo_valor: int = 1000            # puntaje meta, o cantidad a recolectar
@export var objetivo_color: String = "blue"       # solo si objetivo_tipo == RECOLECTAR_COLOR
@export var limite_movimientos: int = 20          # 0 = sin límite de movimientos
@export var limite_segundos: int = 0              # 0 = sin límite de tiempo
@export var colores_disponibles: Array[String] = [
	"blue", "green", "light_green", "pink", "yellow", "orange",
]
