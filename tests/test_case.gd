class_name TestCase
extends RefCounted
## Minimale Testbasis ohne externe Abhängigkeiten. Testmethoden beginnen mit "test_".
## Läuft über tests/run_tests.gd (headless).

var failures: Array[String] = []
var _current: String = ""
var assertions := 0


func before_each() -> void:
	pass


func assert_true(cond: bool, msg: String = "") -> void:
	assertions += 1
	if not cond:
		failures.append("%s: erwartet true. %s" % [_current, msg])


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s: erwartet %s, erhalten %s. %s" % [_current, str(expected), str(actual), msg])


func assert_not_null(value: Variant, msg: String = "") -> void:
	assertions += 1
	if value == null:
		failures.append("%s: unerwartet null. %s" % [_current, msg])
