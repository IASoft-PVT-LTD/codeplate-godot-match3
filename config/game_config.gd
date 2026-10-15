class_name GameConfig
extends Resource
## Every gameplay, scoring and game-feel number lives here. Change values in
## config/game_config.tres; code reads them through `Game.config`.

@export_group("Screen")
## "portrait" (720x1280: HUD on top, board below) or "landscape" (1280x720:
## HUD in a side panel on the right, board on the left). Set the matching
## window size in project.godot too: docs/recipes/change-screen-shape.md.
@export_enum("portrait", "landscape") var layout: String = "portrait"
## The picture behind every screen (ui/background.gd scales it to cover the
## view). Any image Godot imports works: PNG, JPEG, WebP. List it in assets.json.
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var background_path: String = "res://assets/bg/background.png"

@export_group("Board")
## Board cell size in pixels. Tile art is scaled to fit whatever its size.
@export var cell_size: float = 80.0
## How much of a cell the tile art covers (1.0 = edge to edge).
@export_range(0.5, 1.0) var tile_fill: float = 0.92
## Largest number of tile colors a level may use (needs that many gem textures).
@export var max_colors: int = 6
## Bomb blast radius in cells (1 = 3x3). Two bombs swapped together add 1.
@export var bomb_radius: int = 1

@export_group("Input")
## How far, in cells, a drag must travel to count as a swipe.
@export var swipe_threshold: float = 0.35
## Seconds of no input before a hint pulses.
@export var hint_delay: float = 5.0

@export_group("Animation")
## Multiplies every animation's speed. Checks set it very high to run fast.
@export var animation_speed: float = 1.0
@export var swap_time: float = 0.16
@export var clear_time: float = 0.2
@export var fall_time_per_cell: float = 0.055
@export var fall_min_time: float = 0.14
@export var spawn_pop_time: float = 0.18
@export var cascade_pause: float = 0.06
@export var shuffle_time: float = 0.45

@export_group("Scoring")
@export var points_per_tile: int = 10
## Each cascade level adds this much to the multiplier (0.5 = 1x, 1.5x, 2x...).
@export var cascade_multiplier_step: float = 0.5
@export var special_create_bonus: int = 50
## Bonus points per unused move when a level is won.
@export var points_per_move_left: int = 100

@export_group("Feel")
@export var shake_line: float = 6.0
@export var shake_bomb: float = 12.0
@export var shake_color: float = 16.0
## How quickly a shake fades (higher = shorter).
@export var shake_decay: float = 6.0
## Sound pitch rises by this much with every cascade level.
@export var pitch_per_cascade: float = 0.07
## Particle burst size per cleared tile.
@export var particles_per_tile: int = 10

@export_group("Colors")
## One tint per tile color, used for particles and goal icons. Keep it in
## step with the gem textures (assets/tiles/gem_<n>.png).
@export var tile_tints: PackedColorArray = PackedColorArray([
	Color("#ff4d6d"), Color("#3a86ff"), Color("#2ec27e"),
	Color("#ffbe0b"), Color("#9b5de5"), Color("#ff8c42"),
])


## Seconds for an animation, after applying `animation_speed`.
func t(seconds: float) -> float:
	return seconds / maxf(animation_speed, 0.001)
