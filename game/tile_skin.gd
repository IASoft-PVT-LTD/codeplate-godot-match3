class_name TileSkin
extends RefCounted
## Which texture each tile uses. To reskin, replace the files (same names), or
## change the paths here and in assets.json.

const GEM_PATH := "res://assets/tiles/gem_%d.png"
const COLOR_BOMB_PATH := "res://assets/specials/color_bomb.png"
const OVERLAY_PATHS: Dictionary[Tile.Special, String] = {
	Tile.Special.LINE_H: "res://assets/specials/line_h.png",
	Tile.Special.LINE_V: "res://assets/specials/line_v.png",
	Tile.Special.BOMB: "res://assets/specials/bomb.png",
}

static var _cache: Dictionary[String, Texture2D] = {}


## The main texture for a tile: its gem, or the color bomb.
static func tile_texture(tile: Tile) -> Texture2D:
	if tile.special == Tile.Special.COLOR:
		return texture(COLOR_BOMB_PATH)
	return gem(tile.color)


static func gem(color: int) -> Texture2D:
	return texture(GEM_PATH % color)


## The overlay drawn on top of a special tile, or null.
static func overlay(special: Tile.Special) -> Texture2D:
	if not OVERLAY_PATHS.has(special):
		return null
	return texture(OVERLAY_PATHS[special])


static func tint(color: int) -> Color:
	var tints := Game.config.tile_tints
	if color < 0 or color >= tints.size():
		return Color.WHITE
	return tints[color]


static func texture(path: String) -> Texture2D:
	if not _cache.has(path):
		var t: Texture2D = load(path)
		if t == null:
			push_error("TileSkin: missing texture %s" % path)
		_cache[path] = t
	return _cache[path]
