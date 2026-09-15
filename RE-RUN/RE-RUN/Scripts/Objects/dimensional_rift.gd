extends Area2D

signal rift_entered

@onready var sprite: Sprite2D = $Sprite2D
@onready var light_glow: PointLight2D = get_node_or_null("PointLight2D")
@onready var escape_sfx: AudioStreamPlayer2D = $EscapeSFX

var is_activated: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	pulse_time += delta
	if sprite:
		# Rotating & pulsing cosmic dimensional rift effect
		sprite.rotation += 1.8 * delta
		var scale_pulse := 1.5 + sin(pulse_time * 5.0) * 0.15
		sprite.scale = Vector2(scale_pulse, scale_pulse)

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	is_activated = true
	emit_signal("rift_entered")

	if escape_sfx:
		escape_sfx.play()

	# Freeze player controls during extraction
	if "is_controlled" in body:
		body.is_controlled = false
	if "velocity" in body:
		body.velocity = Vector2.ZERO

	# Swirling extraction animation
	if sprite:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "scale", Vector2(4.5, 4.5), 0.6)
		tw.tween_property(sprite, "modulate", Color(2.0, 1.5, 3.0, 1.0), 0.6)
		if body:
			tw.tween_property(body, "global_position", global_position, 0.45)
			tw.tween_property(body, "scale", Vector2.ZERO, 0.55)

	# Notify HUD / Level Manager
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		var root = get_tree().current_scene
		if root:
			hud = root.get_node_or_null("HUD")

	if hud:
		hud.add_score(5000)
		hud.show_floating_text("+5000 SECRET REALM ESCAPE!", global_position + Vector2(0, -50), Color(0.4, 1.0, 0.6))
		if hud.has_method("show_level_complete_sequence"):
			hud.show_level_complete_sequence()
		elif hud.has_method("show_toast"):
			hud.show_toast("🌌 REALITY RESTORED! DIMENSIONAL ESCAPE SUCCESSFUL! 🌌")
