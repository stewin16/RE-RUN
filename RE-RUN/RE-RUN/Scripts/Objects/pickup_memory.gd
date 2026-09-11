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

func _process(delta: float) -> void:
	if not is_collected and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.006) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player") or body.name == "Player":
		is_collected = true
		emit_signal("collected")
		if sfx:
			sfx.play()

		# Select fact and store into GameSettings learned shards!
		var memory = MEMORY_BANK[randi() % MEMORY_BANK.size()]
		GameSettings.learned_memory_shards.append(memory)

		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_memory_shard_banner"):
			hud.show_memory_shard_banner(memory["fact"])

		var tween := create_tween()
		tween.tween_property(self, "position:y", position.y - 20.0, 0.25)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
