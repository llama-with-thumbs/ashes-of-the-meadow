extends StaticBody2D

## Floating arcade terminal — interact to play MEGA SHEEP minigame

var player_nearby: bool = false
var _hover_time: float = 0.0

@onready var prompt_label: Label = $PromptLabel
@onready var terminal_sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	prompt_label.visible = false
	var area: Area2D = $InteractArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Gentle hover bob
	_hover_time += delta
	terminal_sprite.position.y = sin(_hover_time * 1.5) * 3.0
	# Prompt pulse
	if player_nearby and prompt_label.visible:
		prompt_label.modulate.a = 0.7 + sin(_hover_time * 3.0) * 0.3

func interact(_player: CharacterBody2D) -> void:
	get_tree().change_scene_to_file("res://scenes/minigame/mega_sheep.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		prompt_label.visible = false
