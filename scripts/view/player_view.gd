class_name PlayerView
extends CharacterBody3D
## Spielerfigur (Würfel) mit Third-Person-Kamera. Reine Darstellung und Bewegung,
## Spielregeln entscheidet der GameState.

const GRAVITY := 25.0
const MOUSE_SENSITIVITY := 0.003
const CAMERA_DISTANCE := 7.0
const CAMERA_HEIGHT := 1.6
const PITCH_MIN := -1.2
const PITCH_MAX := 0.3

var speed := 6.0
var controls_enabled := true

var _yaw := 0.0
var _pitch := -0.4
var _pivot: Node3D
var _model: Node3D


func _ready() -> void:
	collision_layer = 2  # Türen/Wände liegen auf Layer 1
	collision_mask = 1

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.6, 0.8)
	shape.shape = box
	shape.position.y = 0.8
	add_child(shape)

	_model = Node3D.new()
	add_child(_model)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.8, 1.6, 0.8)
	body.mesh = body_mesh
	body.position.y = 0.8
	body.material_override = _color_material(Color(0.2, 0.45, 0.9))
	_model.add_child(body)
	var nose := MeshInstance3D.new()  # zeigt die Blickrichtung
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.3, 0.3, 0.3)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 1.2, -0.5)
	nose.material_override = _color_material(Color(1, 0.9, 0.2))
	_model.add_child(nose)

	_pivot = Node3D.new()
	_pivot.position.y = CAMERA_HEIGHT
	add_child(_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = CAMERA_DISTANCE
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	_pivot.add_child(arm)
	var cam := Camera3D.new()
	cam.current = true
	arm.add_child(cam)
	_apply_look()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, PITCH_MIN, PITCH_MAX)
		_apply_look()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Basis(Vector3.UP, _yaw) * Vector3(input.x, 0.0, input.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if dir.length_squared() > 0.001:
		_model.rotation.y = atan2(-dir.x, -dir.z)


func _apply_look() -> void:
	_pivot.rotation = Vector3(_pitch, _yaw, 0.0)


static func _color_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
