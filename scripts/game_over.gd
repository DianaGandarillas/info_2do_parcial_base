extends CanvasLayer

@onready var title_label = $Overlay/VBoxContainer/TitleLabel
@onready var score_label = $Overlay/VBoxContainer/ScoreLabel
@onready var restart_button = $Overlay/VBoxContainer/RestartButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)

func show_game_over(won: bool, score: int):
	title_label.text = "¡Victoria!" if won else "Game Over"
	score_label.text = "Puntaje: " + str(score)
	visible = true

func hide_game_over():
	visible = false

func _on_restart_pressed():
	var grid = get_parent().get_node("grid")
	if grid:
		grid.restart_game()
	hide_game_over()
