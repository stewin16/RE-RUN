extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
@onready var bgm: AudioStreamPlayer = $BGM
@onready var speedup_sfx: AudioStreamPlayer = $SpeedupSFX

# Parallax background sprites for color shifting & atmosphere
@onready var bg_sky: TextureRect = $ParallaxBackground/SkyLayer/Sprite
@onready var bg_stars: TextureRect = get_node_or_null("ParallaxBackground/StarsLayer/Sprite")
@onready var bg_clouds: TextureRect = get_node_or_null("ParallaxBackground/CloudsLayer/Sprite")
@onready var bg_distant: TextureRect = $ParallaxBackground/DistantLayer/Sprite
@onready var bg_near: TextureRect = $ParallaxBackground/NearLayer/Sprite

# Celestial Sun & Moon
@onready var sun_sprite: Sprite2D = get_node_or_null("ParallaxBackground/CelestialLayer/SunSprite")
@onready var moon_sprite: Sprite2D = get_node_or_null("ParallaxBackground/CelestialLayer/MoonSprite")

# Packed Scenes for procedural spawning
var ground_scene: PackedScene = preload("res://Scenes/Objects/GroundBlock.tscn")
var p64_scene: PackedScene = preload("res://Scenes/Objects/Platform64.tscn")
var p96_scene: PackedScene = preload("res://Scenes/Objects/Platform96.tscn")
var movplat_scene: PackedScene = preload("res://Scenes/Objects/moving_platform.tscn")
var barrier_scene: PackedScene = preload("res://Scenes/Objects/traffic_barrier.tscn")
var pipe_scene: PackedScene = preload("res://Scenes/Objects/overhead_pipe.tscn")
var spikes_scene: PackedScene = preload("res://Scenes/Objects/spikes.tscn")
var coin_scene: PackedScene = preload("res://Scenes/Objects/coin.tscn")
var terminal_scene: PackedScene = preload("res://Scenes/Objects/tech_terminal.tscn")
var qblock_scene: PackedScene = preload("res://Scenes/Objects/question_block.tscn")

var janitor_scene: PackedScene = preload("res://Scenes/Objects/janitor_chase.tscn")

# Power-ups & Boss Scenes
var pickup_knowledge_scene: PackedScene = preload("res://Scenes/Objects/pickup_knowledge.tscn")
var pickup_hint_scene: PackedScene = preload("res://Scenes/Objects/pickup_hint.tscn")
var pickup_memory_scene: PackedScene = preload("res://Scenes/Objects/pickup_memory.tscn")
var teacher_boss_scene: PackedScene = preload("res://Scenes/Objects/teacher_boss.tscn")

var shake_amount: float = 0.0
var distance_traveled: float = 0.0
var next_speedup_dist: float = 450.0
var is_game_active: bool = true
var next_spawn_x: float = 0.0
var active_chunks: Array[Node2D] = []
var active_janitor: CharacterBody2D = null

# Controlled educational fact milestones (strictly 2 per level) & 4 Random Quiz Boxes
# Interleaved scheduled events queue with dedicated flat obstacle-free runways (zero hazard interference!)
var scheduled_events: Array[Dictionary] = [
	{"type": "quiz", "dist": 650.0},
	{"type": "fact", "dist": 1250.0},
	{"type": "quiz", "dist": 1850.0},
	{"type": "fact", "dist": 2450.0},
	{"type": "quiz", "dist": 3050.0},
	{"type": "quiz", "dist": 3650.0},
]
var next_event_idx: int = 0
var facts_spawned_count: int = 0
const MAX_FACTS_PER_LEVEL: int = 2
var quiz_boxes_spawned_count: int = 0
const MAX_QUIZ_BOXES_PER_LEVEL: int = 4
var hints_spawned_count: int = 0
var max_hints_for_level: int = 1

# Dedicated Level introductory progression & chase controls across all levels
var chaser_encounter_spawned: bool = false
const CHASER_ENCOUNTER_DIST: float = 768.0
var l1_chunk_counter: int = 0

const LEVEL_CHASERS = {
	1: {"name": "Head Janitor", "speech": "YOU'RE LATE!"},
	2: {"name": "Hall Monitor", "speech": "NO RUNNING!"},
	3: {"name": "Canteen Chef", "speech": "FORGOT LUNCH!"},
	4: {"name": "Infirmary Nurse", "speech": "HEALTH CHECK!"},
	5: {"name": "Head Librarian", "speech": "RETURN BOOKS!"},
	6: {"name": "Campus Patrol", "speech": "NO PERMIT!"},
	7: {"name": "Lab Supervisor", "speech": "GOGGLES ON!"},
	8: {"name": "Athletic Coach", "speech": "PICK UP PACE!"},
	9: {"name": "Discipline Officer", "speech": "VIOLATION!"},
	10: {"name": "Principal Pendelton", "speech": "YOU SHALL NOT PASS!"}
}

const LEVEL_ATMOSPHERES = {
	1: { # Level 1 (Dawn / Early Morning - 6:00 AM): Soft Indigo to Sunrise Amber Peach
		"top_sky": Color(0.12, 0.28, 0.58),
		"bot_sky": Color(1.0, 0.62, 0.32),
		"dist_mod": Color(0.72, 0.75, 0.95),
		"near_mod": Color(0.95, 0.92, 0.98),
		"cloud_tint": Color(1.0, 0.88, 0.82, 0.85),
		"sun_vis": 1.0,
		"moon_vis": 0.10,
		"star_vis": 0.15
	},
	2: { # Level 2 (Early Morning - 7:30 AM): Crisp Blue to Golden Morning Light
		"top_sky": Color(0.16, 0.42, 0.82),
		"bot_sky": Color(0.98, 0.80, 0.48),
		"dist_mod": Color(0.80, 0.82, 0.95),
		"near_mod": Color(1.0, 0.96, 0.95),
		"cloud_tint": Color(1.0, 0.95, 0.88, 0.85),
		"sun_vis": 1.0,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	3: { # Level 3 (Mid-Morning - 9:00 AM): Fresh Azure Sky with Pure White Morning Warmth
		"top_sky": Color(0.14, 0.50, 0.90),
		"bot_sky": Color(0.60, 0.85, 1.0),
		"dist_mod": Color(0.85, 0.92, 1.0),
		"near_mod": Color(1.0, 1.0, 1.0),
		"cloud_tint": Color(1.0, 1.0, 1.0, 0.90),
		"sun_vis": 1.0,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	4: { # Level 4 (Late Morning - 11:00 AM): Bright Cerulean Sky with Sun High
		"top_sky": Color(0.18, 0.58, 0.96),
		"bot_sky": Color(0.75, 0.90, 1.0),
		"dist_mod": Color(0.90, 0.94, 1.0),
		"near_mod": Color(1.0, 1.0, 0.98),
		"cloud_tint": Color(1.0, 1.0, 1.0, 0.90),
		"sun_vis": 1.0,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	5: { # Level 5 (High Noon - 12:30 PM): Brilliant Cyan Zenith Midday Sun
		"top_sky": Color(0.15, 0.62, 1.0),
		"bot_sky": Color(0.82, 0.95, 1.0),
		"dist_mod": Color(0.92, 0.96, 1.0),
		"near_mod": Color(1.0, 1.0, 1.0),
		"cloud_tint": Color(1.0, 1.0, 1.0, 0.95),
		"sun_vis": 1.0,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	6: { # Level 6 (Early Afternoon - 2:30 PM): Warm Sunny Afternoon Sky
		"top_sky": Color(0.20, 0.50, 0.88),
		"bot_sky": Color(0.96, 0.85, 0.62),
		"dist_mod": Color(0.92, 0.88, 0.85),
		"near_mod": Color(1.0, 0.95, 0.90),
		"cloud_tint": Color(1.0, 0.95, 0.85, 0.85),
		"sun_vis": 0.95,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	7: { # Level 7 (Late Afternoon - 4:30 PM): Deepening Amber and Gold Afternoon
		"top_sky": Color(0.26, 0.36, 0.72),
		"bot_sky": Color(0.98, 0.65, 0.32),
		"dist_mod": Color(0.88, 0.70, 0.65),
		"near_mod": Color(1.0, 0.85, 0.75),
		"cloud_tint": Color(1.0, 0.80, 0.68, 0.85),
		"sun_vis": 0.85,
		"moon_vis": 0.0,
		"star_vis": 0.0
	},
	8: { # Level 8 (Golden Hour / Sunset - 5:45 PM): Vibrant Crimson & Orange Sunset
		"top_sky": Color(0.32, 0.14, 0.42),
		"bot_sky": Color(0.98, 0.40, 0.16),
		"dist_mod": Color(0.85, 0.45, 0.40),
		"near_mod": Color(1.0, 0.65, 0.50),
		"cloud_tint": Color(1.0, 0.60, 0.45, 0.85),
		"sun_vis": 0.70,
		"moon_vis": 0.10,
		"star_vis": 0.10
	},
	9: { # Level 9 (Dusk / Twilight - 6:45 PM): Deep Purple Dusk with Early Stars
		"top_sky": Color(0.15, 0.06, 0.30),
		"bot_sky": Color(0.82, 0.25, 0.42),
		"dist_mod": Color(0.70, 0.40, 0.70),
		"near_mod": Color(0.90, 0.65, 0.85),
		"cloud_tint": Color(0.75, 0.45, 0.75, 0.80),
		"sun_vis": 0.20,
		"moon_vis": 0.65,
		"star_vis": 0.55
	},
	10: { # Level 10 (Evening - 7:45 PM): Deep Indigo Twilight & Evening Moon
		"top_sky": Color(0.05, 0.05, 0.18),
		"bot_sky": Color(0.28, 0.14, 0.45),
		"dist_mod": Color(0.55, 0.40, 0.70),
		"near_mod": Color(0.75, 0.60, 0.90),
		"cloud_tint": Color(0.50, 0.35, 0.65, 0.75),
		"sun_vis": 0.0,
		"moon_vis": 1.0,
		"star_vis": 0.85
	}
}

# Boss encounter variables
var boss_spawned: bool = false
var is_boss_active: bool = false
var boss_trigger_x: float = 0.0
var boss_instance: CharacterBody2D = null
const BOSS_ENCOUNTER_DIST: float = 1100.0

var sky_gradient: Gradient
var sky_gradient_tex: GradientTexture2D

func _ready() -> void:
	if camera:
		camera.limit_right = 10000000

	# Dynamic Sky Gradient (top to bottom)
	sky_gradient = Gradient.new()
	sky_gradient.set_color(0, Color(0.12, 0.45, 0.88)) # Rich Blue
	sky_gradient.set_color(1, Color(1.0, 0.58, 0.18))  # Sunrise Orange
	sky_gradient_tex = GradientTexture2D.new()
	sky_gradient_tex.width = 480
	sky_gradient_tex.height = 270
	sky_gradient_tex.fill_from = Vector2(0.5, 0.0)
	sky_gradient_tex.fill_to = Vector2(0.5, 1.0)
	sky_gradient_tex.gradient = sky_gradient
	if bg_sky:
		bg_sky.texture = sky_gradient_tex
		bg_sky.offset_top = 0.0
		bg_sky.offset_bottom = 270.0
		bg_sky.modulate = Color.WHITE

	# Connect player signals
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		player.is_controlled = true
		if hud and hud.has_method("update_health"):
			hud.update_health(player.health, player.max_health)

	# Connect HUD signals
	if hud:
		hud.countdown_finished.connect(_on_countdown_finished)
		hud.restart_requested.connect(_on_restart_requested)
		hud.revive_requested.connect(_on_revive_requested)

	# Apply Level-Specific Configuration (Speed, speedup thresholds, initial atmosphere)
	setup_level_config()

	# Set initial atmosphere immediately
	update_background_atmosphere(true)

	# Build initial safe runway with level-appropriate items
	build_initial_track()

	# Start countdown overlay
	if hud:
		hud.start_countdown()

func setup_level_config() -> void:
	max_hints_for_level = randi_range(1, 2)
	hints_spawned_count = 0
	var env_lvl := OS.get_environment("COLLEGE_RUN_LEVEL")
	if env_lvl != "":
		GameSettings.current_level = clampi(int(env_lvl), 1, 10)
	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i] == "--level" and i + 1 < user_args.size():
			GameSettings.current_level = clampi(int(user_args[i + 1]), 1, 10)

	var lvl: int = clampi(GameSettings.current_level, 1, 10)
	if player:
		match lvl:
			1:
				player.SPEED = 220.0
				next_speedup_dist = 550.0
			2:
				player.SPEED = 240.0
				next_speedup_dist = 500.0
			3:
				player.SPEED = 260.0
				next_speedup_dist = 460.0
			4:
				player.SPEED = 280.0
				next_speedup_dist = 420.0
			5:
				player.SPEED = 300.0
				next_speedup_dist = 390.0
			6:
				player.SPEED = 315.0
				next_speedup_dist = 360.0
			7:
				player.SPEED = 330.0
				next_speedup_dist = 340.0
			8:
				player.SPEED = 345.0
				next_speedup_dist = 320.0
			9:
				player.SPEED = 355.0
				next_speedup_dist = 300.0
			10, _:
				player.SPEED = 365.0
				next_speedup_dist = 280.0

	setup_level_backgrounds(lvl)
	init_scheduled_events()

func init_scheduled_events() -> void:
	var total_dist: float = get_boss_target_distance()
	scheduled_events = [
		{"type": "quiz", "dist": maxf(total_dist * 0.22, 1200.0)},
		{"type": "fact", "dist": total_dist * 0.38},
		{"type": "quiz", "dist": total_dist * 0.52},
		{"type": "fact", "dist": total_dist * 0.66},
		{"type": "quiz", "dist": total_dist * 0.78},
		{"type": "quiz", "dist": total_dist * 0.88},
	]
	next_event_idx = 0
	facts_spawned_count = 0
	quiz_boxes_spawned_count = 0

func setup_level_backgrounds(lvl: int) -> void:
	var dist_tex_path: String = "res://Assets/Backgrounds/city_distant.png"
	var near_tex_path: String = "res://Assets/Backgrounds/city_near.png"

	# First (1) and Last (10) keep the original Academy Cyber City.
	# Middle levels (2 to 9) get unique themed pixel backgrounds from PIXEL BACKGROUNDS.
	# The sky, clouds, stars, and celestial bodies remain identical across all levels.
	match lvl:
		1, 10:
			dist_tex_path = "res://Assets/Backgrounds/city_distant.png"
			near_tex_path = "res://Assets/Backgrounds/city_near.png"
		2:
			# City Landscape Megacity
			dist_tex_path = "res://Assets/Backgrounds/lvl2_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl2_near.png"
		3:
			# Beach & Coastal Route
			dist_tex_path = "res://Assets/Backgrounds/lvl3_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl3_near.png"
		4:
			# Desert Biome Dunes
			dist_tex_path = "res://Assets/Backgrounds/lvl4_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl4_near.png"
		5:
			# Volcano Mountain & Lava Peaks
			dist_tex_path = "res://Assets/Backgrounds/lvl5_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl5_near.png"
		6:
			# Foozle Desert Canyon Mesas
			dist_tex_path = "res://Assets/Backgrounds/lvl6_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl6_near.png"
		7:
			# Foozle Underground Caverns & Crystals
			dist_tex_path = "res://Assets/Backgrounds/lvl7_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl7_near.png"
		8:
			# Volcano Highlands & Ember Forest
			dist_tex_path = "res://Assets/Backgrounds/lvl8_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl8_near.png"
		9:
			# High-Rise Metropolitan Skyline
			dist_tex_path = "res://Assets/Backgrounds/lvl9_distant.png"
			near_tex_path = "res://Assets/Backgrounds/lvl9_near.png"

	if bg_distant and ResourceLoader.exists(dist_tex_path):
		bg_distant.texture = load(dist_tex_path)
		bg_distant.offset_top = 0.0
		bg_distant.offset_bottom = 270.0
	if bg_near and ResourceLoader.exists(near_tex_path):
		bg_near.texture = load(near_tex_path)
		bg_near.offset_top = 0.0
		bg_near.offset_bottom = 270.0

	update_background_atmosphere(true)

func setup_biome_weather(_lvl: int) -> void:
	pass

func build_initial_track() -> void:
	# Initial safe runway: 3 ground blocks (576px) in proper chunk nodes for all levels
	var init_root := Node2D.new()
	init_root.position = Vector2(0, 0)
	add_child(init_root)
	active_chunks.append(init_root)

	for i in range(3):
		var g = ground_scene.instantiate()
		g.position = Vector2(float(i) * 192.0 + 96.0, 220.0)
		init_root.add_child(g)

	# Introductory traffic barrier with intuitive single-jump arc
	var barrier = barrier_scene.instantiate()
	barrier.position = Vector2(350.0, 196.0)
	barrier.near_miss_triggered.connect(_on_near_miss)
	init_root.add_child(barrier)

	# Seldom coins: 2 warm-up coins before the hurdle, and a 3-coin arc over the barrier
	spawn_coin(Vector2(160.0, 175.0), init_root)
	spawn_coin(Vector2(210.0, 175.0), init_root)
	spawn_barrier_jump_arc(init_root, 350.0)

	init_root.set_meta("end_x", 576.0)
	next_spawn_x = 576.0

func _on_chaser_intro_requested(c_name: String, c_speech: String) -> void:
	if hud and hud.has_method("show_chase_warning"):
		hud.show_chase_warning(c_name, c_speech)

func _process(delta: float) -> void:
	# Camera screen shake
	if shake_amount > 0.0:
		shake_amount = max(0.0, shake_amount - delta * 25.0)
		if camera:
			camera.offset = Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

	# Continuous gentle cloud floating drift
	var clouds_layer: ParallaxLayer = get_node_or_null("ParallaxBackground/CloudsLayer")
	if clouds_layer:
		clouds_layer.motion_offset.x -= delta * 12.0

	if not player:
		return

	# Dynamic procedural chunk generation ahead of player
	if player.global_position.x + 1200.0 > next_spawn_x:
		spawn_next_chunk()

	# Despawn old chunks behind player
	cleanup_old_chunks()

	# Check boss encounter trigger
	if boss_spawned and not is_boss_active:
		if player.global_position.x >= boss_trigger_x:
			is_boss_active = true
			player.is_controlled = false
			player.velocity.x = 0.0
			if is_instance_valid(boss_instance):
				boss_instance.is_active = true
			if hud and hud.has_method("start_boss_battle") and is_instance_valid(boss_instance):
				hud.start_boss_battle(boss_instance)

	if is_game_active and not player.is_dead and not is_boss_active:
		var dist_delta := player.velocity.x * delta
		if dist_delta > 0:
			distance_traveled += dist_delta
			if hud:
				hud.add_score(int(dist_delta * 0.15))

		# Day / Night background cycle & Sun / Moon celestial motion
		update_background_atmosphere()

func get_weighted_chunk_type(level: int) -> int:
	var pool: Array = []
	match level:
		1:
			# Level 1 (Academy Cyber City): Balanced sprint, low pipes, traffic barriers, spike pit leap, janitor
			pool = [
				{"type": 1, "w": 20},
				{"type": 2, "w": 20},
				{"type": 3, "w": 20},
				{"type": 4, "w": 15},
				{"type": 9, "w": 15},
				{"type": 0, "w": 10}
			]
		2:
			# Level 2 (Industrial Megacity): Faster pace, moving platforms, triple barrier rush, quad maze, janitor
			pool = [
				{"type": 1, "w": 15},
				{"type": 2, "w": 20},
				{"type": 6, "w": 20},
				{"type": 12, "w": 15},
				{"type": 5, "w": 15},
				{"type": 9, "w": 15}
			]
		3:
			# Level 3 (Beach & Coastal Shore): High platform traverses, lucky vault coin sprints, moving pier platforms, plain sprint
			pool = [
				{"type": 7, "w": 25},
				{"type": 11, "w": 20},
				{"type": 5, "w": 20},
				{"type": 4, "w": 15},
				{"type": 0, "w": 10},
				{"type": 9, "w": 10}
			]
		4:
			# Level 4 (Desert Dunes): Sand dune platform leaps, high traverses, lucky vault sprints, triple barriers
			pool = [
				{"type": 4, "w": 25},
				{"type": 11, "w": 20},
				{"type": 7, "w": 20},
				{"type": 6, "w": 15},
				{"type": 12, "w": 10},
				{"type": 9, "w": 10}
			]
		5:
			# Level 5 (Volcano Magma Peaks): Double spike lava pits, gauntlet traps, quad mazes, moving basalt platforms
			pool = [
				{"type": 10, "w": 25},
				{"type": 8, "w": 20},
				{"type": 12, "w": 20},
				{"type": 5, "w": 15},
				{"type": 6, "w": 10},
				{"type": 9, "w": 10}
			]
		6:
			# Level 6 (Canyon Redrock): High platform traverses, double spike canyon chasms, moving platforms, triple barriers
			pool = [
				{"type": 11, "w": 25},
				{"type": 10, "w": 20},
				{"type": 5, "w": 20},
				{"type": 6, "w": 15},
				{"type": 7, "w": 10},
				{"type": 9, "w": 10}
			]
		7:
			# Level 7 (Underground Crystal Cavern): Low stalactite pipe slides, moving crystal platforms, gauntlets, spike pits
			pool = [
				{"type": 2, "w": 25},
				{"type": 5, "w": 20},
				{"type": 8, "w": 20},
				{"type": 4, "w": 15},
				{"type": 10, "w": 10},
				{"type": 9, "w": 10}
			]
		8:
			# Level 8 (Emerald Forest): High canopy platform traverses, tangled root double spikes, lucky vault sprints, root slides
			pool = [
				{"type": 11, "w": 30},
				{"type": 10, "w": 20},
				{"type": 7, "w": 20},
				{"type": 2, "w": 15},
				{"type": 1, "w": 10},
				{"type": 9, "w": 5}
			]
		9:
			# Level 9 (High-Rise Skyline): High altitude moving platforms, quad mazes, triple barriers, gauntlet combos
			pool = [
				{"type": 12, "w": 25},
				{"type": 5, "w": 25},
				{"type": 6, "w": 20},
				{"type": 8, "w": 15},
				{"type": 11, "w": 10},
				{"type": 9, "w": 5}
			]
		10, _:
			# Level 10 (Cosmic Citadel): Grand master exam gauntlet combining all intense obstacle types
			pool = [
				{"type": 12, "w": 25},
				{"type": 8, "w": 20},
				{"type": 11, "w": 20},
				{"type": 10, "w": 15},
				{"type": 5, "w": 10},
				{"type": 9, "w": 10}
			]

	var total_w := 0
	for item in pool:
		total_w += item["w"]
	var rnd: int = randi() % max(1, total_w)
	var curr := 0
	for item in pool:
		curr += item["w"]
		if rnd < curr:
			return item["type"]
	return 0

func get_boss_target_distance() -> float:
	var lvl: int = clampi(GameSettings.current_level, 1, 10)
	return 4200.0 + (lvl - 1) * 400.0

func check_and_spawn_scheduled_event() -> bool:
	if next_event_idx >= scheduled_events.size() or boss_spawned:
		return false
	var evt: Dictionary = scheduled_events[next_event_idx]
	var evt_dist: float = evt.get("dist", 999999.0)
	if next_spawn_x < evt_dist:
		return false

	var event_root := Node2D.new()
	event_root.position = Vector2(next_spawn_x, 0)
	add_child(event_root)
	active_chunks.append(event_root)

	# 2 Ground blocks of completely flat, obstacle-free pavement (384px)
	spawn_ground(event_root, Vector2(96, 220))
	spawn_ground(event_root, Vector2(288, 220))

	var evt_type: String = evt.get("type", "quiz")
	if evt_type == "quiz":
		# Position golden question block [ ? ] right in center at accessible jumping height
		spawn_quiz_box(Vector2(192.0, 145.0), event_root)
		quiz_boxes_spawned_count += 1
	elif evt_type == "fact":
		# Position Knowledge book right in center at jumping height
		if pickup_knowledge_scene:
			spawn_knowledge(Vector2(192.0, 145.0), event_root)
		facts_spawned_count += 1
		# If level rolled 2 hints, spawn first hint pickup on this safe runway stretch
		if max_hints_for_level >= 2 and hints_spawned_count == 0 and pickup_hint_scene:
			spawn_hint(Vector2(288.0, 155.0), event_root)
			hints_spawned_count += 1

	next_spawn_x += 384.0
	event_root.set_meta("end_x", next_spawn_x)
	next_event_idx += 1
	return true

func check_and_spawn_chaser_encounter() -> bool:
	if chaser_encounter_spawned or boss_spawned:
		return false
	if next_spawn_x < CHASER_ENCOUNTER_DIST:
		return false

	chaser_encounter_spawned = true
	var chunk_root := Node2D.new()
	chunk_root.position = Vector2(next_spawn_x, 0)
	add_child(chunk_root)
	active_chunks.append(chunk_root)

	# 2 Ground blocks of completely flat, obstacle-free runway (384px)
	spawn_ground(chunk_root, Vector2(96, 220))
	spawn_ground(chunk_root, Vector2(288, 220))

	# Clean up any stale chaser
	if is_instance_valid(active_janitor):
		active_janitor.queue_free()
		active_janitor = null

	# Instantiate Standing Janitor ahead on track, facing left towards approaching player!
	if janitor_scene:
		var jan = janitor_scene.instantiate()
		jan.global_position = Vector2(next_spawn_x + 220.0, 196.0)
		jan.is_standing = true
		jan.chase_dir = -1.0
		add_child(jan)
		active_janitor = jan
		if jan.has_signal("intro_requested"):
			jan.intro_requested.connect(_on_chaser_intro_requested)

	next_spawn_x += 384.0
	chunk_root.set_meta("end_x", next_spawn_x)
	return true

func spawn_next_chunk() -> void:
	# Check if it's time for the Final Exam Boss
	if distance_traveled >= get_boss_target_distance() and not boss_spawned:
		spawn_boss_arena()
		return

	if boss_spawned:
		# Just extend flat arena ground
		var g = ground_scene.instantiate()
		g.position = Vector2(next_spawn_x + 96.0, 220.0)
		g.set_meta("end_x", next_spawn_x + 192.0)
		add_child(g)
		active_chunks.append(g)
		next_spawn_x += 192.0
		return

	# Check standing chaser encounter milestone
	if check_and_spawn_chaser_encounter():
		return

	# Check scheduled educational/quiz milestones before any obstacle chunk
	if check_and_spawn_scheduled_event():
		return

	var chunk_type := get_weighted_chunk_type(GameSettings.current_level)
	var chunk_root := Node2D.new()
	chunk_root.position = Vector2(next_spawn_x, 0)
	add_child(chunk_root)
	active_chunks.append(chunk_root)

	match chunk_type:
		0:
			# Type 0: Clear Sprint Runway with Tech Terminal & Coins (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			if terminal_scene and randf() < 0.4:
				var term = terminal_scene.instantiate()
				term.position = Vector2(288, 196)
				chunk_root.add_child(term)
			else:
				spawn_coin_wave(Vector2(160, 160), 6, chunk_root)
			next_spawn_x += 576.0

		1:
			# Type 1: Single Traffic Hurdle [JUMP] (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			var barrier = barrier_scene.instantiate()
			barrier.position = Vector2(288, 196)
			barrier.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(barrier)
			spawn_barrier_jump_arc(chunk_root, 288.0)
			next_spawn_x += 576.0

		2:
			# Type 2: Low Overhead Conduit Pipe [SLIDE] (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			var pipe = pipe_scene.instantiate()
			pipe.position = Vector2(288, 196)
			pipe.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(pipe)
			spawn_pipe_slide_trail(chunk_root, 288.0)
			next_spawn_x += 576.0

		3:
			# Type 3: Two-Tier Terrain: Elevated Platform Route with Ground Hazard (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			var b3 = barrier_scene.instantiate()
			b3.position = Vector2(288, 196)
			b3.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b3)
			spawn_platform(chunk_root, p96_scene, Vector2(288, 138))
			spawn_coin(Vector2(258, 115), chunk_root)
			spawn_coin(Vector2(288, 110), chunk_root)
			spawn_coin(Vector2(318, 115), chunk_root)
			next_spawn_x += 576.0

		4:
			# Type 4: Ground Spikes with Stepping Platform (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			var spk = spikes_scene.instantiate()
			spk.position = Vector2(288, 196)
			chunk_root.add_child(spk)
			spawn_platform(chunk_root, p64_scene, Vector2(288, 142))
			spawn_coin(Vector2(288, 118), chunk_root)
			next_spawn_x += 576.0

		5:
			# Type 5: Moving Platform across Ground Hazard (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			var spk5 = spikes_scene.instantiate()
			spk5.position = Vector2(288, 196)
			chunk_root.add_child(spk5)
			var mov = movplat_scene.instantiate()
			mov.position = Vector2(288, 145)
			mov.move_offset = Vector2(30, 0)
			mov.duration = max(1.5, 2.2 - GameSettings.current_level * 0.1)
			chunk_root.add_child(mov)
			var c5 = coin_scene.instantiate()
			c5.position = Vector2(0, -20.0)
			c5.collected.connect(_on_coin_collected.bind(c5))
			mov.add_child(c5)
			next_spawn_x += 576.0

		6:
			# Type 6: Rhythm Combo 1: Hurdle then Slide (Length 768px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			var b6 = barrier_scene.instantiate()
			b6.position = Vector2(220, 196)
			b6.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b6)
			spawn_barrier_jump_arc(chunk_root, 220.0)
			var pipe6 = pipe_scene.instantiate()
			pipe6.position = Vector2(520, 196)
			pipe6.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(pipe6)
			spawn_pipe_slide_trail(chunk_root, 520.0)
			next_spawn_x += 768.0

		7:
			# Type 7: Multi-Tier Stepped Terrain (Length 768px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			var b7 = barrier_scene.instantiate()
			b7.position = Vector2(360, 196)
			b7.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b7)
			spawn_platform(chunk_root, p96_scene, Vector2(240, 150))
			spawn_coin(Vector2(240, 126), chunk_root)
			spawn_platform(chunk_root, p64_scene, Vector2(480, 115))
			spawn_coin(Vector2(480, 92), chunk_root)
			next_spawn_x += 768.0

		8:
			# Type 8: High Vault Stretch with Question Block (Length 576px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			if qblock_scene:
				var qb = qblock_scene.instantiate()
				qb.position = Vector2(288, 140)
				chunk_root.add_child(qb)
			spawn_vault_double_jump_arc(chunk_root, 288.0)
			next_spawn_x += 576.0

		9:
			# Type 9: Staggered Double Barriers (Length 768px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			var b9a = barrier_scene.instantiate()
			b9a.position = Vector2(220, 196)
			b9a.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b9a)
			spawn_barrier_jump_arc(chunk_root, 220.0)
			var b9b = barrier_scene.instantiate()
			b9b.position = Vector2(520, 196)
			b9b.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b9b)
			spawn_barrier_jump_arc(chunk_root, 520.0)
			next_spawn_x += 768.0

		10:
			# Type 10: Spike Pit Run with Overhead Safe Rail (Length 768px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			var spk10 = spikes_scene.instantiate()
			spk10.position = Vector2(300, 196)
			chunk_root.add_child(spk10)
			spawn_platform(chunk_root, p96_scene, Vector2(300, 138))
			spawn_coin(Vector2(280, 115), chunk_root)
			spawn_coin(Vector2(320, 115), chunk_root)
			var b10 = barrier_scene.instantiate()
			b10.position = Vector2(580, 196)
			b10.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b10)
			spawn_barrier_jump_arc(chunk_root, 580.0)
			next_spawn_x += 768.0

		11:
			# Type 11: Rhythm Combo 2: Slide then Hurdle (Length 768px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			var pipe11 = pipe_scene.instantiate()
			pipe11.position = Vector2(220, 196)
			pipe11.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(pipe11)
			spawn_pipe_slide_trail(chunk_root, 220.0)
			var b11 = barrier_scene.instantiate()
			b11.position = Vector2(520, 196)
			b11.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(b11)
			spawn_barrier_jump_arc(chunk_root, 520.0)
			next_spawn_x += 768.0

		12, _:
			# Type 12: Grand Campus Gauntlet (Length 960px)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			spawn_ground(chunk_root, Vector2(864, 220))
			var pipe12 = pipe_scene.instantiate()
			pipe12.position = Vector2(180, 196)
			pipe12.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(pipe12)
			spawn_pipe_slide_trail(chunk_root, 180.0)
			var spk12 = spikes_scene.instantiate()
			spk12.position = Vector2(460, 196)
			chunk_root.add_child(spk12)
			spawn_platform(chunk_root, p96_scene, Vector2(460, 138))
			spawn_coin(Vector2(460, 115), chunk_root)
			var bar12 = barrier_scene.instantiate()
			bar12.position = Vector2(740, 196)
			bar12.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(bar12)
			spawn_barrier_jump_arc(chunk_root, 740.0)
			next_spawn_x += 960.0

	chunk_root.set_meta("end_x", next_spawn_x)

func spawn_boss_arena() -> void:
	boss_spawned = true
	if is_instance_valid(active_janitor) and active_janitor.has_method("tire_out"):
		active_janitor.tire_out()
	var arena_root := Node2D.new()
	arena_root.position = Vector2(next_spawn_x, 0)
	arena_root.set_meta("end_x", next_spawn_x + 1440.0)
	add_child(arena_root)
	active_chunks.append(arena_root)

	# 1. Pre-Boss Safe Preparation Runway (No hazards, refill items)
	spawn_ground(arena_root, Vector2(96, 220))
	spawn_ground(arena_root, Vector2(288, 220))

	# Pre-boss runway: hint pickup for exam prep (random 1 or 2 hints across level)
	if pickup_hint_scene and hints_spawned_count < max_hints_for_level:
		spawn_hint(Vector2(200, 180), arena_root)
		hints_spawned_count += 1

	# 2. Flat Examination Arena Ground
	for i in range(5):
		spawn_ground(arena_root, Vector2(480 + i * 192, 220))

	# Spawn Teacher Boss in examination arena
	boss_instance = teacher_boss_scene.instantiate()
	boss_instance.position = Vector2(720, 180)
	boss_instance.z_index = 5
	arena_root.add_child(boss_instance)

	boss_trigger_x = next_spawn_x + 550.0
	next_spawn_x += 1440.0

func spawn_ground(parent: Node2D, pos: Vector2) -> void:
	var g = ground_scene.instantiate()
	g.position = pos
	parent.add_child(g)

func spawn_platform(parent: Node2D, scn: PackedScene, pos: Vector2) -> void:
	var p = scn.instantiate()
	p.position = pos
	parent.add_child(p)

func spawn_coin(pos: Vector2, parent: Node2D = self) -> void:
	if not coin_scene:
		return
	var c = coin_scene.instantiate()
	c.position = pos
	c.collected.connect(_on_coin_collected.bind(c))
	parent.add_child(c)

func spawn_ground_coins(parent: Node2D, start_x: float, count: int, spacing: float = 28.0, y_pos: float = 175.0) -> void:
	for i in range(count):
		spawn_coin(Vector2(start_x + float(i) * spacing, y_pos), parent)

func spawn_barrier_jump_arc(parent: Node2D, barrier_x: float) -> void:
	# Parabolic 3-coin arc matching single-jump trajectory over barrier at barrier_x
	var pts: Array[Vector2] = [
		Vector2(barrier_x - 36.0, 160.0), # Takeoff waist height
		Vector2(barrier_x, 120.0),         # Apex right over hurdle
		Vector2(barrier_x + 36.0, 160.0)  # Landing waist height
	]
	for p in pts:
		spawn_coin(p, parent)

func spawn_pipe_slide_trail(parent: Node2D, pipe_x: float) -> void:
	# 2 coins (seldom) along pavement surface under the low pipe — teaches slide
	spawn_coin(Vector2(pipe_x - 18.0, 190.0), parent)
	spawn_coin(Vector2(pipe_x + 18.0, 190.0), parent)

func spawn_platform_coin_line(parent: Node2D, plat_center_x: float, plat_width: float, plat_y: float) -> void:
	var coin_y: float = plat_y - 20.0
	spawn_coin(Vector2(plat_center_x, coin_y), parent)

func spawn_vault_double_jump_arc(parent: Node2D, center_x: float) -> void:
	# Seldom design: exactly 3 coins at the peak of the double-jump arc
	spawn_coin(Vector2(center_x - 24.0, 88.0), parent)
	spawn_coin(Vector2(center_x, 80.0), parent)
	spawn_coin(Vector2(center_x + 24.0, 88.0), parent)

func spawn_coin_arc(start_pos: Vector2, count: int, parent: Node2D = self, apex_height: float = 55.0, spacing: float = 28.0) -> void:
	for i in range(count):
		var t = float(i) / float(max(1, count - 1))
		var arc_y = -sin(t * PI) * apex_height
		var c_pos = start_pos + Vector2(i * spacing, arc_y)
		spawn_coin(c_pos, parent)

func spawn_coin_wave(start_pos: Vector2, count: int, parent: Node2D = self, wavelength: float = 30.0, amplitude: float = 32.0) -> void:
	for i in range(count):
		var wave_y = sin(float(i) * 0.7) * amplitude
		var c_pos = start_pos + Vector2(i * wavelength, wave_y)
		spawn_coin(c_pos, parent)

func spawn_coin_cluster(center_pos: Vector2, parent: Node2D = self, spacing: float = 22.0) -> void:
	var offsets = [
		Vector2(0, -spacing),
		Vector2(-spacing, 0),
		Vector2(0, 0),
		Vector2(spacing, 0),
		Vector2(0, spacing)
	]
	for off in offsets:
		spawn_coin(center_pos + off, parent)

func spawn_coin_stair(start_pos: Vector2, count: int, step: Vector2, parent: Node2D = self) -> void:
	for i in range(count):
		spawn_coin(start_pos + step * float(i), parent)

func spawn_random_sky_coins(chunk_root: Node2D, chunk_len: float, min_x: float = 40.0, max_x_offset: float = 60.0) -> void:
	var current_x = min_x + randf_range(0.0, 30.0)
	var end_bound = chunk_len - max_x_offset
	
	while current_x < end_bound:
		var pattern = randi() % 6
		var height_tier = randi() % 3 # 0 = High double-jump vault (65..95), 1 = Mid-air leap (115..140), 2 = Low runner glide (160..175)
		var base_y = 165.0
		if height_tier == 0:
			base_y = randf_range(75.0, 95.0)
		elif height_tier == 1:
			base_y = randf_range(115.0, 140.0)
		else:
			base_y = randf_range(160.0, 175.0)

		match pattern:
			0: # Dynamic Arc (Apex from 45 to 85 px, 4 to 7 coins)
				var count = randi_range(4, 7)
				var apex = randf_range(45.0, 85.0)
				var spacing = randf_range(24.0, 32.0)
				spawn_coin_arc(Vector2(current_x, base_y), count, chunk_root, apex, spacing)
				current_x += count * spacing + randf_range(45.0, 80.0)

			1: # Sinusoidal Wave (5 to 8 coins undulating across track)
				var count = randi_range(5, 8)
				var amp = randf_range(22.0, 38.0)
				var wl = randf_range(26.0, 34.0)
				spawn_coin_wave(Vector2(current_x, base_y), count, chunk_root, wl, amp)
				current_x += count * wl + randf_range(45.0, 80.0)

			2: # Diamond Cluster (5 coins floating high)
				spawn_coin_cluster(Vector2(current_x + 30.0, clampf(base_y - 20.0, 70.0, 145.0)), chunk_root, randf_range(18.0, 24.0))
				current_x += 80.0 + randf_range(40.0, 70.0)

			3: # Ascending Staircase (Upward 4-step ramp)
				var count = randi_range(3, 5)
				var step = Vector2(randf_range(24.0, 30.0), -randf_range(14.0, 22.0))
				var start_y = minf(base_y + 25.0, 180.0)
				spawn_coin_stair(Vector2(current_x, start_y), count, step, chunk_root)
				current_x += count * step.x + randf_range(40.0, 75.0)

			4: # Descending Staircase (Downward 4-step slope)
				var count = randi_range(3, 5)
				var step = Vector2(randf_range(24.0, 30.0), randf_range(14.0, 22.0))
				var start_y = maxf(base_y - 25.0, 80.0)
				spawn_coin_stair(Vector2(current_x, start_y), count, step, chunk_root)
				current_x += count * step.x + randf_range(40.0, 75.0)

			5: # Double Leap Arch (two small consecutive quick arcs)
				var apex = randf_range(35.0, 55.0)
				spawn_coin_arc(Vector2(current_x, base_y), 4, chunk_root, apex, 24.0)
				spawn_coin_arc(Vector2(current_x + 96.0, base_y), 4, chunk_root, apex, 24.0)
				current_x += 192.0 + randf_range(45.0, 75.0)

func spawn_knowledge(pos: Vector2, parent: Node2D = self) -> void:
	var k = pickup_knowledge_scene.instantiate()
	k.position = pos
	parent.add_child(k)

func spawn_hint(pos: Vector2, parent: Node2D = self) -> void:
	var h = pickup_hint_scene.instantiate()
	h.position = pos
	parent.add_child(h)

func spawn_memory(pos: Vector2, parent: Node2D = self) -> void:
	var m = pickup_memory_scene.instantiate()
	m.position = pos
	parent.add_child(m)

func spawn_quiz_box(pos: Vector2, parent: Node2D = self) -> void:
	if not qblock_scene:
		return
	var qb = qblock_scene.instantiate()
	qb.position = pos
	qb.quiz_triggered.connect(_on_quiz_triggered)
	parent.add_child(qb)

func cleanup_old_chunks() -> void:
	# Keep boss arena alive once spawned!
	if boss_spawned:
		return
	var safe_behind_x := player.global_position.x - 700.0
	if is_instance_valid(active_janitor):
		safe_behind_x = minf(safe_behind_x, active_janitor.global_position.x - 500.0)

	while active_chunks.size() > 0:
		var candidate = active_chunks[0]
		if not is_instance_valid(candidate):
			active_chunks.pop_front()
			continue
		var chunk_end: float = candidate.get_meta("end_x", candidate.global_position.x + 400.0)
		if chunk_end < safe_behind_x:
			var old = active_chunks.pop_front()
			if is_instance_valid(old):
				old.queue_free()
		else:
			break

func update_background_atmosphere(force_instant: bool = false) -> void:
	var lvl: int = clampi(GameSettings.current_level, 1, 10)
	var atmo: Dictionary = LEVEL_ATMOSPHERES.get(lvl, LEVEL_ATMOSPHERES[1])

	var top_sky: Color = atmo.get("top_sky", Color(0.05, 0.08, 0.22))
	var bot_sky: Color = atmo.get("bot_sky", Color(0.10, 0.44, 0.70))
	var dist_color: Color = atmo.get("dist_mod", Color(0.70, 0.85, 1.0))
	var near_color: Color = atmo.get("near_mod", Color(0.90, 0.95, 1.0))
	var cloud_tint: Color = atmo.get("cloud_tint", Color(0.60, 0.75, 0.95, 0.75))
	var sun_vis: float = atmo.get("sun_vis", 0.0)
	var moon_vis: float = atmo.get("moon_vis", 0.0)
	var star_vis: float = atmo.get("star_vis", 0.0)

	# Gentle breathing atmosphere pulsation
	var pulse := sin(distance_traveled * 0.002) * 0.03
	top_sky = top_sky.lightened(pulse)
	bot_sky = bot_sky.lightened(pulse * 0.5)

	if sky_gradient:
		if force_instant:
			sky_gradient.set_color(0, top_sky)
			sky_gradient.set_color(1, bot_sky)
		else:
			var curr_top := sky_gradient.get_color(0)
			var curr_bot := sky_gradient.get_color(1)
			sky_gradient.set_color(0, curr_top.lerp(top_sky, 0.08))
			sky_gradient.set_color(1, curr_bot.lerp(bot_sky, 0.08))

	if force_instant:
		if bg_distant:
			bg_distant.modulate = dist_color
		if bg_near:
			bg_near.modulate = near_color
		if bg_clouds:
			bg_clouds.modulate = cloud_tint
		if bg_stars:
			bg_stars.modulate = Color(1.0, 1.0, 1.0, star_vis)
		if sun_sprite and is_instance_valid(sun_sprite):
			sun_sprite.modulate.a = sun_vis
			sun_sprite.position = Vector2(240, 60)
		if moon_sprite and is_instance_valid(moon_sprite):
			moon_sprite.modulate.a = moon_vis
			moon_sprite.position = Vector2(240, 80)
	else:
		if bg_distant:
			bg_distant.modulate = bg_distant.modulate.lerp(dist_color, 0.08)
		if bg_near:
			bg_near.modulate = bg_near.modulate.lerp(near_color, 0.08)
		if bg_clouds:
			bg_clouds.modulate = bg_clouds.modulate.lerp(cloud_tint, 0.08)
		if bg_stars:
			bg_stars.modulate = bg_stars.modulate.lerp(Color(1.0, 1.0, 1.0, star_vis), 0.08)
		if sun_sprite and is_instance_valid(sun_sprite):
			sun_sprite.modulate.a = lerpf(sun_sprite.modulate.a, sun_vis, 0.08)
		if moon_sprite and is_instance_valid(moon_sprite):
			moon_sprite.modulate.a = lerpf(moon_sprite.modulate.a, moon_vis, 0.08)

func add_shake(amount: float) -> void:
	shake_amount = max(shake_amount, amount)

func _on_quiz_triggered(trigger_node: Node2D) -> void:
	if hud and hud.has_method("show_tech_quiz"):
		hud.show_tech_quiz(trigger_node)

func _on_countdown_finished() -> void:
	is_game_active = true
	if player:
		player.is_controlled = true
	if bgm and not bgm.playing:
		bgm.play()
	# (Chase warning is shown when the janitor actually triggers at distance milestone)

func _on_player_health_changed(health: int) -> void:
	add_shake(7.0)
	if hud and hud.has_method("update_health"):
		hud.update_health(health, player.max_health if player else 3)

func _on_player_died() -> void:
	is_game_active = false
	add_shake(12.0)
	if bgm:
		bgm.stop()
	if hud:
		hud.show_game_over_sequence()

func _on_coin_collected(coin_node: Node2D) -> void:
	if hud:
		hud.add_coin(1)
		hud.show_floating_text("+100", coin_node.global_position, Color(1.0, 0.85, 0.2))

func _on_near_miss(pos: Vector2) -> void:
	add_shake(2.0)
	if hud:
		hud.add_score(50)
		hud.show_floating_text("NEAR MISS! +50", pos, Color(0.2, 0.9, 1.0))

func _on_revive_requested() -> void:
	is_game_active = true
	if is_instance_valid(active_janitor):
		active_janitor.queue_free()
		active_janitor = null

	# Check if reviving from a failed Boss Final Exam:
	var revived_from_boss: bool = false
	if hud and "was_boss_battle_active" in hud and hud.was_boss_battle_active:
		revived_from_boss = true
	elif is_boss_active or (boss_spawned and is_instance_valid(boss_instance) and player and player.global_position.x >= boss_trigger_x - 120.0):
		revived_from_boss = true

	if revived_from_boss and is_instance_valid(boss_instance):
		# Reset boss encounter trigger and UI
		is_boss_active = false
		if hud:
			hud.was_boss_battle_active = false
			hud.is_in_boss_battle = false
			if hud.boss_bar_panel:
				hud.boss_bar_panel.visible = false
			if hud.quiz_modal:
				hud.quiz_modal.visible = false
			if hud.boss_intro_modal:
				hud.boss_intro_modal.visible = false

		# Reset boss health and idle animation
		boss_instance.hp = boss_instance.max_hp
		boss_instance.is_active = false
		if boss_instance.has_method("play_state"):
			boss_instance.play_state("idle")

		# Revive player at a distance away from the boss (on the safe runway 360px back)
		var revive_x: float = boss_trigger_x - 360.0
		if player:
			player.global_position = Vector2(revive_x, 190.0)
			player.velocity = Vector2(player.WALK_SPEED, 0.0)
			GameSettings.lifelines = 3
			player.health = 3
			player.is_dead = false
			player.is_controlled = true
			player.is_sliding = false
			player.is_attacking = false
			player.hurt_timer = 0.0
			player.invulnerable_timer = 1.8
			if player.sprite:
				player.sprite.rotation = 0.0
				player.sprite.scale = Vector2.ONE
				player.sprite.play("run")
			player.emit_signal("health_changed", player.health)

		if hud and hud.has_method("update_health"):
			hud.update_health(3, 3)
		if hud and hud.has_method("show_toast"):
			hud.show_toast("RE-EXAM GRANTED! RETRYING WITH NEW QUESTIONS!")

		if camera:
			camera.position = Vector2(0, -20)
			camera.reset_smoothing()
	else:
		if player:
			player.revive_at_location(player.global_position)
			if hud and hud.has_method("update_health"):
				hud.update_health(player.health, player.max_health)

	if bgm and not bgm.playing:
		bgm.play()

func _on_restart_requested() -> void:
	GameSettings.reset_run_state()
	get_tree().reload_current_scene()


