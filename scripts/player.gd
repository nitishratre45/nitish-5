extends CharacterBody3D

const WALK_SPEED := 7.0
const RUN_SPEED := 11.0
const JUMP_VELOCITY := 5.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_input := Vector2.ZERO

func set_controls(value: Vector2) -> void:
    move_input = value

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var direction := Vector3(move_input.x, 0.0, move_input.y)
    var speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
    if direction.length() > 0.1:
        direction = direction.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        look_at(global_position + direction, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED)
    move_and_slide()
