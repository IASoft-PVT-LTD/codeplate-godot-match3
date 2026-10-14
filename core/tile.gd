class_name Tile
extends RefCounted
## One piece on the board. Pure data: the view looks tiles up by `id`.

enum Special {
	NONE,
	LINE_H, ## Clears its whole row when activated.
	LINE_V, ## Clears its whole column when activated.
	BOMB, ## Clears the 3x3 square around it.
	COLOR, ## Colorless. Swapped with a tile, clears every tile of that color.
}

## Color bombs have no color, so they never take part in normal matches.
const NO_COLOR: int = -1

var id: int
var color: int
var special: Special


func _init(p_id: int, p_color: int, p_special: Special = Special.NONE) -> void:
	id = p_id
	color = p_color
	special = p_special


func is_special() -> bool:
	return special != Special.NONE


func is_line() -> bool:
	return special == Special.LINE_H or special == Special.LINE_V


func _to_string() -> String:
	return "Tile#%d(c%d,%s)" % [id, color, Special.keys()[special]]
