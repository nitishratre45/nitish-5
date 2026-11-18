extends Node3D

var target: Node3D
var chase_speed := 13.0
var active := false

func set_target(value: Node3D) -> void:
    target = value
    active = is_instance_valid(value)
    visible = active

func _process(delta: float) -> void:
    if not active or not is_instance_valid(target):
        return
    var destination := target.global_position
    destination.y = global_position.y
    var direction := destination - global_position
    if direction.length() > 2.5:
        var step := direction.normalized()
        global_position += step * chase_speed * delta
        look_at(global_position + step, Vector3.UP)
