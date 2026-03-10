extends Node2D

## Main demo world — manages phases, camera, narration, and ending sequence

@onready var player: CharacterBody2D = $Sheep
@onready var camera: Camera2D = $Sheep/Camera2D
@onready var narration_label: Label = $UI/NarrationLabel
@onready var hud: CanvasLayer = $UI/HUD
@onready var fade_rect: ColorRect = $UI/FadeRect
@onready var ending_label: Label = $UI/EndingLabel

var ending_triggered: bool = false
var _active_narrations: Array[Label] = []

func _ready() -> void:
	fade_rect.color = Color(0, 0, 0, 1)
	ending_label.visible = false
	narration_label.visible = false

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.build_completed.connect(_on_build_completed)

	_start_opening()

func _start_opening() -> void:
	# Player can move immediately — ambient space sound is already playing
	hud.visible = true
	player.enable_movement()

	# Fade in from black with atmospheric narration
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0)
	tween.tween_callback(func():
		_show_narration("...")
		await get_tree().create_timer(5.0).timeout
		_show_narration("Where... am I?")
		await get_tree().create_timer(5.0).timeout
		_show_narration("Everything is silent.")
		await get_tree().create_timer(5.0).timeout
		_show_narration("Something is glowing nearby...")
	)

func _on_phase_changed(new_phase: GameState.Phase) -> void:
	match new_phase:
		GameState.Phase.TUTORIAL:
			_show_narration("A cassette player... it still works.")
			await get_tree().create_timer(5.0).timeout
			_show_narration("SPACE to play a note. Sound pushes you forward.")
			await get_tree().create_timer(5.0).timeout
			_show_narration("Hold SPACE for a stronger pulse. E to interact.")
			await get_tree().create_timer(5.0).timeout
			_show_narration("Explore the ruins... gather what remains.")
			await get_tree().create_timer(5.0).timeout
			GameState.tutorial_complete = true
			GameState.advance_phase(GameState.Phase.EXPLORATION)
		GameState.Phase.EXPLORATION:
			_show_narration("Fragments of home... scattered everywhere.")
		GameState.Phase.BUILDING:
			_show_narration("The home-frame... maybe I can rebuild.")
		GameState.Phase.ENDING:
			_trigger_ending()

func _on_build_completed(part_name: String) -> void:
	match part_name:
		"hull":
			_show_narration("The hull holds. It feels... almost safe.")
			if not GameState.antenna_built:
				await get_tree().create_timer(5.0).timeout
				_show_narration("I need an antenna. To listen for others.")
		"antenna":
			_show_narration("The antenna hums to life...")

func _trigger_ending() -> void:
	if ending_triggered:
		return
	ending_triggered = true

	await get_tree().create_timer(3.0).timeout
	_show_narration("Wait... what is that sound?")
	await get_tree().create_timer(5.0).timeout
	_show_narration("A signal. Faint. But unmistakable.")
	await get_tree().create_timer(5.0).timeout
	_show_narration("A distant bleat, wrapped in static.")
	await get_tree().create_timer(5.0).timeout

	ending_label.visible = true
	ending_label.modulate.a = 0.0
	ending_label.text = "You are not alone.\n\n\nAshes of the Meadow\nDemo\n\n\nAuthor of the concept: @AnnSerafima\nDeveloper: VFilitovich"

	var tween := create_tween()
	tween.tween_property(ending_label, "modulate:a", 1.0, 3.0)
	tween.tween_interval(8.0)
	tween.tween_property(fade_rect, "color:a", 1.0, 3.0)

func _show_narration(text: String, duration: float = 5.5) -> void:
	# Drift existing labels upward
	for old_lbl in _active_narrations:
		if is_instance_valid(old_lbl):
			var drift := create_tween()
			drift.tween_property(old_lbl, "offset_top", old_lbl.offset_top - 35.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			drift.parallel().tween_property(old_lbl, "offset_bottom", old_lbl.offset_bottom - 35.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.anchor_left = 0.5
	lbl.anchor_top = 0.5
	lbl.anchor_right = 0.5
	lbl.anchor_bottom = 0.5
	lbl.offset_left = -300.0
	lbl.offset_top = 100.0
	lbl.offset_right = 300.0
	lbl.offset_bottom = 140.0
	lbl.modulate.a = 0.0
	narration_label.get_parent().add_child(lbl)
	_active_narrations.append(lbl)

	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 1.0)
	tween.tween_interval(duration)
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func():
		_active_narrations.erase(lbl)
		lbl.queue_free()
	)
