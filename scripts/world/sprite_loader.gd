extends Node

## Assigns procedural textures to all scene sprites on _ready.
## Attach as a child of the main scene root.

const ProceduralSprites = preload("res://scripts/world/procedural_sprites.gd")

func _ready() -> void:
	# Wait one frame so all children are ready
	await get_tree().process_frame
	_assign_textures()

func _assign_textures() -> void:
	var root := get_parent()

	# Player sheep
	var sheep := root.get_node_or_null("Sheep")
	if sheep:
		var sprite: Sprite2D = sheep.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = ProceduralSprites.generate_sheep()
		var cassette: Sprite2D = sheep.get_node_or_null("CassetteSprite")
		if cassette:
			cassette.texture = ProceduralSprites.generate_cassette()

	# Cassette pickup
	var cassette_pickup := root.get_node_or_null("CassettePickup")
	if cassette_pickup:
		var sprite: Sprite2D = cassette_pickup.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = ProceduralSprites.generate_cassette()

	# Home base
	var home := root.get_node_or_null("HomeBase")
	if home:
		var sprite: Sprite2D = home.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = ProceduralSprites.generate_home_frame()
		var hull: Sprite2D = home.get_node_or_null("HullVisual")
		if hull:
			hull.texture = ProceduralSprites.generate_hull()
		var antenna: Sprite2D = home.get_node_or_null("AntennaVisual")
		if antenna:
			antenna.texture = ProceduralSprites.generate_antenna()

	# Collectibles and debris — iterate all children of root
	for child in root.get_children():
		if child is Area2D and child.has_method("interact") and "item_type" in child:
			var sprite: Sprite2D = child.get_node_or_null("Sprite2D")
			if sprite:
				sprite.texture = ProceduralSprites.generate_collectible(child.item_type)
		elif child is StaticBody2D and child.get_script() and child.get_script().resource_path.ends_with("debris.gd"):
			var sprite: Sprite2D = child.get_node_or_null("Sprite2D")
			if sprite:
				sprite.texture = ProceduralSprites.generate_debris()
