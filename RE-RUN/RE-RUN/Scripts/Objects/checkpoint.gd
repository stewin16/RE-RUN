extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_activated: bool = false

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	if body.is_in_group("player"):
		is_activated = true
		sprite.region_rect = Rect2(32, 0, 32, 32)
		if sfx:
			sfx.play()
		if body.has_method("set_checkpoint"):
			body.set_checkpoint(global_position + Vector2(0, -10))
		
		# Feedback pulse
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
