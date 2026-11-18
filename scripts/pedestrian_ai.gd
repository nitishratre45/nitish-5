extends CharacterBody3D

var walk_speed := 2.0
var destination := Vector3.ZERO
var wait_time := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    _pick_destination()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0

    if wait_time > 0.0:
        wait_time -= delta
        velocity.x = move_toward(velocity.x, 0.0, walk_speed)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed)
    else:
        var offset := destination - global_position
        offset.y = 0.0
        if offset.length() < 1.2:
            wait_time = rng.randf_range(0.5, 2.0)
            _pick_destination()
        else:
            var direction := offset.normalized()
            velocity.x = direction.x * walk_speed
            velocity.z = direction.z * walk_speed
            look_at(global_position + direction, Vector3.UP)
    move_and_slide()

func _pick_destination() -> void:
    destination = global_position + Vector3(rng.randf_range(-12.0, 12.0), 0.0, rng.randf_range(-12.0, 12.0))
