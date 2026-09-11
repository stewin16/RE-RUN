extends Area2D

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false

const FACTS = [
	"Honey never spoils — archaeologists found edible 3,000-year-old honey in Egyptian tombs!",
	"The first computer programmer in history was Ada Lovelace in 1843!",
	"The first computer bug was an actual moth found trapped inside the Harvard Mark II in 1947!",
	"Over 90% of the world's currency exists only in digital form on computers!",
	"The QWERTY keyboard layout was created in 1873 to prevent typewriter jam collisions!"
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not is_collected and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.007) * 2.5

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player") or body.name == "Player":
		is_collected = true
		GameSettings.knowledge_score += 10
		emit_signal("collected")
		if sfx:
			sfx.play()

		# Trigger HUD Knowledge Toast
		var fact = FACTS[randi() % FACTS.size()]
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_knowledge_fact"):
			hud.show_knowledge_fact(fact)

		var tween := create_tween()
		tween.tween_property(self, "position:y", position.y - 20.0, 0.25)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
