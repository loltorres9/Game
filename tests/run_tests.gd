extends SceneTree
## Aufruf: godot --headless --path . -s tests/run_tests.gd
## Findet alle tests/test_*.gd (außer test_case.gd), führt alle Methoden test_* aus.
## Exit-Code 0 = alle bestanden, 1 = Fehler.

const TEST_DIR := "res://tests"
const BASE_FILE := "test_case.gd"


func _init() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		push_error("Testordner nicht gefunden: %s" % TEST_DIR)
		quit(1)
		return
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != BASE_FILE:
			files.append(f)
	files.sort()
	for f in files:
		var script := load("%s/%s" % [TEST_DIR, f]) as GDScript
		if script == null or not script.can_instantiate():
			printerr("  FAIL  %s: Skript lässt sich nicht laden" % f)
			total += 1
			failed += 1
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var t: TestCase = script.new()
			t.before_each()
			t._current = "%s::%s" % [f, name]
			t.call(name)
			total += 1
			if t.assertions == 0:
				t.failures.append("%s: keine Assertion ausgeführt (Skriptfehler im Test?)" % t._current)
			if t.failures.is_empty():
				print("  OK    ", t._current)
			else:
				failed += 1
				for msg in t.failures:
					printerr("  FAIL  ", msg)
	print("%d Tests, %d fehlgeschlagen" % [total, failed])
	quit(1 if failed > 0 else 0)
