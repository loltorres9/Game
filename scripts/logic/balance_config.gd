class_name BalanceConfig
extends Resource
## Zentrale Balancing-Werte. Keine Magic Numbers im Code: alles hier, Werte in res://config/balance.tres.
## Zeiten in Sekunden, Geschwindigkeiten in Metern pro Sekunde.

@export_group("Spiel")
@export var cell_count: int = 12
@export var player_count: int = 8
@export var start_cell_counts_as_visited: bool = true

@export_group("Arena (Meter)")
@export var cell_width: float = 10.0
@export var cell_front_depth: float = 7.0
@export var cell_back_depth: float = 7.0
@export var yard_depth: float = 22.0
@export var wall_height: float = 4.0
@export var door_width: float = 3.0

@export_group("Runde")
@export var observation_duration: float = 8.0
@export var run_duration: float = 25.0

@export_group("Tiere pro Runde")
@export var initial_dangerous_animals: int = 2
@export var initial_disruptor_animals: int = 2
@export var extra_animals_every_n_rounds: int = 3
@export var extra_animals_per_step: int = 1

@export_group("Spieler")
@export var player_speed: float = 6.0
@export var interact_range: float = 2.5
@export var inventory_slots: int = 2
@export var allow_early_door_break: bool = true

@export_group("Effekte")
@export var effect_max_rounds: int = 2
@export var slow_speed_factor: float = 0.6
@export var stink_detection_factor: float = 1.5

## Werte pro Tierart. Schlüssel = Tier-ID.
## speed: Geschwindigkeit; sight_range: Sichtweite; aggressiveness: 0..1
## delay_player_trapped_*: Verzögerung eines im Hinterraum versteckten Spielers (Tier im Vorderraum)
## delay_self_trapped_*: Verzögerung des Tieres, wenn es selbst im Hinterraum eingesperrt war
## Alle Zahlen sind Startwerte zum Ausprobieren, keine Vorgaben aus dem Plan.
@export var dangerous_animals: Dictionary = {}
@export var disruptor_animals: Dictionary = {}
