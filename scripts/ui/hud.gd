extends CanvasLayer

## Minimal HUD showing inventory and phase hints

@onready var inventory_label: Label = $InventoryPanel/InventoryLabel
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	GameState.item_collected.connect(_on_item_collected)
	GameState.phase_changed.connect(_on_phase_changed)
	_update_inventory()

func _on_item_collected(_type: String, _amount: int) -> void:
	_update_inventory()
	# Brief flash on collect
	inventory_label.modulate = Color(1.0, 0.9, 0.5)
	var tween := create_tween()
	tween.tween_property(inventory_label, "modulate", Color.WHITE, 0.5)

func _update_inventory() -> void:
	inventory_label.text = GameState.get_inventory_text()

func _on_phase_changed(phase: GameState.Phase) -> void:
	match phase:
		GameState.Phase.EXPLORATION:
			_show_hint("Collect materials from the debris")
		GameState.Phase.BUILDING:
			_show_hint("Return to the home-frame to build")

func _show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = true
	hint_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.7, 1.0)
	tween.tween_interval(4.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func(): hint_label.visible = false)
