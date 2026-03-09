extends Node2D

## Main demo world — manages phases, camera, narration, and ending sequence

@onready var player: CharacterBody2D = $Sheep
@onready var camera: Camera2D = $Sheep/Camera2D
@onready var narration_label: Label = $UI/NarrationLabel
@onready var cassette_device: Area2D = $CassettePickup
@onready var hud: CanvasLayer = $UI/HUD
@onready var fade_rect: ColorRect = $UI/FadeRect
@onready var ending_label: Label = $UI/EndingLabel

@export var skip_intro: bool = true  ## Set to false for full intro sequence

var narration_queue: Array[Dictionary] = []
var showing_narration: bool = false
var ending_triggered: bool = false

func _ready() -> void:
	# Start with black screen
	fade_rect.color = Color(0, 0, 0, 1)
	ending_label.visible = false
	hud.visible = false
	narration_label.visible = false

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.build_completed.connect(_on_build_completed)

	# Start the demo sequence
	_start_opening()

func _start_opening() -> void:
	if skip_intro:
		# Dev mode: skip intro, give cassette, start gameplay immediately
		fade_rect.color.a = 0.0
		hud.visible = true
		player.receive_cassette()
		GameState.advance_phase(GameState.Phase.EXPLORATION)
		_show_narration("Dev mode — explore freely. SPACE=pulse, A/D=aim, E=interact", 5.0)
		return

	# Fade in from black
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0)
	tween.tween_callback(func():
		_show_narration("...", 3.5)
		await get_tree().create_timer(4.5).timeout
		_show_narration("Where... am I?", 5.0)
		await get_tree().create_timer(6.0).timeout
		_show_narration("Everything is silent.", 5.0)
		await get_tree().create_timer(6.0).timeout
		_show_narration("Something is glowing nearby...", 5.0)
		await get_tree().create_timer(6.0).timeout
		# Give player basic drift ability to reach cassette
		player.can_move = false
		# Gentle nudge toward cassette
		var dir_to_cassette := (cassette_device.global_position - player.global_position).normalized()
		player.space_velocity = dir_to_cassette * 20.0
		GameState.advance_phase(GameState.Phase.DISCOVERY)
	)

func _on_phase_changed(new_phase: GameState.Phase) -> void:
	match new_phase:
		GameState.Phase.DISCOVERY:
			_show_narration("Drift toward the light...", 6.0)
		GameState.Phase.TUTORIAL:
			hud.visible = true
			_show_narration("A cassette player... fused with a bass.", 5.0)
			await get_tree().create_timer(6.0).timeout
			_show_narration("SPACE to play a note. Sound pushes you forward.", 6.0)
			await get_tree().create_timer(7.0).timeout
			_show_narration("A/D to aim. Hold SPACE for a stronger pulse.", 6.0)
			await get_tree().create_timer(7.0).timeout
			_show_narration("E to interact with objects nearby.", 5.0)
			await get_tree().create_timer(6.0).timeout
			_show_narration("Explore the ruins... gather what remains.", 5.0)
			await get_tree().create_timer(6.0).timeout
			GameState.tutorial_complete = true
			GameState.advance_phase(GameState.Phase.EXPLORATION)
		GameState.Phase.EXPLORATION:
			_show_narration("Fragments of home... scattered everywhere.", 6.0)
		GameState.Phase.BUILDING:
			_show_narration("The home-frame... maybe I can rebuild.", 5.0)
		GameState.Phase.ENDING:
			_trigger_ending()

func _on_build_completed(part_name: String) -> void:
	match part_name:
		"hull":
			_show_narration("The hull holds. It feels... almost safe.", 5.0)
			if not GameState.antenna_built:
				await get_tree().create_timer(6.0).timeout
				_show_narration("I need an antenna. To listen for others.", 5.0)
		"antenna":
			_show_narration("The antenna hums to life...", 5.0)

func _trigger_ending() -> void:
	if ending_triggered:
		return
	ending_triggered = true

	await get_tree().create_timer(3.0).timeout
	_show_narration("Wait... what is that sound?", 5.0)
	await get_tree().create_timer(6.0).timeout
	_show_narration("A signal. Faint. But unmistakable.", 5.0)
	await get_tree().create_timer(6.0).timeout
	_show_narration("A distant bleat, wrapped in static.", 6.0)
	await get_tree().create_timer(7.0).timeout

	# Fade to warm color
	ending_label.visible = true
	ending_label.modulate.a = 0.0
	ending_label.text = "You are not alone.\n\n\nAshes of the Meadow\nDemo"

	var tween := create_tween()
	tween.tween_property(ending_label, "modulate:a", 1.0, 3.0)
	tween.tween_interval(8.0)
	tween.tween_property(fade_rect, "color:a", 1.0, 3.0)

func _show_narration(text: String, duration: float) -> void:
	narration_label.text = text
	narration_label.visible = true
	narration_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(narration_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(duration)
	tween.tween_property(narration_label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func(): narration_label.visible = false)
