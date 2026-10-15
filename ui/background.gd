extends TextureRect
## The full-screen picture behind every screen. Its file is
## `background_path` in config/game_config.tres, so a new background is a
## config change, not a scene edit.


func _ready() -> void:
	var path := Game.config.background_path
	if ResourceLoader.exists(path):
		texture = load(path)
	else:
		push_error("Background image not found: %s (background_path in config/game_config.tres)" % path)
