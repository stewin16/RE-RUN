extends Area2D

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if not is_collected and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.008) * 2.5

func _on_area_entered(area: Area2D) -> void:
	var p = area.get_parent()
	if p and (p.is_in_group("player") or p.name == "Player"):
		_collect(p)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_collect(body)

func _collect(_body: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	GameSettings.hints = min(3, GameSettings.hints + 1)
	emit_signal("collected")
	if sfx:
		sfx.play()

	var hud = get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		if hud.has_method("show_floating_text"):
			hud.show_floating_text("💡 HINT ACQUIRED! (USE 50:50 IN QUIZ)", global_position + Vector2(0, -10), Color(1.0, 0.9, 0.2))
		if hud.has_method("update_hud_instant"):
			hud.update_hud_instant()

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 20.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
