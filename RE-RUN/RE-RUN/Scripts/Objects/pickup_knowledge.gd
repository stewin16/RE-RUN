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
	"The QWERTY keyboard layout was created in 1873 to prevent mechanical typewriter jams!",
	"Binary search reduces a 1,000,000-item search to at most 20 comparisons!",
	"Python was named after the Monty Python comedy troupe, not the snake!",
	"The Apollo 11 moon landing guidance computer operated on just 4 Kilobytes of RAM!"
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if not is_collected and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.007) * 2.5

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

	# Empower player with Knowledge & 2X Score boost!
	GameSettings.knowledge_score += 10
	GameSettings.is_multiplier_active = true
	GameSettings.power_up_timer = maxf(GameSettings.power_up_timer, 8.0)
	emit_signal("collected")

	if sfx:
		sfx.play()

	# Trigger HUD Knowledge Toast & Floating Text
	var fact = FACTS[randi() % FACTS.size()]
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		if hud.has_method("show_knowledge_fact"):
			hud.show_knowledge_fact(fact)
		if hud.has_method("show_floating_text"):
			hud.show_floating_text("📘 +10 KNOWLEDGE & 2X BOOST!", global_position + Vector2(0, -10), Color(0.25, 0.95, 1.0))
		if hud.has_method("update_hud_instant"):
			hud.update_hud_instant()

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 20.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
