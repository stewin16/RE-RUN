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
var warn_scene: PackedScene = preload("res://Scenes/Objects/warning_marker.tscn")
var coin_scene: PackedScene = preload("res://Scenes/Objects/coin.tscn")
var terminal_scene: PackedScene = preload("res://Scenes/Objects/tech_terminal.tscn")
var qblock_scene: PackedScene = preload("res://Scenes/Objects/question_block.tscn")

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

# Boss encounter variables
var boss_spawned: bool = false
var is_boss_active: bool = false
var boss_trigger_x: float = 0.0
var boss_instance: CharacterBody2D = null
const BOSS_ENCOUNTER_DIST: float = 1100.0

const DAY_NIGHT_CYCLE_LEN := 1600.0

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
		bg_sky.modulate = Color.WHITE

	# Connect player signals
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		player.is_controlled = true

	# Connect HUD signals
	if hud:
		hud.countdown_finished.connect(_on_countdown_finished)
		hud.restart_requested.connect(_on_restart_requested)
		hud.revive_requested.connect(_on_revive_requested)

	# Set initial Dawn / Early Morning atmosphere immediately
	update_background_atmosphere(true)

	# Build initial safe runway with introductory power-ups
	build_initial_track()

	# Start countdown overlay
	if hud:
		hud.start_countdown()

func build_initial_track() -> void:
	while next_spawn_x < 700.0:
		var g = ground_scene.instantiate()
		g.position = Vector2(next_spawn_x + 96.0, 220.0)
		add_child(g)
		active_chunks.append(g)
		
		# Place starter tutorial items
		if next_spawn_x == 0.0:
			spawn_coin_arc(Vector2(next_spawn_x + 60.0, 165.0), 3)
		elif next_spawn_x == 192.0:
			spawn_coin_arc(Vector2(next_spawn_x + 30.0, 160.0), 4)
		elif next_spawn_x == 384.0:
			# Mario-style Question Block at x=480
			var qb = qblock_scene.instantiate()
			qb.position = Vector2(next_spawn_x + 96.0, 155.0)
			qb.quiz_triggered.connect(_on_quiz_triggered)
			add_child(qb)
			active_chunks.append(qb)
			spawn_coin(Vector2(next_spawn_x + 150.0, 185.0))
		
		next_spawn_x += 192.0

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

		# Gradual speed increase with notification
		if distance_traveled >= next_speedup_dist and player.SPEED < 420.0:
			player.SPEED += 25.0
			next_speedup_dist += 550.0
			add_shake(3.0)
			if speedup_sfx:
				speedup_sfx.play()
			if hud:
				hud.show_speed_up()

		# Day / Night background cycle & Sun / Moon celestial motion
		update_background_atmosphere()

func spawn_next_chunk() -> void:
	# Check if it's time for the Final Exam Boss
	if distance_traveled >= BOSS_ENCOUNTER_DIST and not boss_spawned:
		spawn_boss_arena()
		return

	if boss_spawned:
		# Just extend flat arena ground
		var g = ground_scene.instantiate()
		g.position = Vector2(next_spawn_x + 96.0, 220.0)
		add_child(g)
		active_chunks.append(g)
		next_spawn_x += 192.0
		return

	var chunk_type := randi() % 7
	var chunk_root := Node2D.new()
	chunk_root.position = Vector2(next_spawn_x, 0)
	add_child(chunk_root)
	active_chunks.append(chunk_root)

	match chunk_type:
		0:
			# Type 0: Flat sprint with Traffic Barrier & Coin Trail
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			var barrier = barrier_scene.instantiate()
			barrier.position = Vector2(192, 196)
			barrier.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(barrier)
			spawn_coin_arc(Vector2(60, 160), 4, chunk_root)
			spawn_coin_arc(Vector2(240, 170), 3, chunk_root)
			next_spawn_x += 384.0

		1:
			# Type 1: Overhead Pipe requiring SLIDE! + Coin Trail
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			var warn = warn_scene.instantiate()
			warn.position = Vector2(100, 150)
			chunk_root.add_child(warn)
			var pipe = pipe_scene.instantiate()
			pipe.position = Vector2(220, 196)
			pipe.near_miss_triggered.connect(_on_near_miss)
			chunk_root.add_child(pipe)
			for i in range(4):
				spawn_coin(Vector2(160 + i * 35, 205), chunk_root)
			spawn_coin(Vector2(320, 185), chunk_root)
			next_spawn_x += 384.0

		2:
			# Type 2: Platform Leap over Hazard Spike Pit + Coins on upper ledge
			spawn_ground(chunk_root, Vector2(192, 255))
			var spk1 = spikes_scene.instantiate()
			spk1.position = Vector2(140, 231)
			chunk_root.add_child(spk1)
			var spk2 = spikes_scene.instantiate()
			spk2.position = Vector2(220, 231)
			chunk_root.add_child(spk2)
			spawn_platform(chunk_root, p64_scene, Vector2(100, 165))
			spawn_platform(chunk_root, p96_scene, Vector2(260, 140))
			spawn_coin_arc(Vector2(100, 130), 3, chunk_root)
			spawn_coin_arc(Vector2(250, 105), 3, chunk_root)
			next_spawn_x += 384.0

		3:
			# Type 3: Oscillating Moving Platform over City Gap
			var mov = movplat_scene.instantiate()
			mov.position = Vector2(120, 160)
			mov.move_offset = Vector2(140, 0)
			mov.duration = 2.2
			chunk_root.add_child(mov)
			spawn_platform(chunk_root, p96_scene, Vector2(340, 150))
			spawn_coin_arc(Vector2(140, 100), 5, chunk_root)
			spawn_coin_arc(Vector2(320, 115), 3, chunk_root)
			next_spawn_x += 440.0

		4:
			# Type 4: Staggered Triple Barrier Rush with Arc Coins
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			for b_idx in [140, 280, 420]:
				var b = barrier_scene.instantiate()
				b.position = Vector2(b_idx, 196)
				b.near_miss_triggered.connect(_on_near_miss)
				chunk_root.add_child(b)
				spawn_coin(Vector2(b_idx, 130), chunk_root)
			spawn_coin_arc(Vector2(320, 175), 3, chunk_root)
			next_spawn_x += 576.0

		5:
			# Type 5: Mario-style Question Block Bump Station
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			var qb = qblock_scene.instantiate()
			qb.position = Vector2(192, 155)
			qb.quiz_triggered.connect(_on_quiz_triggered)
			chunk_root.add_child(qb)
			spawn_coin(Vector2(140, 185), chunk_root)
			spawn_coin(Vector2(244, 185), chunk_root)
			spawn_coin_arc(Vector2(270, 160), 3, chunk_root)
			next_spawn_x += 384.0

		6:
			# Type 6: Mario-Style Question Block with Coin Arcs
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			var qb = qblock_scene.instantiate()
			qb.position = Vector2(192, 155)
			qb.quiz_triggered.connect(_on_quiz_triggered)
			chunk_root.add_child(qb)
			spawn_coin_arc(Vector2(60, 150), 4, chunk_root)
			spawn_coin_arc(Vector2(260, 160), 3, chunk_root)
			next_spawn_x += 384.0

func spawn_boss_arena() -> void:
	boss_spawned = true
	var arena_root := Node2D.new()
	arena_root.position = Vector2(next_spawn_x, 0)
	add_child(arena_root)
	active_chunks.append(arena_root)

	# Build flat ground for the examination arena
	for i in range(4):
		spawn_ground(arena_root, Vector2(96 + i * 192, 220))

	var teacher_info: Dictionary = GameSettings.get_current_teacher()

	# Spawn Teacher Boss for current level right in front of player
	boss_instance = teacher_boss_scene.instantiate()
	boss_instance.position = Vector2(340, 180)
	boss_instance.z_index = 5
	arena_root.add_child(boss_instance)

	boss_trigger_x = next_spawn_x + 160.0
	next_spawn_x += 768.0

func spawn_ground(parent: Node2D, pos: Vector2) -> void:
	var g = ground_scene.instantiate()
	g.position = pos
	parent.add_child(g)

func spawn_platform(parent: Node2D, scn: PackedScene, pos: Vector2) -> void:
	var p = scn.instantiate()
	p.position = pos
	parent.add_child(p)

func spawn_coin(pos: Vector2, parent: Node2D = self) -> void:
	var c = coin_scene.instantiate()
	c.position = pos
	c.collected.connect(_on_coin_collected.bind(c))
	parent.add_child(c)

func spawn_coin_arc(start_pos: Vector2, count: int, parent: Node2D = self) -> void:
	for i in range(count):
		var arc_y = -sin(float(i) / float(count - 1) * PI) * 35.0
		var c_pos = start_pos + Vector2(i * 30.0, arc_y)
		spawn_coin(c_pos, parent)

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

func cleanup_old_chunks() -> void:
	# Keep boss arena alive once spawned!
	if boss_spawned:
		return
	var remove_cutoff := player.global_position.x - 700.0
	while active_chunks.size() > 0 and active_chunks[0].global_position.x < remove_cutoff:
		var old = active_chunks.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func update_background_atmosphere(force_instant: bool = false) -> void:
	# Continuous cyclic phase from 0.0 to 1.0 (Dawn/Morning -> Noon -> Sunset -> Midnight -> Dawn)
	var phase := fmod(distance_traveled, DAY_NIGHT_CYCLE_LEN) / DAY_NIGHT_CYCLE_LEN
	var top_sky: Color
	var bot_sky: Color
	var dist_color: Color
	var near_color: Color

	if phase < 0.25:
		# Early Morning / Dawn: Rich deep blue fading into warm glowing sunrise orange!
		var t := phase / 0.25
		top_sky = Color(0.12, 0.42, 0.85).lerp(Color(0.20, 0.60, 1.0), t)
		bot_sky = Color(1.0, 0.55, 0.16).lerp(Color(0.65, 0.85, 1.0), t)
		dist_color = Color(0.85, 0.50, 0.40).lerp(Color(0.80, 0.88, 1.0), t)
		near_color = Color(0.95, 0.65, 0.50).lerp(Color(1.0, 1.0, 1.0), t)
	elif phase < 0.50:
		# Noon / Day -> Afternoon: crisp blue sky
		var t := (phase - 0.25) / 0.25
		top_sky = Color(0.20, 0.60, 1.0).lerp(Color(0.25, 0.15, 0.45), t)
		bot_sky = Color(0.65, 0.85, 1.0).lerp(Color(0.98, 0.40, 0.20), t)
		dist_color = Color(0.80, 0.88, 1.0).lerp(Color(0.85, 0.40, 0.50), t)
		near_color = Color(1.0, 1.0, 1.0).lerp(Color(0.90, 0.50, 0.45), t)
	elif phase < 0.75:
		# Sunset -> Midnight: dusk orange fading into dark starry night
		var t := (phase - 0.50) / 0.25
		top_sky = Color(0.25, 0.15, 0.45).lerp(Color(0.04, 0.04, 0.12), t)
		bot_sky = Color(0.98, 0.40, 0.20).lerp(Color(0.12, 0.08, 0.22), t)
		dist_color = Color(0.85, 0.40, 0.50).lerp(Color(0.25, 0.30, 0.55), t)
		near_color = Color(0.90, 0.50, 0.45).lerp(Color(0.35, 0.40, 0.65), t)
	else:
		# Midnight -> Morning: dark starry night transitioning into sunrise
		var t := (phase - 0.75) / 0.25
		top_sky = Color(0.04, 0.04, 0.12).lerp(Color(0.12, 0.42, 0.85), t)
		bot_sky = Color(0.12, 0.08, 0.22).lerp(Color(1.0, 0.55, 0.16), t)
		dist_color = Color(0.25, 0.30, 0.55).lerp(Color(0.85, 0.50, 0.40), t)
		near_color = Color(0.35, 0.40, 0.65).lerp(Color(0.95, 0.65, 0.50), t)

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
	else:
		if bg_distant:
			bg_distant.modulate = bg_distant.modulate.lerp(dist_color, 0.08)
		if bg_near:
			bg_near.modulate = bg_near.modulate.lerp(near_color, 0.08)

	# Dynamic Sun & Moon physical rise and set along celestial arc
	var sun_angle := phase * TAU
	var moon_angle := (phase + 0.5) * TAU

	var sun_vis := 0.0
	if sun_sprite and is_instance_valid(sun_sprite):
		var sun_x := 240.0 - cos(sun_angle) * 190.0
		var sun_y := 160.0 - sin(sun_angle) * 120.0
		sun_sprite.position = Vector2(sun_x, sun_y)
		sun_vis = clampf((sin(sun_angle) + 0.15) / 0.35, 0.0, 1.0)
		sun_sprite.modulate.a = sun_vis

	var moon_vis := 0.0
	if moon_sprite and is_instance_valid(moon_sprite):
		var moon_x := 240.0 - cos(moon_angle) * 190.0
		var moon_y := 160.0 - sin(moon_angle) * 120.0
		moon_sprite.position = Vector2(moon_x, moon_y)
		moon_vis = clampf((sin(moon_angle) + 0.15) / 0.35, 0.0, 1.0)
		moon_sprite.modulate.a = moon_vis

	# Stars layer: crisp white and cyan pixel stars, twinkling bright during dusk, night, and dawn!
	if bg_stars:
		var star_vis := 0.0
		if moon_vis > 0.05:
			star_vis = clampf(moon_vis * 1.3, 0.25, 1.0)
		elif sun_vis < 0.6:
			star_vis = clampf(1.0 - (sun_vis * 1.6), 0.0, 0.8)
		bg_stars.modulate = Color(1.0, 1.0, 1.0, star_vis)

	# Clouds layer: genuine pixel art clouds tinted by atmospheric light
	if bg_clouds:
		var cloud_tint: Color
		if phase < 0.25: # Dawn
			cloud_tint = Color(1.0, 0.85, 0.78, 0.85)
		elif phase < 0.50: # Noon
			cloud_tint = Color(1.0, 1.0, 1.0, 0.90)
		elif phase < 0.75: # Sunset
			cloud_tint = Color(1.0, 0.70, 0.65, 0.85)
		else: # Night moonlit
			cloud_tint = Color(0.60, 0.65, 0.90, 0.65)
		bg_clouds.modulate = bg_clouds.modulate.lerp(cloud_tint, 0.08)

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

func _on_player_health_changed(health: int) -> void:
	add_shake(7.0)

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
		hud.show_floating_text("+100", coin_node.global_position)

func _on_near_miss(pos: Vector2) -> void:
	add_shake(2.0)
	if hud:
		hud.add_score(50)
		hud.show_floating_text("NEAR MISS! +50", pos, Color(0.2, 0.9, 1.0))

func _on_revive_requested() -> void:
	is_game_active = true
	if player:
		player.revive_at_location(player.global_position)
	if bgm and not bgm.playing:
		bgm.play()

func _on_restart_requested() -> void:
	GameSettings.reset_run_state()
	get_tree().reload_current_scene()
