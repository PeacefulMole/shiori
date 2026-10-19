class_name TestBase
extends RefCounted

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func eq(actual: Variant, expected: Variant, label: String = "") -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])
