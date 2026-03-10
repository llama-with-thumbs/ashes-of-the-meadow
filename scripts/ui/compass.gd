extends Control

## Compass UI widget — "N" always points toward the HomeBase

@export var radius: float = 40.0

var _player: Node2D
var _home_base: Node2D

# Colors matching the reference compass
var bg_color := Color(0.08, 0.08, 0.08, 0.85)
var ring_color := Color(0.25, 0.25, 0.25, 1.0)
var tick_color := Color(0.85, 0.85, 0.85, 1.0)
var cardinal_color := Color(0.2, 0.9, 0.3, 1.0)  # Green like the reference
var north_color := Color(0.2, 0.9, 0.3, 1.0)
var center_color := Color(0.6, 0.6, 0.6, 1.0)

func _ready() -> void:
	add_to_group("compass_ui")
	visible = false
	_player = get_tree().get_first_node_in_group("player")
	_home_base = get_node_or_null("/root/DemoWorld/HomeBase")

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _home_base == null:
		_home_base = get_node_or_null("/root/DemoWorld/HomeBase")
	queue_redraw()

func _draw() -> void:
	var center := Vector2(radius + 10.0, radius + 10.0)

	# Angle from player to home base (0 = right, rotating CCW)
	var angle_to_base := 0.0
	if _player and _home_base:
		var dir := _home_base.global_position - _player.global_position
		angle_to_base = dir.angle()  # radians, 0=right, PI/2=down in Godot

	# The compass rotates so that "N" (up on the dial) points toward the base.
	# We want "up" (-PI/2 in screen coords) to align with angle_to_base.
	# So rotation offset = angle_to_base + PI/2 (because "N" is drawn at -PI/2)
	var rot := angle_to_base + PI / 2.0

	# Background circle
	draw_circle(center, radius + 4.0, ring_color)
	draw_circle(center, radius, bg_color)

	# Tick marks — 36 small, 8 medium, 4 large (cardinal)
	for i in 36:
		var tick_angle: float = rot + float(i) * TAU / 36.0
		var is_cardinal: bool = (i % 9 == 0)
		var is_intercardinal: bool = (i % 9 == 4 or i % 9 == 5)  # rough
		is_intercardinal = (i % 9 != 0 and i % 4 == 0)  # every 4th that isn't cardinal

		var inner: float
		var width: float
		var color: Color
		if is_cardinal:
			inner = radius - 12.0
			width = 2.5
			color = tick_color
		elif i % 4 == 0:  # intercardinal (every 4th = every 40 degrees... use every 9/2)
			inner = radius - 8.0
			width = 1.5
			color = Color(tick_color, 0.7)
		else:
			inner = radius - 5.0
			width = 1.0
			color = Color(tick_color, 0.4)

		var dir := Vector2.from_angle(tick_angle - PI / 2.0)
		var p1 := center + dir * inner
		var p2 := center + dir * (radius - 2.0)
		draw_line(p1, p2, color, width)

	# Cardinal labels: N, E, S, W
	var labels := ["N", "E", "S", "W"]
	var label_font := ThemeDB.fallback_font
	var font_size := 14
	for i in 4:
		var label_angle: float = rot + float(i) * TAU / 4.0
		var dir := Vector2.from_angle(label_angle - PI / 2.0)
		var pos := center + dir * (radius - 22.0)

		var col: Color
		if i == 0:
			col = north_color  # N is bright green
		else:
			col = cardinal_color

		# Larger font for N
		var fs: int = 16 if i == 0 else font_size
		var text_size := label_font.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(label_font, pos - text_size / 2.0 + Vector2(0, text_size.y * 0.35), labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)

	# North arrow — triangle pointing outward from center toward N
	var n_dir := Vector2.from_angle(rot - PI / 2.0)
	var arrow_tip := center + n_dir * (radius - 2.0)
	var arrow_base_l := center + n_dir * (radius - 14.0) + n_dir.rotated(PI / 2.0) * 4.0
	var arrow_base_r := center + n_dir * (radius - 14.0) - n_dir.rotated(PI / 2.0) * 4.0
	draw_colored_polygon([arrow_tip, arrow_base_l, arrow_base_r], north_color)

	# Center pin
	draw_circle(center, 4.0, center_color)
	draw_circle(center, 2.5, Color(0.4, 0.4, 0.4, 1.0))
