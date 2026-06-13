extends Node2D

@export var color: String

enum SpecialType { NONE, ROW, COLUMN, ADJACENT, RAINBOW }

var matched = false
var special_type = SpecialType.NONE
var special_color = ""

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func is_special() -> bool:
	return special_type != SpecialType.NONE

func set_special(type: SpecialType, color_name: String):
	special_type = type
	special_color = color_name
	var path = ""
	if type == SpecialType.RAINBOW:
		path = "res://assets/pieces/Rainbow.png"
	else:
		var type_str = SpecialType.keys()[type]
		path = "res://assets/pieces/" + color_name.capitalize() + " " + type_str.capitalize() + ".png"
	$Sprite2D.texture = load(path)
