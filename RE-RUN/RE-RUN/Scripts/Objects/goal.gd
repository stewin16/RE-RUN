extends Area2D

signal level_completed

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_reached: bool = false

func _on_body_entered(body: Node2D) -> void:
	if is_reached:
		return
	if body.is_in_group("player"):
		is_reached = true
		if sfx:
			sfx.play()
		emit_signal("level_completed")
