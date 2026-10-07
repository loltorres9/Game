class_name GameHud
extends CanvasLayer
## Anzeige: Phase, Restzeit, Runde, besuchte Zellen, Endmeldung.

const PHASE_NAMES := {
	GameState.Phase.OBSERVATION: "Beobachtung – Türen geschlossen",
	GameState.Phase.RUN: "LAUF – Türen offen!",
	GameState.Phase.FINISHED: "Spiel beendet",
}

var _info: Label
var _banner: Label
var _hint: Label


func _ready() -> void:
	_info = _make_label(Control.PRESET_TOP_LEFT, 22)
	_info.offset_left = 16
	_info.offset_top = 12
	_banner = _make_label(Control.PRESET_CENTER, 56)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint = _make_label(Control.PRESET_BOTTOM_LEFT, 16)
	_hint.offset_left = 16
	_hint.offset_top = -40
	_hint.text = "WASD: Laufen   Maus: Kamera   E: Handtür   Esc: Maus freigeben   R: Neustart (nach Spielende)"


func update_view(state: GameState, pid: int) -> void:
	var cells := state.visited_cells(pid)
	_info.text = "Runde %d\n%s\nZeit: %d s\nBesuchte Zellen: %d / %d\n%s" % [
		state.round_number,
		PHASE_NAMES[state.phase],
		ceili(state.time_remaining),
		cells.size(),
		state.balance.cell_count,
		", ".join(cells.map(func(c: int) -> String: return str(c))),
	]
	if state.is_finished():
		if state.winners.has(pid):
			_banner.text = "GEWONNEN!\nAlle Zellen besucht."
		else:
			_banner.text = "AUSGESCHIEDEN\nR für Neustart"
	elif not state.is_alive(pid):
		_banner.text = "AUSGESCHIEDEN"
	else:
		_banner.text = ""


func _make_label(preset: Control.LayoutPreset, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	l.set_anchors_and_offsets_preset(preset)
	return l
