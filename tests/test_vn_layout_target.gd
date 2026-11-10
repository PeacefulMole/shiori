extends TestBase

const VNLayoutTarget := preload("res://addons/shiori/scripts/vn_layout_target.gd")

func test_control_move_and_proportional_resize() -> void:
	var control := Control.new()
	control.position = Vector2(10, 20)
	control.size = Vector2(100, 50)
	var target := VNLayoutTarget.new("panel", control)
	target.move_to(Vector2(30, 40))
	eq(target.get_rect(), Rect2(30, 40, 100, 50), "control moved")
	target.resize(1.5)
	eq(target.get_rect(), Rect2(30, 40, 150, 75), "control resized proportionally")
	eq(target.to_array(), [30.0, 40.0, 150.0, 75.0], "rectangle serialized")
	control.free()

func test_sprite_resize_uses_original_scale() -> void:
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.position = Vector2(10, 20)
	sprite.scale = Vector2(2, 1.5)
	var target := VNLayoutTarget.new("sprite", sprite)
	eq(target.get_rect(), Rect2(10, 20, 128, 48), "initial sprite rect")
	target.resize(1.5)
	eq(target.get_rect(), Rect2(10, 20, 192, 72), "sprite resized proportionally")
	eq(sprite.scale, Vector2(3, 2.25), "sprite scale retained")
	sprite.free()

func test_custom_geometry_callbacks() -> void:
	var control := Control.new()
	control.position = Vector2(10, 20)
	control.size = Vector2(100, 50)
	var getter := func(node: CanvasItem) -> Rect2:
		return Rect2(node.position * 2, node.size)
	var setter := func(node: CanvasItem, rect: Rect2) -> void:
		node.position = rect.position / 2
		node.size = rect.size
	var target := VNLayoutTarget.new("custom", control, getter, setter)
	eq(target.get_rect(), Rect2(20, 40, 100, 50), "custom getter")
	target.move_to(Vector2(50, 60))
	eq(control.position, Vector2(25, 30), "custom setter")
	control.free()

func test_zero_sized_target_ignores_resize() -> void:
	var control := Control.new()
	control.size = Vector2(0, 50)
	var target := VNLayoutTarget.new("empty", control)
	target.resize(2)
	eq(target.get_rect(), Rect2(0, 0, 0, 50), "zero-sized rect is unchanged")
	check(target.get_rect().size.is_finite(), "zero-sized rect stays finite")
	control.free()


func test_texture_button_resize_updates_minimum_size() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(32, 72)
	button.size = Vector2(32, 72)
	tree.root.add_child(button)
	var target := VNLayoutTarget.new("button", button)
	target.set_rect(Rect2(100, 110, 40, 60))
	await tree.process_frame
	eq(button.custom_minimum_size, Vector2(40, 60), "requested minimum size")
	eq(button.get_rect(), Rect2(100, 110, 40, 60), "minimum size does not override the requested rect")
	button.free()
	await tree.process_frame


func test_centered_sprite_rect_includes_offset_and_parent_transform() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node2D.new()
	parent.position = Vector2(50, 40)
	parent.scale = Vector2.ONE * 2
	tree.root.add_child(parent)
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.position = Vector2(100, 100)
	sprite.scale = Vector2(2, 1.5)
	sprite.offset = Vector2(4, 6)
	parent.add_child(sprite)
	var target := VNLayoutTarget.new("sprite", sprite)
	eq(target.get_rect(), Rect2(138, 210, 256, 96), "centered offset and parent transform")
	target.move_to(Vector2(20, 30))
	eq(target.get_rect(), Rect2(20, 30, 256, 96), "centered sprite moved by visual rect")
	eq(sprite.global_position, Vector2(132, 60), "node origin follows visual rect")
	target.resize(1.5)
	eq(target.get_rect(), Rect2(20, 30, 384, 144), "centered sprite resized by visual rect")
	eq(sprite.scale, Vector2(3, 2.25), "local scale retained")
	parent.free()
	await tree.process_frame
