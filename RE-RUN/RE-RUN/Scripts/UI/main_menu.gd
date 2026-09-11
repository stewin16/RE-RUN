extends Control

@onready var bg_sky: ParallaxLayer = $ParallaxBackground/SkyLayer
@onready var bg_stars: ParallaxLayer = get_node_or_null("ParallaxBackground/StarsLayer")
@onready var bg_clouds: ParallaxLayer = get_node_or_null("ParallaxBackground/CloudsLayer")
@onready var bg_distant: ParallaxLayer = $ParallaxBackground/DistantLayer
@onready var bg_near: ParallaxLayer = $ParallaxBackground/NearLayer
@onready var runner_sprite: AnimatedSprite2D = $ForegroundRunner/AnimatedSprite2D

@onready var title_label: Label = $MenuContainer/VBox/Title
@onready var subtitle_label: Label = $MenuContainer/VBox/Subtitle
@onready var start_btn: Button = $MenuContainer/VBox/Buttons/StartBtn
@onready var char_btn: Button = get_node_or_null("MenuContainer/VBox/Buttons/CharBtn")
@onready var howto_btn: Button = $MenuContainer/VBox/Buttons/HowToBtn
@onready var settings_btn: Button = $MenuContainer/VBox/Buttons/SettingsBtn
@onready var quit_btn: Button = $MenuContainer/VBox/Buttons/QuitBtn

@onready var char_panel: Panel = get_node_or_null("CharPanel")
@onready var char_face_rect: TextureRect = get_node_or_null("CharPanel/VBox/CarouselHBox/ProfileCard/CardContent/FaceRect")
@onready var char_name_label: Label = get_node_or_null("CharPanel/VBox/CarouselHBox/ProfileCard/CardContent/InfoVBox/NameLabel")
@onready var char_major_label: Label = get_node_or_null("CharPanel/VBox/CarouselHBox/ProfileCard/CardContent/InfoVBox/MajorLabel")
@onready var char_desc_label: Label = get_node_or_null("CharPanel/VBox/CarouselHBox/ProfileCard/CardContent/InfoVBox/DescLabel")
@onready var char_status_label: Label = get_node_or_null("CharPanel/VBox/CarouselHBox/ProfileCard/CardContent/InfoVBox/StatusLabel")
@onready var start_run_btn: Button = get_node_or_null("CharPanel/VBox/BottomHBox/StartRunBtn")

@onready var howto_panel: Panel = $HowToPanel
@onready var settings_panel: Panel = $SettingsPanel
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var bgm: AudioStreamPlayer = $BGM

@onready var music_toggle: CheckButton = $SettingsPanel/VBox/MusicRow/MusicToggle
@onready var sfx_toggle: CheckButton = $SettingsPanel/VBox/SFXRow/SFXToggle
@onready var fs_toggle: CheckButton = $SettingsPanel/VBox/FSRow/FSToggle

var ROSTER_KEYS = GameSettings.STUDENT_KEYS
var current_roster_idx: int = 0
var scroll_pos: float = 0.0

func _ready() -> void:
	if char_panel:
		char_panel.visible = false
	howto_panel.visible = false
	settings_panel.visible = false
	
	if runner_sprite:
		runner_sprite.play("run")

	if bgm and not bgm.playing:
		bgm.play()

	update_character_ui()

	# Button entrance animations
	var btns = [start_btn, char_btn, howto_btn, settings_btn, quit_btn]
	for idx in range(btns.size()):
		var b: Button = btns[idx]
		if b:
			b.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_interval(0.08 * idx)
			tween.tween_property(b, "modulate:a", 1.0, 0.15)

func _process(delta: float) -> void:
	scroll_pos += 140.0 * delta
	if bg_sky:
		bg_sky.motion_offset.x = scroll_pos * 0.05
	if bg_stars:
		bg_stars.motion_offset.x = scroll_pos * 0.08
	if bg_clouds:
		bg_clouds.motion_offset.x = scroll_pos * 0.22
	if bg_distant:
		bg_distant.motion_offset.x = scroll_pos * 0.45
	if bg_near:
		bg_near.motion_offset.x = scroll_pos * 0.8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_on_prev_char_pressed()
			return
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_on_next_char_pressed()
			return
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			var non_char_modal = howto_panel.visible or settings_panel.visible
			if not non_char_modal:
				_on_start_btn_pressed()
				return
		elif event.keycode == KEY_ESCAPE:
			if char_panel and char_panel.visible:
				_on_close_char_pressed()
			elif howto_panel.visible:
				_on_close_howto_pressed()
			elif settings_panel.visible:
				_on_close_settings_pressed()

func update_character_ui() -> void:
	var char_info = GameSettings.get_current_character()
	var char_key = char_info.get("id", "student_m_a")
	current_roster_idx = ROSTER_KEYS.find(char_key)
	if current_roster_idx == -1:
		current_roster_idx = 0
	
	if char_btn:
		char_btn.text = "RUNNER: %s" % char_info.get("name", "LEO").to_upper()
	
	if char_face_rect:
		var f_tex = load(char_info.get("face", ""))
		if f_tex:
			char_face_rect.texture = f_tex
	if char_name_label:
		char_name_label.text = char_info.get("name", "").to_upper()
	if char_major_label:
		char_major_label.text = char_info.get("major", "")
	if char_desc_label:
		char_desc_label.text = char_info.get("desc", "")
	if char_status_label:
		char_status_label.text = "★ STUDENT %d / 22 (READY TO RUN) ★" % (current_roster_idx + 1)
	if start_run_btn:
		start_run_btn.text = "START RUN AS %s" % char_info.get("name", "").to_upper()

	# Update live running preview sprite on main menu
	var sprite_path: String = char_info.get("sprite", "res://Assets/Player/runner_student_m_a.png")
	var tex: Texture2D = load(sprite_path)
	if tex and runner_sprite and runner_sprite.sprite_frames:
		var sf: SpriteFrames = runner_sprite.sprite_frames.duplicate(true)
		for f_idx in range(sf.get_frame_count("run")):
			var old_tex = sf.get_frame_texture("run", f_idx)
			if old_tex is AtlasTexture:
				var new_tex := AtlasTexture.new()
				new_tex.atlas = tex
				new_tex.region = old_tex.region
				sf.set_frame("run", f_idx, new_tex)
		runner_sprite.sprite_frames = sf
		runner_sprite.play("run")

func _on_prev_char_pressed() -> void:
	play_click()
	current_roster_idx = (current_roster_idx - 1 + ROSTER_KEYS.size()) % ROSTER_KEYS.size()
	GameSettings.selected_character = ROSTER_KEYS[current_roster_idx]
	update_character_ui()

func _on_next_char_pressed() -> void:
	play_click()
	current_roster_idx = (current_roster_idx + 1) % ROSTER_KEYS.size()
	GameSettings.selected_character = ROSTER_KEYS[current_roster_idx]
	update_character_ui()

func _on_select_char_key(char_key: String) -> void:
	play_click()
	GameSettings.selected_character = char_key
	update_character_ui()

func _on_btn_hover(_btn: Button) -> void:
	play_click()

func play_click() -> void:
	if click_sfx:
		click_sfx.play()

func _on_start_btn_pressed() -> void:
	play_click()
	var tween := create_tween()
	tween.tween_property(start_btn, "scale", Vector2(1.1, 0.8), 0.08)
	tween.tween_property(start_btn, "scale", Vector2.ONE, 0.08)
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")

func _on_char_btn_pressed() -> void:
	play_click()
	if char_panel:
		char_panel.visible = true
	howto_panel.visible = false
	settings_panel.visible = false
	update_character_ui()

func _on_close_char_pressed() -> void:
	play_click()
	if char_panel:
		char_panel.visible = false

func _on_howto_btn_pressed() -> void:
	play_click()
	howto_panel.visible = true
	settings_panel.visible = false
	if char_panel:
		char_panel.visible = false

func _on_settings_btn_pressed() -> void:
	play_click()
	settings_panel.visible = true
	howto_panel.visible = false
	if char_panel:
		char_panel.visible = false

func _on_quit_btn_pressed() -> void:
	play_click()
	get_tree().quit()

func _on_close_howto_pressed() -> void:
	play_click()
	howto_panel.visible = false

func _on_close_settings_pressed() -> void:
	play_click()
	settings_panel.visible = false

func _on_music_toggled(button_pressed: bool) -> void:
	play_click()
	if bgm:
		bgm.stream_paused = not button_pressed

func _on_sfx_toggled(button_pressed: bool) -> void:
	play_click()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not button_pressed)

func _on_fs_toggled(button_pressed: bool) -> void:
	play_click()
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
