extends Control

## Slider to control asteroid density — changes take effect on release

signal density_changed(count: int)

@export var value: float = 0.5  # 0.0 = few, 1.0 = many
var dragging: bool = false
var slot_rect: Rect2

func _ready() -> void:
	custom_minimum_size = Vector2(60, 140)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Initialize slot_rect so input works before first draw
	slot_rect = Rect2(16.0, 22.0, 18.0, size.y - 46.0)

func get_count() -> int:
	# Map 0..1 to 10..80 asteroids
	return int(lerp(10.0, 80.0, value))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				_update_from_mouse(event.position.y)
			else:
				dragging = false
				density_changed.emit(get_count())
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			value = clampf(value + 0.1, 0.0, 1.0)
			queue_redraw()
			density_changed.emit(get_count())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			value = clampf(value - 0.1, 0.0, 1.0)
			queue_redraw()
			density_changed.emit(get_count())
	elif event is InputEventMouseMotion:
		if dragging:
			_update_from_mouse(event.position.y)
		queue_redraw()

func _update_from_mouse(mouse_y: float) -> void:
	var slot_top := slot_rect.position.y
	var slot_bot := slot_rect.position.y + slot_rect.size.y
	value = 1.0 - clampf((mouse_y - slot_top) / (slot_bot - slot_top), 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	# Faceplate
	draw_rect(Rect2(0, 0, w, h), Color(0.76, 0.75, 0.73))
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.84, 0.83, 0.81), 1.0)
	draw_line(Vector2(0, h - 1), Vector2(w, h - 1), Color(0.62, 0.61, 0.6), 1.0)
	draw_line(Vector2(0, 0), Vector2(0, h), Color(0.82, 0.81, 0.79), 1.0)
	draw_line(Vector2(w - 1, 0), Vector2(w - 1, h), Color(0.65, 0.64, 0.63), 1.0)

	# Label
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(4, h - 6), "ROCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.25))

	# Slot
	var slot_left := 16.0
	var slot_width := 18.0
	var slot_top := 22.0
	var slot_bottom := h - 24.0
	slot_rect = Rect2(slot_left, slot_top, slot_width, slot_bottom - slot_top)

	draw_rect(Rect2(slot_left - 2, slot_top - 2, slot_width + 4, slot_bottom - slot_top + 4), Color(0.45, 0.44, 0.43))
	draw_rect(slot_rect, Color(0.2, 0.2, 0.22))
	draw_line(Vector2(slot_left, slot_top), Vector2(slot_left + slot_width, slot_top), Color(0.12, 0.12, 0.14), 1.0)

	# Tick marks
	var labels := ["FEW", "", "MID", "", "MAX"]
	for i in 5:
		var t := float(i) / 4.0
		var y_pos := slot_top + (1.0 - t) * (slot_bottom - slot_top)
		draw_line(Vector2(slot_left + slot_width + 4, y_pos), Vector2(slot_left + slot_width + 9, y_pos), Color(0.35, 0.35, 0.35), 1.0)
		if labels[i] != "":
			draw_string(font, Vector2(slot_left + slot_width + 10, y_pos + 3), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.35, 0.35, 0.35))

	# Knob
	var knob_h := 16.0
	var knob_w := slot_width + 4
	var knob_travel := slot_bottom - slot_top - knob_h
	var knob_y := slot_top + (1.0 - value) * knob_travel
	var knob_x := slot_left - 2

	var knob_rect := Rect2(knob_x, knob_y, knob_w, knob_h)
	draw_rect(knob_rect, Color(0.72, 0.71, 0.7))
	draw_line(Vector2(knob_x, knob_y), Vector2(knob_x + knob_w, knob_y), Color(0.85, 0.84, 0.83), 1.0)
	draw_line(Vector2(knob_x, knob_y + knob_h), Vector2(knob_x + knob_w, knob_y + knob_h), Color(0.55, 0.54, 0.53), 1.0)

	# Ridges
	for i in 5:
		var ry := knob_y + 3 + i * (knob_h - 6) / 4.0
		draw_line(Vector2(knob_x + 2, ry), Vector2(knob_x + knob_w - 2, ry), Color(0.55, 0.54, 0.53, 0.6), 1.0)
		draw_line(Vector2(knob_x + 2, ry + 1), Vector2(knob_x + knob_w - 2, ry + 1), Color(0.82, 0.81, 0.8, 0.4), 1.0)

	# Count display
	draw_string(font, Vector2(6, 14), str(get_count()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.3, 0.3))
