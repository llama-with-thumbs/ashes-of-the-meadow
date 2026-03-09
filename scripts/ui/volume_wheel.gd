extends Control

## Retro Walkman-style volume wheel — ridged knob in a recessed slot

@export var value: float = 0.8
var dragging: bool = false
var hover: bool = false

# Layout
var slot_rect: Rect2
var knob_size: Vector2

func _ready() -> void:
	custom_minimum_size = Vector2(60, 180)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_volume()

func _apply_volume() -> void:
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, value <= 0.01)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and slot_rect.grow(8).has_point(event.position):
				dragging = true
				_update_from_mouse(event.position.y)
			else:
				dragging = false
		# Scroll wheel on the control
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			value = clampf(value + 0.05, 0.0, 1.0)
			_apply_volume()
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			value = clampf(value - 0.05, 0.0, 1.0)
			_apply_volume()
			queue_redraw()
	elif event is InputEventMouseMotion:
		hover = slot_rect.grow(8).has_point(event.position)
		if dragging:
			_update_from_mouse(event.position.y)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# + / - keys to adjust volume from anywhere
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:  # +
			value = clampf(value + 0.05, 0.0, 1.0)
			_apply_volume()
			queue_redraw()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:  # -
			value = clampf(value - 0.05, 0.0, 1.0)
			_apply_volume()
			queue_redraw()

func _update_from_mouse(mouse_y: float) -> void:
	var slot_top := slot_rect.position.y
	var slot_bot := slot_rect.position.y + slot_rect.size.y
	# Invert: top = max, bottom = min
	var t := 1.0 - clampf((mouse_y - slot_top) / (slot_bot - slot_top), 0.0, 1.0)
	value = t
	_apply_volume()
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	# ── SILVER FACEPLATE BACKGROUND ──
	var plate_rect := Rect2(0, 0, w, h)
	draw_rect(plate_rect, Color(0.76, 0.75, 0.73))
	# Subtle bevel — lighter top edge, darker bottom
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.84, 0.83, 0.81), 1.0)
	draw_line(Vector2(0, h - 1), Vector2(w, h - 1), Color(0.62, 0.61, 0.6), 1.0)
	draw_line(Vector2(0, 0), Vector2(0, h), Color(0.82, 0.81, 0.79), 1.0)
	draw_line(Vector2(w - 1, 0), Vector2(w - 1, h), Color(0.65, 0.64, 0.63), 1.0)

	# ── "VOL" LABEL ──
	var font := ThemeDB.fallback_font
	var font_size := 11
	draw_string(font, Vector2(6, h - 8), "VOL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.25, 0.25, 0.25))

	# ── RECESSED SLOT ──
	var slot_left := 16.0
	var slot_width := 18.0
	var slot_top := 28.0
	var slot_bottom := h - 30.0
	slot_rect = Rect2(slot_left, slot_top, slot_width, slot_bottom - slot_top)

	# Slot shadow/recess
	draw_rect(Rect2(slot_left - 2, slot_top - 2, slot_width + 4, slot_bottom - slot_top + 4), Color(0.45, 0.44, 0.43))
	# Slot interior — dark
	draw_rect(slot_rect, Color(0.2, 0.2, 0.22))
	# Slot inner shadow top
	draw_line(Vector2(slot_left, slot_top), Vector2(slot_left + slot_width, slot_top), Color(0.12, 0.12, 0.14), 1.0)

	# ── NUMBER MARKINGS along right side ──
	var steps := 8
	for i in steps + 1:
		var t := float(i) / float(steps)
		var y_pos := slot_top + t * (slot_bottom - slot_top)
		var num := steps - i  # 8 at top, 0 at bottom
		# Tick line
		draw_line(Vector2(slot_left + slot_width + 4, y_pos), Vector2(slot_left + slot_width + 9, y_pos), Color(0.35, 0.35, 0.35), 1.0)
		# Number
		if num % 2 == 0:
			draw_string(font, Vector2(slot_left + slot_width + 11, y_pos + 4), str(num), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.35, 0.35, 0.35))

	# ── RIDGED KNOB ──
	var knob_h := 20.0
	var knob_w := slot_width + 4
	# Knob Y position based on value (inverted: top = max)
	var knob_travel := slot_bottom - slot_top - knob_h
	var knob_y := slot_top + (1.0 - value) * knob_travel
	var knob_x := slot_left - 2

	knob_size = Vector2(knob_w, knob_h)

	# Knob body — metallic silver
	var knob_rect := Rect2(knob_x, knob_y, knob_w, knob_h)
	draw_rect(knob_rect, Color(0.72, 0.71, 0.7))
	# Knob highlight top
	draw_line(Vector2(knob_x, knob_y), Vector2(knob_x + knob_w, knob_y), Color(0.85, 0.84, 0.83), 1.0)
	# Knob shadow bottom
	draw_line(Vector2(knob_x, knob_y + knob_h), Vector2(knob_x + knob_w, knob_y + knob_h), Color(0.55, 0.54, 0.53), 1.0)

	# Ridges on knob — horizontal grooves
	var ridge_count := 7
	for i in ridge_count:
		var ry := knob_y + 3 + i * (knob_h - 6) / float(ridge_count - 1)
		# Dark groove
		draw_line(Vector2(knob_x + 2, ry), Vector2(knob_x + knob_w - 2, ry), Color(0.55, 0.54, 0.53, 0.6), 1.0)
		# Light edge below groove
		draw_line(Vector2(knob_x + 2, ry + 1), Vector2(knob_x + knob_w - 2, ry + 1), Color(0.82, 0.81, 0.8, 0.4), 1.0)

	# ── PLAY ARROW below slot (decorative) ──
	var arrow_y := h - 22.0
	var arrow_x := 10.0
	# Simple triangle
	var arrow_points := PackedVector2Array([
		Vector2(arrow_x, arrow_y - 4),
		Vector2(arrow_x, arrow_y + 4),
		Vector2(arrow_x + 7, arrow_y),
	])
	draw_colored_polygon(arrow_points, Color(0.2, 0.2, 0.22))
