extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# === Temporizadores del ciclo destruir → colapsar → rellenar ===
@onready var destroy_timer: Timer = $destroy_timer
@onready var collapse_timer: Timer = $collapse_timer
@onready var refill_timer: Timer = $refill_timer

# === Puntaje y contador (B1/B2) ===
signal score_changed(nuevo_puntaje: int)
signal counter_changed(restantes: int)
signal game_finished(gano: bool)

var score = 0
var moves_remaining = 30
var target_score = 5000

# === Sonidos (B4) ===
@onready var sfx_swap: AudioStreamPlayer = $sfx_swap
@onready var sfx_match: AudioStreamPlayer = $sfx_match
@onready var sfx_invalid: AudioStreamPlayer = $sfx_invalid

func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	emit_signal("counter_changed", moves_remaining)
	emit_signal("score_changed", score)
	sfx_swap.stream = load("res://assets/sounds/1.ogg")
	sfx_match.stream = load("res://assets/sounds/3.ogg")
	sfx_invalid.stream = load("res://assets/sounds/4.ogg")

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		moves_remaining -= 1
		emit_signal("counter_changed", moves_remaining)
		sfx_swap.play()
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	sfx_invalid.play()
	if moves_remaining <= 0:
		game_over(false)
	elif score >= target_score:
		game_over(true)
	else:
		state = MOVE
		move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func find_matches():
	# TODO (PARCIAL · M3): aquí es donde se decide qué piezas forman cada combinación.
	# Para crear piezas especiales necesitas conocer el LARGO de cada línea: una de 4
	# genera una pieza de línea (fila/columna) y una de 5 una bomba de color. El chequeo
	# actual solo mira el "centro" de tríos; probablemente tengas que recorrer las
	# líneas completas para distinguir combinaciones de 3, 4 y 5.
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
				# detect vertical matches
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					
	destroy_timer.start()
	
func destroy_matched():
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				score += 10
				emit_signal("score_changed", score)
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	move_checked = true
	if was_matched:
		sfx_match.play()
		collapse_timer.start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	refill_timer.start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				destroy_timer.start()
				return
	if moves_remaining <= 0:
		game_over(false)
	elif score >= target_score:
		game_over(true)
	else:
		state = MOVE
		move_checked = false

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over(won: bool):
	state = WAIT
	emit_signal("game_finished", won)
	var game_over_node = get_parent().get_node("GameOver")
	if game_over_node:
		game_over_node.show_game_over(won, score)

func restart_game():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	all_pieces = make_2d_array()
	score = 0
	moves_remaining = 30
	emit_signal("score_changed", score)
	emit_signal("counter_changed", moves_remaining)
	spawn_pieces()
	state = MOVE

# TODO (PARCIAL · M2): funciones sugeridas para detectar el bloqueo del tablero.
# func hay_jugadas_validas() -> bool:
# func rebarajar() -> void:
