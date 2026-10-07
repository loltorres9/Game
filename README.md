# Zellenlauf

Rundenbasiertes 3D-Multiplayer-Spiel in Godot 4 (GDScript). Siehe `PLAN.md` für Regeln und Meilensteine.

## Struktur
- `scenes/` Szenen · `scripts/logic/` Spiellogik (ohne Szenenabhängigkeit) · `scripts/view/` Darstellung
- `config/balance.tres` alle Balancing-Werte · `tests/` Tests

## Tests
`godot --headless --path . --import` (einmalig), dann `godot --headless --path . -s tests/run_tests.gd`

## Steuerung (M1)
WASD laufen · Maus Kamera · E Handtür öffnen/schließen · Esc Maus freigeben · R Neustart nach Spielende
