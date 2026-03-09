extends StaticBody2D

## The tiny floating home-frame where the sheep builds its vessel

@onready var hull_visual: Sprite2D = $HullVisual
@onready var antenna_visual: Sprite2D = $AntennaVisual
@onready var build_prompt: Label = $BuildPrompt
@onready var interact_area: Area2D = $InteractArea

var player_nearby: bool = false
var _base_y: float

func _ready() -> void:
	_base_y = position.y
	hull_visual.visible = false
	antenna_visual.visible = false
	build_prompt.visible = false
	GameState.build_completed.connect(_on_build_completed)

	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		_update_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		build_prompt.visible = false

func _update_prompt() -> void:
	if not player_nearby:
		build_prompt.visible = false
		return

	if not GameState.hull_built and GameState.can_build("hull"):
		build_prompt.text = "[E] Build Hull (3 Salvage, 2 Wool)"
		build_prompt.visible = true
	elif GameState.hull_built and not GameState.antenna_built and GameState.can_build("antenna"):
		build_prompt.text = "[E] Build Antenna (2 Tape, 1 Stardust)"
		build_prompt.visible = true
	elif not GameState.hull_built:
		build_prompt.text = "Need: 3 Salvage, 2 Wool"
		build_prompt.visible = true
	elif not GameState.antenna_built:
		build_prompt.text = "Need: 2 Tape, 1 Stardust"
		build_prompt.visible = true
	else:
		build_prompt.text = "Home complete!"
		build_prompt.visible = true

func interact(player) -> void:
	if not GameState.hull_built:
		GameState.build_part("hull")
	elif not GameState.antenna_built:
		GameState.build_part("antenna")
	_update_prompt()

func _on_build_completed(part_name: String) -> void:
	match part_name:
		"hull":
			hull_visual.visible = true
			_animate_build(hull_visual)
		"antenna":
			antenna_visual.visible = true
			_animate_build(antenna_visual)
	_update_prompt()

func _animate_build(node: Node2D) -> void:
	var target_scale := node.scale
	node.modulate.a = 0.0
	node.scale = target_scale * 0.3
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(node, "scale", target_scale, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _process(_delta: float) -> void:
	# Gentle hover — absolute position, no drift
	position.y = _base_y + sin(Time.get_ticks_msec() * 0.001) * 3.0
