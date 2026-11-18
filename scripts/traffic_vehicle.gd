extends Node3D

var travel_direction := Vector3.FORWARD
var cruise_speed := 9.0
var lane_origin := Vector3.ZERO
var world_limit := 118.0

func configure(start: Vector3, direction: Vector3, speed: float) -> void:
    lane_origin = start
    position = start
    travel_direction = direction.normalized()
    cruise_speed = speed
    if abs(travel_direction.x) > 0.5:
        rotation.y = -PI * 0.5 if travel_direction.x > 0.0 else PI * 0.5

func _process(delta: float) -> void:
    global_position += travel_direction * cruise_speed * delta
    if travel_direction.z > 0.0 and global_position.z > world_limit:
        global_position.z = -world_limit
    elif travel_direction.z < 0.0 and global_position.z < -world_limit:
        global_position.z = world_limit
    elif travel_direction.x > 0.0 and global_position.x > world_limit:
        global_position.x = -world_limit
    elif travel_direction.x < 0.0 and global_position.x < -world_limit:
        global_position.x = world_limit
