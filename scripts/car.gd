extends CharacterBody3D

const ACCELERATION := 17.0
const MAX_SPEED := 24.0
const TURN_SPEED := 1.8
var speed := 0.0
var move_input := Vector2.ZERO

func set_controls(value: Vector2) -> void:
    move_input = value

func _physics_process(delta: float) -> void:
    var throttle := -move_input.y
    speed = move_toward(speed, throttle * MAX_SPEED, ACCELERATION * delta)
    if abs(speed) > 0.4:
        rotate_y(-move_input.x * TURN_SPEED * delta * sign(speed))
    var forward := -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed
    velocity.y = -0.8
    move_and_slide()
    if is_on_wall():
        speed *= 0.35
