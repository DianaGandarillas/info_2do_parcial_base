extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var objective_label = $MarginContainer/HBoxContainer/HBoxContainer/objective_label

var current_score = 0
var current_count = 0

func _ready():
	var grid = get_parent().get_node("grid")
	grid.score_changed.connect(update_score)
	grid.counter_changed.connect(update_counter)
	grid.objective_changed.connect(update_objective)
	current_score = grid.score
	current_count = grid.moves_remaining
	score_label.text = str(current_score)
	counter_label.text = str(current_count)

func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	score_label.text = str(current_score)

func update_counter(restantes: int) -> void:
	current_count = restantes
	counter_label.text = str(current_count)
	
func update_objective(texto:String):
	objective_label.text = texto
