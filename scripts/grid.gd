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

const PieceClass = preload("res://scripts/piece.gd")

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

# special pieces to create after destroy
var specials_to_create = []

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

#M1
signal objective_changed(texto:String)

var score = 0
var moves_remaining = 30
var target_score = 5000

#M1
var levels = []
var current_level_index = 0
var current_level : LevelConfig

#m4
const SAVE_FILE = "user://save.json"
var best_score = 0

# === Sonidos (B4) ===
@onready var sfx_swap: AudioStreamPlayer = $sfx_swap
@onready var sfx_match: AudioStreamPlayer = $sfx_match
@onready var sfx_invalid: AudioStreamPlayer = $sfx_invalid

func _ready():
	print(ProjectSettings.globalize_path(SAVE_FILE))
	state = MOVE
	randomize()
	#M1
	load_levels()
	##load_level(0)
	#m4
	load_progress()
	load_level(current_level_index)
	
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
	var target_col = column + direction.x
	var target_row = row + direction.y
	if not in_grid(target_col, target_row):
		return
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[target_col][target_row]
	if first_piece == null or other_piece == null:
		return
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[target_col][target_row] = first_piece
	first_piece.move(grid_to_pixel(target_col, target_row))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		moves_remaining -= 1
		emit_signal("counter_changed", moves_remaining)
		sfx_swap.play()
		if piece_one.is_special() or piece_two.is_special():
			activate_special_swap()
		else:
			find_matches()
			if destroy_timer.is_stopped():
				undo_invalid_swap()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func undo_invalid_swap():
	all_pieces[last_place.x][last_place.y] = piece_one
	all_pieces[last_place.x + last_direction.x][last_place.y + last_direction.y] = piece_two
	piece_one.move(grid_to_pixel(last_place.x, last_place.y))
	piece_two.move(grid_to_pixel(last_place.x + last_direction.x, last_place.y + last_direction.y))
	sfx_invalid.play()
	if moves_remaining <= 0:
		game_over(false)
	elif score >= target_score:
		game_over(true)
	else:
		state = MOVE
		move_checked = false

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
	specials_to_create.clear()

	# Horizontal runs
	for j in height:
		var i = 0
		while i < width:
			if all_pieces[i][j] == null or all_pieces[i][j].is_special():
				i += 1
				continue
			var current_color = all_pieces[i][j].color
			var run_start = i
			var run_length = 0
			while i < width and all_pieces[i][j] != null and not all_pieces[i][j].is_special() and all_pieces[i][j].color == current_color:
				run_length += 1
				i += 1
			if run_length >= 3:
				for k in range(run_start, run_start + run_length):
					all_pieces[k][j].matched = true
					all_pieces[k][j].dim()
				if run_length == 4:
					var last = run_start + run_length - 1
					all_pieces[last][j].matched = false
					specials_to_create.append({col = last, row = j, type = PieceClass.SpecialType.ROW, color = current_color})
				elif run_length >= 5:
					var last = run_start + run_length - 1
					all_pieces[last][j].matched = false
					specials_to_create.append({col = last, row = j, type = PieceClass.SpecialType.RAINBOW, color = current_color})

	# Vertical runs
	for i in width:
		var j = 0
		while j < height:
			if all_pieces[i][j] == null or all_pieces[i][j].is_special():
				j += 1
				continue
			var current_color = all_pieces[i][j].color
			var run_start = j
			var run_length = 0
			while j < height and all_pieces[i][j] != null and not all_pieces[i][j].is_special() and all_pieces[i][j].color == current_color:
				run_length += 1
				j += 1
			if run_length >= 3:
				for k in range(run_start, run_start + run_length):
					all_pieces[i][k].matched = true
					all_pieces[i][k].dim()
				if run_length == 4:
					var last = run_start + run_length - 1
					all_pieces[i][last].matched = false
					specials_to_create.append({col = i, row = last, type = PieceClass.SpecialType.COLUMN, color = current_color})
				elif run_length >= 5:
					var last = run_start + run_length - 1
					all_pieces[i][last].matched = false
					specials_to_create.append({col = i, row = last, type = PieceClass.SpecialType.RAINBOW, color = current_color})

	if specials_to_create.size() > 0 or _has_matched():
		destroy_timer.start()

func _has_matched() -> bool:
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				return true
	return false
	
func destroy_matched():
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				score += 10
				emit_signal("score_changed", score)
				#m1
				emit_signal("objective_changed", "%d / %d puntos" % [score, target_score])
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	for spec in specials_to_create:
		var piece = all_pieces[spec.col][spec.row]
		if piece != null and not piece.is_special():
			piece.set_special(spec.type, spec.color)
			was_matched = true
	specials_to_create.clear()

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
	if score >= target_score:
		game_over(true)
	elif moves_remaining <= 0:
		game_over(false)
	else:
		if not has_valid_moves():
			reshuffle()
			find_matches()
			if _has_matched() or specials_to_create.size() > 0:
				return
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
	#m1
	if won:
		if current_level_index < levels.size() - 1:
			current_level_index += 1
		#m4
		save_progress()
	emit_signal("game_finished", won)
	var game_over_node = get_parent().get_node("GameOver")
	if game_over_node:
		game_over_node.show_game_over(won, score)

func restart_game():
	destroy_timer.stop()
	collapse_timer.stop()
	refill_timer.stop()
	specials_to_create.clear()
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	all_pieces = make_2d_array()
	piece_one = null
	piece_two = null
	last_place = Vector2.ZERO
	last_direction = Vector2.ZERO
	move_checked = false
	is_controlling = false
	first_touch = Vector2.ZERO
	final_touch = Vector2.ZERO
	score = 0
	#moves_remaining = 30
	load_level(current_level_index)
	
	emit_signal("score_changed", score)
	emit_signal("counter_changed", moves_remaining)
	spawn_pieces()
	state = MOVE

# === Activación de especiales (M3) ===

func activate_special_swap():
	if piece_one.is_special() and piece_two.is_special():
		activate_combo(piece_one, piece_two)
		return

	var spec_piece = piece_one if piece_one.is_special() else piece_two
	var norm_piece = piece_two if piece_one.is_special() else piece_one
	var spec_col = last_place.x + last_direction.x if piece_one.is_special() else last_place.x
	var spec_row = last_place.y + last_direction.y if piece_one.is_special() else last_place.y

	spec_piece.matched = true
	spec_piece.dim()
	norm_piece.matched = true
	norm_piece.dim()

	match spec_piece.special_type:
		PieceClass.SpecialType.ROW:
			mark_row(spec_row)
		PieceClass.SpecialType.COLUMN:
			mark_column(spec_col)
		PieceClass.SpecialType.RAINBOW:
			mark_color(norm_piece.color)
		PieceClass.SpecialType.ADJACENT:
			mark_adjacent(spec_col, spec_row)

	destroy_timer.start()

func activate_combo(piece_a, piece_b):
	piece_a.matched = true
	piece_a.dim()
	piece_b.matched = true
	piece_b.dim()

	var type_a = piece_a.special_type
	var type_b = piece_b.special_type
	var col_a = last_place.x + last_direction.x
	var row_a = last_place.y + last_direction.y
	var col_b = last_place.x
	var row_b = last_place.y

	if (type_a == PieceClass.SpecialType.ROW and type_b == PieceClass.SpecialType.COLUMN):
		mark_row(row_a)
		mark_column(col_b)
	elif (type_a == PieceClass.SpecialType.COLUMN and type_b == PieceClass.SpecialType.ROW):
		mark_column(col_a)
		mark_row(row_b)
	elif type_a == PieceClass.SpecialType.RAINBOW and type_b == PieceClass.SpecialType.RAINBOW:
		for i in width:
			for j in height:
				if all_pieces[i][j] != null and not all_pieces[i][j].matched:
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
	elif type_a == PieceClass.SpecialType.RAINBOW:
		mark_color(piece_b.color)
		match type_b:
			PieceClass.SpecialType.ROW: mark_row(row_b)
			PieceClass.SpecialType.COLUMN: mark_column(col_b)
			PieceClass.SpecialType.ADJACENT: mark_adjacent(col_b, row_b)
	elif type_b == PieceClass.SpecialType.RAINBOW:
		mark_color(piece_a.color)
		match type_a:
			PieceClass.SpecialType.ROW: mark_row(row_a)
			PieceClass.SpecialType.COLUMN: mark_column(col_a)
			PieceClass.SpecialType.ADJACENT: mark_adjacent(col_a, row_a)
	else:
		match type_a:
			PieceClass.SpecialType.ROW: mark_row(row_a)
			PieceClass.SpecialType.COLUMN: mark_column(col_a)
			PieceClass.SpecialType.ADJACENT: mark_adjacent(col_a, row_a)
		match type_b:
			PieceClass.SpecialType.ROW: mark_row(row_b)
			PieceClass.SpecialType.COLUMN: mark_column(col_b)
			PieceClass.SpecialType.ADJACENT: mark_adjacent(col_b, row_b)

	destroy_timer.start()

func mark_row(row):
	for i in width:
		if all_pieces[i][row] != null and not all_pieces[i][row].matched:
			all_pieces[i][row].matched = true
			all_pieces[i][row].dim()

func mark_column(col):
	for j in height:
		if all_pieces[col][j] != null and not all_pieces[col][j].matched:
			all_pieces[col][j].matched = true
			all_pieces[col][j].dim()

func mark_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].color == color and not all_pieces[i][j].matched:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()

func mark_adjacent(col, row):
	for di in range(-1, 2):
		for dj in range(-1, 2):
			var ni = col + di
			var nj = row + dj
			if in_grid(ni, nj) and all_pieces[ni][nj] != null and not all_pieces[ni][nj].matched:
				all_pieces[ni][nj].matched = true
				all_pieces[ni][nj].dim()

# === Detección de bloqueo y rebarajado (M2) ===

func has_valid_moves() -> bool:
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].is_special():
				return true
	for i in width:
		for j in height:
			if all_pieces[i][j] == null or all_pieces[i][j].is_special():
				continue
			if i + 1 < width and all_pieces[i + 1][j] != null and not all_pieces[i + 1][j].is_special():
				if swap_creates_match(i, j, i + 1, j):
					return true
			if j + 1 < height and all_pieces[i][j + 1] != null and not all_pieces[i][j + 1].is_special():
				if swap_creates_match(i, j, i, j + 1):
					return true
	return false

func swap_creates_match(c1, r1, c2, r2) -> bool:
	var temp = all_pieces[c1][r1]
	all_pieces[c1][r1] = all_pieces[c2][r2]
	all_pieces[c2][r2] = temp

	var result = check_match_at(c1, r1) or check_match_at(c2, r2)

	temp = all_pieces[c1][r1]
	all_pieces[c1][r1] = all_pieces[c2][r2]
	all_pieces[c2][r2] = temp

	return result

func check_match_at(col, row) -> bool:
	var piece = all_pieces[col][row]
	if piece == null or piece.is_special():
		return false
	var color = piece.color

	var count = 1
	var i = col - 1
	while i >= 0 and all_pieces[i][row] != null and not all_pieces[i][row].is_special() and all_pieces[i][row].color == color:
		count += 1
		i -= 1
	i = col + 1
	while i < width and all_pieces[i][row] != null and not all_pieces[i][row].is_special() and all_pieces[i][row].color == color:
		count += 1
		i += 1
	if count >= 3:
		return true

	count = 1
	var j = row - 1
	while j >= 0 and all_pieces[col][j] != null and not all_pieces[col][j].is_special() and all_pieces[col][j].color == color:
		count += 1
		j -= 1
	j = row + 1
	while j < height and all_pieces[col][j] != null and not all_pieces[col][j].is_special() and all_pieces[col][j].color == color:
		count += 1
		j += 1
	return count >= 3

func reshuffle():
	var attempts = 0
	while not has_valid_moves() and attempts < 50:
		var colors = []
		var positions = []
		for i in width:
			for j in height:
				if all_pieces[i][j] != null and not all_pieces[i][j].is_special():
					colors.append(all_pieces[i][j].color)
					positions.append({col = i, row = j})
		colors.shuffle()
		for idx in range(positions.size()):
			var p = positions[idx]
			all_pieces[p.col][p.row].color = colors[idx]
			var path = "res://assets/pieces/" + colors[idx].capitalize() + " Piece.png"
			all_pieces[p.col][p.row].get_node("Sprite2D").texture = load(path)
		attempts += 1
	if not has_valid_moves():
		var fallback_colors = ["blue", "green", "light_green", "pink", "yellow", "orange"]
		for i in width:
			for j in height:
				if all_pieces[i][j] != null and not all_pieces[i][j].is_special():
					var rand_color = fallback_colors[randi_range(0, fallback_colors.size() - 1)]
					all_pieces[i][j].color = rand_color
					var path = "res://assets/pieces/" + rand_color.capitalize() + " Piece.png"
					all_pieces[i][j].get_node("Sprite2D").texture = load(path)

#M1
func load_levels():

	levels.clear()

	levels.append(load("res://levels/level1.tres"))
	levels.append(load("res://levels/level2.tres"))
	levels.append(load("res://levels/level3.tres"))
	
	
func load_level(index:int):

	current_level_index = index

	current_level = levels[index]

	target_score = current_level.objetivo_valor

	moves_remaining = current_level.limite_movimientos

	emit_signal("counter_changed", moves_remaining)
	emit_signal("objective_changed","Meta: %d puntos" % target_score)
	
	
#M4
	
func save_progress():

	if score > best_score:
		best_score = score

	var data = {

		"level": current_level_index,

		"best_score": best_score
	}
	print("Guardando...")
	print("Nivel:", current_level_index)
	print("Best score:", best_score)

	var file = FileAccess.open(
		SAVE_FILE,
		FileAccess.WRITE
	)

	file.store_string(JSON.stringify(data))
	
	
func load_progress():

	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(
		SAVE_FILE,
		FileAccess.READ
	)

	var data = JSON.parse_string(
		file.get_as_text()
	)

	if data == null:
		return

	current_level_index = data["level"]

	best_score = data["best_score"]
	print("Nivel cargado:", current_level_index)
	print("Best score:", best_score)
