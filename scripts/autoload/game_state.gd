extends Node

## Global game state singleton

# Demo phases
enum Phase {
	AWAKENING,      # Sheep wakes up
	DISCOVERY,      # Finds cassette-bass
	TUTORIAL,       # Learns movement
	EXPLORATION,    # Free roam
	BUILDING,       # First build
	ENDING          # Signal received
}

var current_phase: Phase = Phase.AWAKENING
var has_cassette_bass: bool = false

# Inventory
var salvage: int = 0
var tape_fragments: int = 0
var wool_fiber: int = 0
var stardust: int = 0

# Building progress
var hull_built: bool = false
var antenna_built: bool = false

# Demo flags
var tutorial_complete: bool = false
var signal_received: bool = false

signal phase_changed(new_phase: Phase)
signal item_collected(item_type: String, amount: int)
signal build_completed(part_name: String)

func advance_phase(to: Phase) -> void:
	if to <= current_phase:
		return
	current_phase = to
	phase_changed.emit(to)

func add_item(item_type: String, amount: int = 1) -> void:
	match item_type:
		"salvage":
			salvage += amount
		"tape_fragment":
			tape_fragments += amount
		"wool_fiber":
			wool_fiber += amount
		"stardust":
			stardust += amount
	item_collected.emit(item_type, amount)

	# Check if we have enough to build something — advance to BUILDING phase
	if current_phase == Phase.EXPLORATION:
		if can_build("hull") or can_build("antenna"):
			advance_phase(Phase.BUILDING)

func can_build(part: String) -> bool:
	match part:
		"hull":
			return salvage >= 3 and wool_fiber >= 2 and not hull_built
		"antenna":
			return tape_fragments >= 2 and stardust >= 1 and not antenna_built
	return false

func build_part(part: String) -> bool:
	if not can_build(part):
		return false
	match part:
		"hull":
			salvage -= 3
			wool_fiber -= 2
			hull_built = true
		"antenna":
			tape_fragments -= 2
			stardust -= 1
			antenna_built = true
	build_completed.emit(part)
	if hull_built and antenna_built:
		advance_phase(Phase.ENDING)
	return true

func get_inventory_text() -> String:
	var lines := []
	if salvage > 0: lines.append("Salvage: %d" % salvage)
	if tape_fragments > 0: lines.append("Tape: %d" % tape_fragments)
	if wool_fiber > 0: lines.append("Wool: %d" % wool_fiber)
	if stardust > 0: lines.append("Dust: %d" % stardust)
	if lines.is_empty():
		return "Empty"
	return "\n".join(lines)
