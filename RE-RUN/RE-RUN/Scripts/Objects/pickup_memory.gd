extends Area2D

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false

const MEMORY_BANK = [
	{
		"fact": "The human heart beats around 100,000 times per day!",
		"q": "How many times does the human heart beat per day?",
		"correct": "Around 100,000 times",
		"wrongs": ["Around 10,000 times", "Around 500,000 times", "Around 1,000,000 times"]
	},
	{
		"fact": "Python was named after the Monty Python comedy show, not the snake!",
		"q": "What was the Python programming language named after?",
		"correct": "Monty Python comedy show",
		"wrongs": ["Python snake genus", "Ancient Greek myth", "A secret laboratory"]
	},
	{
		"fact": "The Apollo 11 Lunar Module guidance computer had only 4 Kilobytes of RAM!",
		"q": "How much RAM did the Apollo 11 Lunar Module guidance computer possess?",
		"correct": "4 Kilobytes",
		"wrongs": ["64 Megabytes", "1 Gigabyte", "512 Kilobytes"]
	}
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if not is_collected and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.006) * 3.0

func _on_area_entered(area: Area2D) -> void:
	var p = area.get_parent()
	if p and (p.is_in_group("player") or p.name == "Player"):
		_collect(p)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_collect(body)

func _collect(body: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	emit_signal("collected")
	if sfx:
		sfx.play()

	# Select fact and store into GameSettings learned shards!
	var memory = MEMORY_BANK[randi() % MEMORY_BANK.size()]
	GameSettings.learned_memory_shards.append(memory)
	GameSettings.knowledge_score += 50
	if body.has_method("heal"):
		body.heal(1)

	var hud = get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		if hud.has_method("show_memory_shard_banner"):
			hud.show_memory_shard_banner(memory["fact"])
		if hud.has_method("show_floating_text"):
			hud.show_floating_text("📜 MEMORY RECOVERED! (+50 PTS)", global_position + Vector2(0, -10), Color(0.4, 0.9, 1.0))
		if hud.has_method("update_hud_instant"):
			hud.update_hud_instant()

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 20.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
