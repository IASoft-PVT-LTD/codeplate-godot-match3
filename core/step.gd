class_name Step
extends RefCounted
## One thing that happened while resolving a move, in order. The resolver
## changes the board right away and records Steps; the view replays them as
## animations. Only the fields for the step's `type` are set.

enum Type {
	SWAP, ## Tiles at `a` and `b` swapped places.
	SWAP_BACK, ## The swap at `a`/`b` made no match, so the tiles swapped back.
	CLEAR, ## Tiles were cleared (`cleared`), specials fired (`activations`), new specials appeared (`created`).
	FALL, ## Tiles fell into gaps and new tiles dropped in (`falls`).
	SHUFFLE, ## No moves were left, so tiles moved to new cells (`positions`).
}


class Cleared:
	extends RefCounted
	var tile: Tile
	var cell: Vector2i


class Activation:
	extends RefCounted
	var special: Tile.Special
	var cell: Vector2i
	## The color a color bomb targeted (Tile.NO_COLOR for "everything").
	var color: int = Tile.NO_COLOR
	## Every cell this activation hit.
	var cells: Array[Vector2i] = []


class Created:
	extends RefCounted
	var tile: Tile
	var cell: Vector2i


class Fall:
	extends RefCounted
	var tile: Tile
	## For a new tile, `from.y` is negative: it drops in from above the board.
	var from: Vector2i
	var to: Vector2i
	var is_new: bool


var type: Type
var a: Vector2i
var b: Vector2i
## SWAP / SWAP_BACK: the tile that started at `a` and the one that started at `b`.
## (The board has moved on by the time the view plays the step, so use these.)
var tile_a: Tile
var tile_b: Tile
## 0 for the clears caused directly by the swap, 1 for the first cascade, and so on.
var cascade: int = 0
var points: int = 0
var cleared: Array[Cleared] = []
var activations: Array[Activation] = []
var created: Array[Created] = []
var falls: Array[Fall] = []
## SHUFFLE: tile id -> new cell.
var positions: Dictionary[int, Vector2i] = {}


static func make(p_type: Type) -> Step:
	var s := Step.new()
	s.type = p_type
	return s
