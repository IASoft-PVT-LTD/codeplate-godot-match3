extends Control
## Title screen: logo, a row of bobbing gems, Play, Settings (the shared
## CodePlate settings + credits screen) and a sound toggle.

const SOUND_ON := preload("res://assets/ui/sound_on.png")
const SOUND_OFF := preload("res://assets/ui/sound_off.png")

@onready var _gems: HBoxContainer = %Gems
@onready var _logo: Label = %Logo
@onready var _play: Button = %PlayButton
@onready var _settings: Button = %SettingsButton
@onready var _sound: Button = %SoundButton


## Widest the logo may be, in pixels. Long names shrink to fit.
const LOGO_MAX_WIDTH := 640.0


func _ready() -> void:
	_logo.text = ProjectSettings.get_setting("application/config/name", "MATCH 3").to_upper()
	_fit_logo()
	for i: int in Game.config.max_colors:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(90, 110)
		var gem := TextureRect.new()
		gem.texture = TileSkin.gem(i)
		gem.size = Vector2(84, 84)
		gem.position = Vector2(3, 13)
		gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		holder.add_child(gem)
		_gems.add_child(holder)
		var tw := gem.create_tween().set_loops()
		tw.tween_interval(i * 0.12)
		tw.tween_property(gem, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(gem, "position:y", 13.0, 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(maxf(0.0, (Game.config.max_colors - i) * 0.12))
	_play.pressed.connect(func() -> void:
		Audio.play(&"click")
		Game.goto_level_select())
	_settings.pressed.connect(open_settings)
	_sound.pressed.connect(func() -> void:
		Game.set_sound(not Game.sound_on)
		Audio.apply_sound_setting()
		Audio.play(&"click")
		_update_sound_icon())
	_update_sound_icon()
	Audio.play_music(&"theme")
	_play.grab_focus.call_deferred()


## Opens the settings screen (volumes, fullscreen, reset, credits) on top.
func open_settings() -> CodePlateSettings:
	Audio.play(&"click")
	var s := CodePlateSettings.open(self)
	s.closed.connect(func() -> void:
		_update_sound_icon()
		_settings.grab_focus())
	return s


## Shrinks the logo font until the game name fits on one line.
func _fit_logo() -> void:
	var font := _logo.get_theme_font(&"font")
	var size := _logo.get_theme_font_size(&"font_size")
	while size > 40 and font.get_string_size(_logo.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > LOGO_MAX_WIDTH:
		size -= 4
	_logo.add_theme_font_size_override(&"font_size", size)


func _update_sound_icon() -> void:
	_sound.icon = SOUND_ON if Game.sound_on else SOUND_OFF
