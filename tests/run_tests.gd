extends SceneTree

var _total := 0
var _failed := 0

func _init() -> void:
	run.call_deferred()

func run() -> void:
	for file in DirAccess.get_files_at("res://tests"):
		if not file.begins_with("test_") or not file.ends_with(".gd") or file == "run_tests.gd":
			continue
		await _run_file("res://tests/" + file)
	print("---")
	print("%d tests, %d failed" % [_total, _failed])
	quit(1 if _failed > 0 else 0)

func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	if script == null:
		_failed += 1
		print("FAIL ", path, " (load error)")
		return
	var instance = script.new()
	for method in instance.get_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"):
			continue
		_total += 1
		instance.failures.clear()
		await instance.call(method_name)
		if instance.failures.is_empty():
			print("PASS ", path, " :: ", method_name)
		else:
			_failed += 1
			print("FAIL ", path, " :: ", method_name)
			for failure in instance.failures:
				print("   ", failure)
	if instance is Node:
		instance.free()
