extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CAR_SCRIPT = preload("res://scripts/car.gd")
const TRAFFIC_SCRIPT = preload("res://scripts/traffic_vehicle.gd")
const PEDESTRIAN_SCRIPT = preload("res://scripts/pedestrian_ai.gd")
const POLICE_SCRIPT = preload("res://scripts/police_ai.gd")

var player: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D
var info: Label
var driving := false
var collected := 0
var wanted_level := 0
var checkpoints: Array[Area3D] = []
var police_car: Node3D
var save_path := "user://nitish5_save.cfg"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 4518
    _load_progress()
    _build_environment()
    _build_roads()
    _build_city()
    _build_player()
    _build_car()
    _build_traffic()
    _build_pedestrians()
    _build_police()
    _build_checkpoints()
    _build_hud()

func _process(_delta: float) -> void:
    _update_camera()
    _update_hud()

func _physics_process(_delta: float) -> void:
    var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if driving:
        car.call("set_controls", movement)
    else:
        player.call("set_controls", movement)
    if Input.is_action_just_pressed("interact"):
        _toggle_vehicle()
    if Input.is_action_just_pressed("wanted"):
        _toggle_wanted_level()

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.68, 0.75, 0.88)
    env.ambient_light_energy = 0.85
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)
    var floor := StaticBody3D.new()
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(260, 260)
    floor_mesh.mesh = plane
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("34423d")
    floor_mat.roughness = 1.0
    floor_mesh.material_override = floor_mat
    floor.add_child(floor_mesh)
    var floor_shape := CollisionShape3D.new()
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(260, 0.2, 260)
    floor_shape.shape = floor_box
    floor_shape.position.y = -0.1
    floor.add_child(floor_shape)
    add_child(floor)

func _build_roads() -> void:
    var road_mat := StandardMaterial3D.new()
    road_mat.albedo_color = Color("252b30")
    road_mat.roughness = 0.95
    var line_mat := StandardMaterial3D.new()
    line_mat.albedo_color = Color("e4d9a8")
    for i in range(-5, 5):
        var lane := float(i) * 22.0 + 11.0
        _add_road_strip(Vector3(lane, 0.015, 0), Vector2(7.5, 260), road_mat)
        _add_road_strip(Vector3(0, 0.016, lane), Vector2(260, 7.5), road_mat)
        for dash in range(-12, 13):
            _add_box_visual(Vector3(lane, 0.035, dash * 9.0), Vector3(0.12, 0.025, 3.8), line_mat)
            _add_box_visual(Vector3(dash * 9.0, 0.035, lane), Vector3(3.8, 0.025, 0.12), line_mat)

func _add_road_strip(pos: Vector3, size: Vector2, material: Material) -> void:
    var road := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = size
    road.mesh = mesh
    road.material_override = material
    road.position = pos
    add_child(road)

func _add_box_visual(pos: Vector3, size: Vector3, material: Material) -> void:
    var item := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.material_override = material
    item.position = pos
    add_child(item)

func _build_city() -> void:
    var palette := [Color("66717d"), Color("a58d79"), Color("7b8790"), Color("b5a58e"), Color("596d70"), Color("81777f")]
    for x in range(-5, 6):
        for z in range(-5, 6):
            if abs(x) < 2 and abs(z) < 2:
                continue
            var height := rng.randf_range(5.0, 22.0)
            var width := rng.randf_range(7.0, 10.5)
            var depth := rng.randf_range(7.0, 10.5)
            var building := StaticBody3D.new()
            building.position = Vector3(x * 22.0, height * 0.5, z * 22.0)
            var mesh := MeshInstance3D.new()
            var box_mesh := BoxMesh.new()
            box_mesh.size = Vector3(width, height, depth)
            mesh.mesh = box_mesh
            var mat := StandardMaterial3D.new()
            mat.albedo_color = palette[rng.randi_range(0, palette.size() - 1)]
            mat.roughness = 0.92
            mesh.material_override = mat
            building.add_child(mesh)
            var collision := CollisionShape3D.new()
            var shape := BoxShape3D.new()
            shape.size = box_mesh.size
            collision.shape = shape
            building.add_child(collision)
            _add_windows(building, height, depth)
            add_child(building)

func _add_windows(parent: Node3D, height: float, depth: float) -> void:
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color("284d60")
    glass.metallic = 0.18
    glass.roughness = 0.25
    for floor_index in range(1, int(height / 3.0)):
        for side in [-1.0, 1.0]:
            var window := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(1.0, 0.85, 0.06)
            window.mesh = mesh
            window.material_override = glass
            window.position = Vector3(0, -height * 0.5 + floor_index * 2.8, side * (depth * 0.5 + 0.04))
            parent.add_child(window)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0, 7)
    var visual := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.43
    capsule.height = 1.8
    visual.mesh = capsule
    visual.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("e5a34b")
    visual.material_override = material
    player.add_child(visual)
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.43
    shape.height = 1.8
    collider.shape = shape
    collider.position.y = 0.9
    player.add_child(collider)
    add_child(player)

func _build_car() -> void:
    car = CharacterBody3D.new()
    car.name = "PlayerCar"
    car.set_script(CAR_SCRIPT)
    car.position = Vector3(3.5, 0, 7)
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(2.1, 0.8, 4.0)
    body.mesh = body_mesh
    body.position.y = 0.55
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color("c52e35")
    paint.metallic = 0.4
    paint.roughness = 0.3
    body.material_override = paint
    car.add_child(body)
    var cabin := MeshInstance3D.new()
    var cabin_mesh := BoxMesh.new()
    cabin_mesh.size = Vector3(1.7, 0.65, 1.8)
    cabin.mesh = cabin_mesh
    cabin.position = Vector3(0, 1.18, -0.25)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color("263b4a")
    cabin.material_override = glass
    car.add_child(cabin)
    var collider := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(2.1, 1.1, 4.0)
    collider.shape = box
    collider.position.y = 0.55
    car.add_child(collider)
    add_child(car)

func _make_vehicle_visual(parent: Node3D, color: Color) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.8, 0.7, 3.4)
    body.mesh = mesh
    body.position.y = 0.55
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.25
    body.material_override = material
    parent.add_child(body)
    var cabin := MeshInstance3D.new()
    var cabin_mesh := BoxMesh.new()
    cabin_mesh.size = Vector3(1.45, 0.55, 1.45)
    cabin.mesh = cabin_mesh
    cabin.position = Vector3(0, 1.12, -0.2)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color("203642")
    cabin.material_override = glass
    parent.add_child(cabin)

func _build_traffic() -> void:
    var lanes := [-55.0, -33.0, 11.0, 33.0, 55.0]
    var colors := [Color("e6bd45"), Color("4d91c8"), Color("d85b4e"), Color("dedede")]
    for i in range(10):
        var traffic := Node3D.new()
        traffic.set_script(TRAFFIC_SCRIPT)
        _make_vehicle_visual(traffic, colors[i % colors.size()])
        var x: float = float(lanes[i % lanes.size()]) + (2.0 if i % 2 == 0 else -2.0)
        var direction := Vector3.FORWARD if i % 2 == 0 else Vector3.BACK
        var z := -105.0 + float(i) * 20.0
        traffic.call("configure", Vector3(x, 0, z), direction, rng.randf_range(7.0, 13.0))
        add_child(traffic)

func _build_pedestrians() -> void:
    for i in range(12):
        var npc := CharacterBody3D.new()
        npc.set_script(PEDESTRIAN_SCRIPT)
        var x := rng.randf_range(-95.0, 95.0)
        var z := rng.randf_range(-95.0, 95.0)
        if abs(x) < 12.0 and abs(z) < 12.0:
            x += 18.0
        npc.position = Vector3(x, 0, z)
        var visual := MeshInstance3D.new()
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.32
        capsule.height = 1.55
        visual.mesh = capsule
        visual.position.y = 0.78
        var material := StandardMaterial3D.new()
        material.albedo_color = [Color("d46a48"), Color("4b8f7c"), Color("596ba7"), Color("c4a34b")][i % 4]
        visual.material_override = material
        npc.add_child(visual)
        var collision := CollisionShape3D.new()
        var shape := CapsuleShape3D.new()
        shape.radius = 0.32
        shape.height = 1.55
        collision.shape = shape
        collision.position.y = 0.78
        npc.add_child(collision)
        add_child(npc)

func _build_police() -> void:
    police_car = Node3D.new()
    police_car.set_script(POLICE_SCRIPT)
    _make_vehicle_visual(police_car, Color("202c42"))
    police_car.visible = false
    police_car.position = Vector3(-20, 0, -20)
    add_child(police_car)

func _build_checkpoints() -> void:
    var positions := [Vector3(-10, 1.2, 0), Vector3(15, 1.2, -16), Vector3(42, 1.2, 22), Vector3(-42, 1.2, -35), Vector3(0, 1.2, 55)]
    for index in range(collected, positions.size()):
        var area := Area3D.new()
        area.position = positions[index]
        var ring := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = 0.8
        torus.outer_radius = 1.0
        ring.mesh = torus
        ring.rotation.x = PI * 0.5
        var glow := StandardMaterial3D.new()
        glow.albedo_color = Color("39e7cf")
        glow.emission_enabled = true
        glow.emission = Color("19bda8")
        ring.material_override = glow
        area.add_child(ring)
        var collision := CollisionShape3D.new()
        var sphere := SphereShape3D.new()
        sphere.radius = 1.5
        collision.shape = sphere
        area.add_child(collision)
        area.body_entered.connect(_on_checkpoint_entered.bind(area))
        add_child(area)
        checkpoints.append(area)

func _on_checkpoint_entered(body: Node3D, point: Area3D) -> void:
    if body != player and body != car:
        return
    if not is_instance_valid(point):
        return
    collected += 1
    checkpoints.erase(point)
    point.queue_free()
    _save_progress()
    if collected >= 5:
        info.text = "MISSION COMPLETE!  •  $5000\nAll city checkpoints collected."

func _toggle_vehicle() -> void:
    if not driving and player.global_position.distance_to(car.global_position) < 5.0:
        driving = true
        player.visible = false
        player.set_physics_process(false)
    elif driving:
        driving = false
        player.global_position = car.global_position + car.global_transform.basis.x * 2.5
        player.visible = true
        player.set_physics_process(true)
        car.call("set_controls", Vector2.ZERO)

func _toggle_wanted_level() -> void:
    wanted_level = 1 if wanted_level == 0 else 0
    if wanted_level > 0:
        var target: Node3D = car if driving else player
        police_car.call("set_target", target)
    else:
        police_car.call("set_target", null)

func _update_camera() -> void:
    var target: Node3D = car if driving else player
    if camera == null:
        camera = Camera3D.new()
        camera.fov = 75.0
        camera.current = true
        add_child(camera)
        camera.global_position = Vector3(0, 5, 14)
    var focus := target.global_position + Vector3(0, 1.3, 0)
    var offset := target.global_transform.basis.z * (8.5 if driving else 6.0) + Vector3(0, 3.0, 0)
    camera.global_position = camera.global_position.lerp(focus + offset, 0.13)
    camera.look_at(focus, Vector3.UP)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(310, 112)
    layer.add_child(panel)
    info = Label.new()
    info.text = "NITISH 5  |  CITY EXPLORER\nCheckpoints: %d / 5\nWASD: Move  •  E: Car  •  F: Police" % collected
    info.add_theme_font_size_override("font_size", 17)
    panel.add_child(info)
    _add_hold_button(layer, "▲", Vector2(100, -160), "move_forward")
    _add_hold_button(layer, "▼", Vector2(100, -70), "move_back")
    _add_hold_button(layer, "◀", Vector2(12, -115), "move_left")
    _add_hold_button(layer, "▶", Vector2(188, -115), "move_right")
    _add_hold_button(layer, "JUMP", Vector2(-190, -160), "jump", true)
    _add_hold_button(layer, "BRAKE", Vector2(-190, -78), "brake", true)
    _add_action_button(layer, "ENTER / EXIT", Vector2(-190, -238), _toggle_vehicle)
    _add_action_button(layer, "WANTED", Vector2(-190, -305), _toggle_wanted_level)

func _add_hold_button(layer: CanvasLayer, caption: String, offset: Vector2, action: String, right_side := false) -> void:
    var button := Button.new()
    button.text = caption
    button.size = Vector2(76, 70)
    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if right_side else Control.PRESET_BOTTOM_LEFT)
    button.position = offset
    button.modulate = Color(1, 1, 1, 0.82)
    layer.add_child(button)
    button.button_down.connect(func(): Input.action_press(action))
    button.button_up.connect(func(): Input.action_release(action))

func _add_action_button(layer: CanvasLayer, caption: String, offset: Vector2, callback: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.size = Vector2(160, 58)
    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.position = offset
    layer.add_child(button)
    button.pressed.connect(callback)

func _update_hud() -> void:
    if info:
        var police_status := "WANTED: ON" if wanted_level > 0 else "WANTED: OFF"
        info.text = "NITISH 5  |  CITY EXPLORER\nCheckpoints: %d / 5\n%s  •  %s" % [collected, "DRIVING" if driving else "ON FOOT", police_status]

func _save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("mission", "checkpoints", collected)
    config.save(save_path)

func _load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(save_path) == OK:
        collected = clampi(int(config.get_value("mission", "checkpoints", 0)), 0, 5)
