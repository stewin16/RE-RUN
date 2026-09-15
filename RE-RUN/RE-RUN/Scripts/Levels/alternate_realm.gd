extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
@onready var bgm: AudioStreamPlayer = $BGM
@onready var celestial_ring: Sprite2D = get_node_or_null("ParallaxBackground/CelestialLayer/CelestialRing")

var ground_scene: PackedScene = preload("res://Scenes/Objects/apocalypse_ground.tscn")
var p64_scene: PackedScene = preload("res://Scenes/Objects/Platform64.tscn")
var p96_scene: PackedScene = preload("res://Scenes/Objects/Platform96.tscn")
var coin_scene: PackedScene = preload("res://Scenes/Objects/coin.tscn")
var rift_scene: PackedScene = preload("res://Scenes/Objects/dimensional_rift.tscn")

var zombie_scene: PackedScene = preload("res://Scenes/Objects/monster_zombie.tscn")
var skeleton_scene: PackedScene = preload("res://Scenes/Objects/monster_skeleton.tscn")
var witch_scene: PackedScene = preload("res://Scenes/Objects/monster_witch.tscn")

var next_spawn_x: float = 0.0
var active_chunks: Array[Node2D] = []
var distance_traveled: float = 0.0
var is_game_active: bool = true
var rift_spawned: bool = false
const REALM_END_DIST: float = 2600.0

func _ready() -> void:
	if bgm and not bgm.playing:
		bgm.play()

	# Connect Player & HUD signals
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		player.is_controlled = true
		if hud and hud.has_method("update_health"):
			hud.update_health(player.health, player.max_health)

	if hud:
		if hud.has_signal("revive_requested"):
			hud.revive_requested.connect(_on_revive_requested)
		if hud.has_signal("restart_requested"):
			hud.restart_requested.connect(_on_restart_requested)

	# Dimensional reality tear announcement toast (surprise revealed only upon entering!)
	if hud and hud.has_method("show_toast"):
		hud.show_toast("⚠️ REALITY BREACH: THE SHADOW DISTRICT ⚠️")

	# Build realm gauntlet track
	build_initial_realm_track()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_game_active:
		return

	if not player.is_dead:
		var dist_delta := player.velocity.x * delta
		if dist_delta > 0:
			distance_traveled += dist_delta
			if hud:
				hud.add_score(int(dist_delta * 0.25))

	# Pulse celestial ring in the sky
	if celestial_ring:
		celestial_ring.rotation += 0.8 * delta
		var s := 1.8 + sin(Time.get_ticks_msec() * 0.003) * 0.2
		celestial_ring.scale = Vector2(s, s)

	# Spawn chunks ahead
	if player.global_position.x + 550.0 > next_spawn_x:
		spawn_next_realm_chunk()

	# Cleanup past chunks
	cleanup_past_chunks()

func build_initial_realm_track() -> void:
	# Safe starting runway (apocalypse ruins)
	for i in range(3):
		var g = ground_scene.instantiate()
		g.position = Vector2(next_spawn_x + 96.0, 220.0)
		g.set_meta("end_x", next_spawn_x + 192.0)
		add_child(g)
		active_chunks.append(g)
		# Safe starting coins
		if i > 0:
			spawn_coin_arc(Vector2(next_spawn_x + 30.0, 160.0), 4, g)
		next_spawn_x += 192.0

func spawn_next_realm_chunk() -> void:
	if next_spawn_x >= REALM_END_DIST and not rift_spawned:
		spawn_realm_extraction_portal()
		return

	var chunk_root := Node2D.new()
	chunk_root.position = Vector2(next_spawn_x, 0)
	add_child(chunk_root)
	active_chunks.append(chunk_root)

	var step := int(next_spawn_x / 192.0) % 5

	match step:
		0:
			# Pattern 0: The Zombie Horde Pack (Large Group of 4 zombies)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			# 4 Zombies in marching formation
			for i in range(4):
				spawn_zombie(Vector2(240 + i * 35, 196), chunk_root)
			# High vault coin arc over the entire swarm
			spawn_coin_arc(Vector2(210, 130), 6, chunk_root)
			next_spawn_x += 768.0

		1:
			# Pattern 1: Skeleton Rush (Squad of 3 fast skeletons) & Single Sky Witch
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			# Solitary Witch floating high in the sky (y=95)
			spawn_witch(Vector2(320, 95), chunk_root)
			# Squadron of 3 fast skeletons charging on the ground
			for i in range(3):
				spawn_skeleton(Vector2(270 + i * 40, 196), chunk_root)
			# Jump arc coins guiding leap over skeletons under witch
			spawn_coin_arc(Vector2(240, 140), 5, chunk_root)
			next_spawn_x += 768.0

		2:
			# Pattern 2: Sky Twin Coven (Double Witches in Sky) + Ground Undead Patrol
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			# Exactly TWO witches floating high in the sky
			spawn_witch(Vector2(250, 95), chunk_root)
			spawn_witch(Vector2(500, 105), chunk_root)
			# Elevated scaffold platform in middle to jump onto or slide below
			spawn_platform(chunk_root, p96_scene, Vector2(370, 145))
			spawn_coin_arc(Vector2(330, 115), 4, chunk_root)
			# 3 zombies patrolling the ground below
			for i in range(3):
				spawn_zombie(Vector2(220 + i * 40, 196), chunk_root)
			next_spawn_x += 768.0

		3:
			# Pattern 3: Scaffold Escape Route over Skeleton Legion (Large Group of 4)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			# Elevated safety platform
			spawn_platform(chunk_root, p96_scene, Vector2(300, 140))
			spawn_coin_arc(Vector2(260, 110), 4, chunk_root)
			# 4 fast skeletons running beneath the platform
			for i in range(4):
				spawn_skeleton(Vector2(230 + i * 36, 196), chunk_root)
			next_spawn_x += 768.0

		4:
			# Pattern 4: Grand Undead Siege (Mixed Swarm of 3 zombies + 3 skeletons & 1 High Sky Witch)
			spawn_ground(chunk_root, Vector2(96, 220))
			spawn_ground(chunk_root, Vector2(288, 220))
			spawn_ground(chunk_root, Vector2(480, 220))
			spawn_ground(chunk_root, Vector2(672, 220))
			spawn_ground(chunk_root, Vector2(864, 220))
			# Wave 1: 3 zombies
			for i in range(3):
				spawn_zombie(Vector2(200 + i * 35, 196), chunk_root)
			spawn_coin_arc(Vector2(180, 135), 4, chunk_root)
			# Center high sky witch (singular)
			spawn_witch(Vector2(460, 90), chunk_root)
			spawn_platform(chunk_root, p64_scene, Vector2(460, 145))
			# Wave 2: 3 skeletons
			for i in range(3):
				spawn_skeleton(Vector2(620 + i * 35, 196), chunk_root)
			spawn_coin_arc(Vector2(600, 135), 4, chunk_root)
			next_spawn_x += 960.0

	chunk_root.set_meta("end_x", next_spawn_x)

func spawn_realm_extraction_portal() -> void:
	rift_spawned = true
	var chunk_root := Node2D.new()
	chunk_root.position = Vector2(next_spawn_x, 0)
	add_child(chunk_root)
	active_chunks.append(chunk_root)

	# Grand extraction runway
	spawn_ground(chunk_root, Vector2(96, 220))
	spawn_ground(chunk_root, Vector2(288, 220))
	spawn_ground(chunk_root, Vector2(480, 220))
	spawn_ground(chunk_root, Vector2(672, 220))

	# Arc of triumphant golden coins leading to rift
	spawn_coin_arc(Vector2(120, 150), 6, chunk_root)
	spawn_coin_arc(Vector2(320, 130), 6, chunk_root)

	# Dimensional Extraction Rift Portal!
	var rift = rift_scene.instantiate()
	rift.position = Vector2(520, 160)
	rift.rift_entered.connect(_on_realm_escape_complete)
	chunk_root.add_child(rift)

	next_spawn_x += 768.0
	chunk_root.set_meta("end_x", next_spawn_x)

func _on_realm_escape_complete() -> void:
	is_game_active = false
	# Mark Level 5 cleared in GameSettings
	GameSettings.current_level = 6
	# Delay for victory animation then transition back
	await get_tree().create_timer(1.8).timeout
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")

func spawn_ground(parent: Node2D, pos: Vector2) -> void:
	var g = ground_scene.instantiate()
	g.position = pos
	parent.add_child(g)

func spawn_platform(parent: Node2D, scn: PackedScene, pos: Vector2) -> void:
	var p = scn.instantiate()
	p.position = pos
	parent.add_child(p)

func spawn_zombie(pos: Vector2, parent: Node2D) -> void:
	var z = zombie_scene.instantiate()
	z.position = pos
	parent.add_child(z)

func spawn_skeleton(pos: Vector2, parent: Node2D) -> void:
	var s = skeleton_scene.instantiate()
	s.position = pos
	parent.add_child(s)

func spawn_witch(pos: Vector2, parent: Node2D) -> void:
	var w = witch_scene.instantiate()
	w.position = pos
	parent.add_child(w)

func spawn_coin(pos: Vector2, parent: Node2D) -> void:
	var c = coin_scene.instantiate()
	c.position = pos
	if c.has_signal("coin_collected"):
		c.coin_collected.connect(_on_coin_collected)
	parent.add_child(c)

func spawn_coin_arc(start_pos: Vector2, count: int, parent: Node2D) -> void:
	var width_spacing: float = 24.0
	for i in range(count):
		var t := float(i) / float(count - 1) if count > 1 else 0.0
		var h := sin(t * PI) * 28.0
		var coin_pos := start_pos + Vector2(i * width_spacing, -h)
		spawn_coin(coin_pos, parent)

func _on_coin_collected(coin_node: Node2D) -> void:
	if hud:
		hud.add_coin(1)
		hud.show_floating_text("+100", coin_node.global_position, Color(0.9, 0.4, 1.0))

func cleanup_past_chunks() -> void:
	if not is_instance_valid(player):
		return
	var cleanup_boundary: float = player.global_position.x - 380.0
	var to_remove: Array[Node2D] = []
	for chunk in active_chunks:
		if is_instance_valid(chunk):
			var end_x: float = chunk.get_meta("end_x", chunk.position.x + 192.0)
			if end_x < cleanup_boundary:
				to_remove.append(chunk)

	for old in to_remove:
		active_chunks.erase(old)
		if is_instance_valid(old):
			old.queue_free()

func _on_player_health_changed(new_health: int) -> void:
	if camera:
		var tw := create_tween()
		tw.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.05)
		tw.tween_property(camera, "offset", Vector2.ZERO, 0.08)
	if hud and hud.has_method("update_health"):
		hud.update_health(new_health, player.max_health if player else 3)

func _on_player_died() -> void:
	is_game_active = false
	if bgm:
		bgm.stop()
	if hud:
		hud.show_game_over_sequence("VOID CASUALTY")

func _on_revive_requested() -> void:
	is_game_active = true
	if player:
		player.revive_at_location(player.global_position)
		if hud and hud.has_method("update_health"):
			hud.update_health(player.health, player.max_health)
	if bgm and not bgm.playing:
		bgm.play()

func _on_restart_requested() -> void:
	GameSettings.reset_run_state()
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")
