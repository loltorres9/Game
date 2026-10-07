extends Control
## Platzhalter-Startszene (M0). Lädt die Balancing-Konfiguration und zeigt eine Kurzinfo.

const BALANCE_PATH := "res://config/balance.tres"


func _ready() -> void:
	var balance := load(BALANCE_PATH) as BalanceConfig
	if balance == null:
		push_error("Balancing-Konfiguration konnte nicht geladen werden: %s" % BALANCE_PATH)
		return
	$Label.text = "Zellenlauf – %d Zellen, %d Spieler" % [balance.cell_count, balance.player_count]
