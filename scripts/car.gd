extends CharacterBody3D

const ACCELERATION := 17.0
const MAX_SPEED := 25.0
const REVERSE_SPEED := 9.0
const TURN_SPEED := 1.9
const BRAKE_STRENGTH := 26.0

var speed := 0.0
var move_input := Vector2.ZERO
var handbrake := false

func set_controls(value: Vector2) -> void:
    move_input = value

func _physics_process(delta: float) -> void:
    var throttle := -move_input.y
    var target_speed := MAX_SPEED if throttle > 0.0 else REVERSE_SPEED
    speed = move_toward(speed, throttle * target_speed, ACCELERATION * delta)

    if Input.is_action_pressed("brake"):
        speed = move_toward(speed, 0.0, BRAKE_STRENGTH * delta)

    if abs(speed) > 0.35:
        rotate_y(-move_input.x * TURN_SPEED * delta * sign(speed))

    var forward := -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed
    velocity.y = -1.0
    move_and_slide()

    if is_on_wall():
        speed *= 0.3
