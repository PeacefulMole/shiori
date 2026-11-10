class_name VNLayoutTarget
extends RefCounted

var id: String
var _node: CanvasItem
var _getter: Callable
var _setter: Callable
var _base_rect: Rect2
var _base_scale := Vector2.ONE

func _init(target_id: String, node: CanvasItem, getter: Callable = Callable(), setter: Callable = Callable()) -> void:
	id = target_id
	_node = node
	_getter = getter
	_setter = setter
	if node is Sprite2D:
		_base_scale = node.scale
	_base_rect = get_rect()

func get_rect() -> Rect2:
	if _getter.is_valid():
		return _getter.call(_node)
	if _node is Control:
		return Rect2(_node.global_position, _node.size)
	if _node is Sprite2D:
		var texture_size := Vector2.ZERO
		if _node.texture is AtlasTexture:
			texture_size = _node.texture.region.size
		elif _node.texture != null:
			texture_size = _node.texture.get_size()
		return Rect2(_node.position, texture_size * _node.scale)
	return Rect2()

func set_rect(rect: Rect2) -> void:
	if _setter.is_valid():
		_setter.call(_node, rect)
		return
	if _node is Control:
		_node.global_position = rect.position
		_node.size = rect.size
	elif _node is Sprite2D:
		_node.position = rect.position
		if _base_rect.size.x != 0 and _base_rect.size.y != 0:
			_node.scale = _base_scale * (rect.size / _base_rect.size)

func move_to(new_position: Vector2) -> void:
	var rect := get_rect()
	rect.position = new_position
	set_rect(rect)

func resize(factor: float) -> void:
	if factor <= 0 or not is_finite(factor):
		return
	if _base_rect.size.x == 0 or _base_rect.size.y == 0:
		return
	var rect := get_rect()
	rect.size = _base_rect.size * factor
	set_rect(rect)

func to_array() -> Array:
	var rect := get_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
