extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D

static var biome_textures: Dictionary = {}

func _ready() -> void:
	apply_level_biome()

func apply_level_biome() -> void:
	var lvl: int = 1
	if get_node_or_null("/root/GameSettings"):
		lvl = clampi(GameSettings.current_level, 1, 10)
	
	var tex = get_biome_texture(lvl)
	if tex and sprite:
		sprite.texture = tex
		sprite.region_enabled = false

static func get_biome_texture(lvl: int) -> Texture2D:
	if biome_textures.has(lvl):
		return biome_textures[lvl]
	
	var path: String = "res://Assets/Tiles/Biomes/ground_lvl1_city.png"
	match lvl:
		1: path = "res://Assets/Tiles/Biomes/ground_lvl1_city.png"
		2: path = "res://Assets/Tiles/Biomes/ground_lvl2_megacity.png"
		3: path = "res://Assets/Tiles/Biomes/ground_lvl3_beach.png"
		4: path = "res://Assets/Tiles/Biomes/ground_lvl4_desert.png"
		5: path = "res://Assets/Tiles/Biomes/ground_lvl5_volcano.png"
		6: path = "res://Assets/Tiles/Biomes/ground_lvl6_canyon.png"
		7: path = "res://Assets/Tiles/Biomes/ground_lvl7_cavern.png"
		8: path = "res://Assets/Tiles/Biomes/ground_lvl8_forest.png"
		9: path = "res://Assets/Tiles/Biomes/ground_lvl9_rooftop.png"
		10, _: path = "res://Assets/Tiles/Biomes/ground_lvl10_citadel.png"
	
	if ResourceLoader.exists(path):
		var loaded_tex = load(path)
		biome_textures[lvl] = loaded_tex
		return loaded_tex
	return null
