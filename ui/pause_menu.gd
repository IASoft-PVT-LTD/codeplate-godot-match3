class_name PauseMenu
extends Control
## Pause overlay. Pauses the SceneTree while open (this node keeps processing).

signal resumed
signal restart_pressed
signal levels_pressed

@onready var _resume: Button = %ResumeButton
@onready var _restart: Button = %RestartButton
@onready var _sound: Button = %SoundButton
@onready var _levels: Button = %LevelsButton


func _ready() -> void:
	_resume.pressed.connect(close)
	_restart.pressed.connect(_leave.bind(restart_pressed))
	_levels.pressed.connect(_leave.bind(levels_pressed))
	_sound.pressed.connect(_toggle_sound)


func open() -> void:
	_update_sound_label()
	visible = true
	get_tree().paused = true
	_resume.grab_focus.call_deferred()


func close() -> void:
	Audio.play(&"click")
	visible = false
	get_tree().paused = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _leave(sig: Signal) -> void:
	Audio.play(&"click")
	get_tree().paused = false
	sig.emit()


func _toggle_sound() -> void:
	Game.set_sound(not Game.sound_on)
	Audio.apply_sound_setting()
	Audio.play(&"click")
	_update_sound_label()


func _update_sound_label() -> void:
	_sound.text = "Sound: On" if Game.sound_on else "Sound: Off"
