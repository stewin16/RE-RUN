extends Area2D

signal collected

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if sprite:
		sprite.frame = randi() % 6

func _on_area_entered(area: Area2D) -> void:
	if is_collected:
		return
	var p = area.get_parent()
	if p and (p.is_in_group("player") or p.name == "Player" or p.has_method("take_damage")):
		_on_body_entered(p)

func _process(delta: float) -> void:
	if is_collected:
		return
	if GameSettings.is_magnet_active:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var dist = global_position.distance_to(p.global_position)
			if dist < 240.0:
				var dir = (p.global_position - global_position).normalized()
				global_position += dir * max(320.0, 600.0 - dist) * delta
				if dist < 18.0:
					_on_body_entered(p)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player") or body.name == "Player" or body.has_method("take_damage"):
		is_collected = true
		emit_signal("collected")
		if sfx:
			sfx.play()
		var tween := create_tween()
		tween.tween_property(self, "position:y", position.y - 16.0, 0.18)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
		tween.tween_callback(queue_free)
