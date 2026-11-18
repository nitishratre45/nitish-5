extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CAR_SCRIPT = preload("res://scripts/car.gd")
var player: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var info: Label
var driving := false
var collected := 0
var checkpoints: Array[Area3D] = []

func _ready() -> void:
    _build_environment()
    _build_city()
    _build_player()
    _build_car()
    _build_checkpoints()
    _build_hud()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        _toggle_vehicle()
    _follow_camera()
    info.text = "NITISH 5  |  CITY EXPLORER\nCheckpoints: %d / 5\n%s  •  E: Enter / Exit" % [collected, "Driving" if driving else "On foot"]

func _physics_process(_delta: float) -> void:
    var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if driving:
        car.set_controls(movement)
    else:
        player.set_controls(movement)

func _build_environment() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.68, 0.75, 0.88)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.shadow_enabled = true
    add_child(sun)

    var floor := StaticBody3D.new()
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(260, 260)
    floor_mesh.mesh = plane
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.16, 0.21, 0.20)
    floor_mesh.material_override = floor_mat
    floor.add_child(floor_mesh)
    var floor_shape := CollisionShape3D.new()
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(260, 0.2, 260)
    floor_shape.shape = floor_box
    floor_shape.position.y = -0.1
    floor.add_child(floor_shape)
    add_child(floor)

func _build_city() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4518
    var palette := [Color("66717d"), Color("a58d79"), Color("7b8790"), Color("b5a58e"), Color("596d70")]
    for x in range(-5, 6):
        for z in range(-5, 6):
            if abs(x) < 2 and abs(z) < 2:
                continue
            var h := rng.randf_range(5.0, 22.0)
            var w := rng.randf_range(7.0, 11.0)
            var d := rng.randf_range(7.0, 11.0)
            var building := StaticBody3D.new()
            building.position = Vector3(x * 22.0, h * 0.5, z * 22.0)
            var mesh := MeshInstance3D.new()
            var shape_mesh := BoxMesh.new()
            shape_mesh.size = Vector3(w, h, d)
            mesh.mesh = shape_mesh
            var mat := StandardMaterial3D.new()
            mat.albedo_color = palette[rng.randi_range(0, palette.size() - 1)]
            mat.roughness = 0.9
            mesh.material_override = mat
            building.add_child(mesh)
            var collision := CollisionShape3D.new()
            var box := BoxShape3D.new()
            box.size = shape_mesh.size
            collision.shape = box
            building.add_child(collision)
            _add_building_windows(building, h, d)
            add_child(building)

func _add_building_windows(parent: Node3D, h: float, d: float) -> void:
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.23, 0.46, 0.55)
    glass.metallic = 0.2
    for level in range(1, int(h / 3.2)):
        for side in [-1.0, 1.0]:
            var win := MeshInstance3D.new()
            var wm := BoxMesh.new()
            wm.size = Vector3(1.0, 0.9, 0.06)
            win.mesh = wm
            win.material_override = glass
            win.position = Vector3(0, -h * 0.5 + level * 3.0, side * (d * 0.5 + 0.04))
            parent.add_child(win)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 1.2, 7)
    var visual := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.8
    visual.mesh = capsule
    visual.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("e5a34b")
    visual.material_override = material
    player.add_child(visual)
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.48
    shape.height = 1.8
    collider.shape = shape
    collider.position.y = 0.9
    player.add_child(collider)
    add_child(player)

func _build_car() -> void:
    car = CharacterBody3D.new()
    car.name = "PlayerCar"
    car.set_script(CAR_SCRIPT)
    car.position = Vector3(3.5, 0.7, 7)
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(2.1, 0.8, 4.0)
    body.mesh = body_mesh
    body.position.y = 0.55
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color("c52e35")
    paint.metallic = 0.45
    paint.roughness = 0.28
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

func _build_checkpoints() -> void:
    var positions := [Vector3(-10, 1.3, 0), Vector3(15, 1.3, -16), Vector3(42, 1.3, 22), Vector3(-42, 1.3, -35), Vector3(0, 1.3, 55)]
    for point in positions:
        var area := Area3D.new()
        area.position = point
        var ring := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = 0.8
        torus.outer_radius = 1.0
        ring.mesh = torus
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
    if collected >= 5:
        info.text = "MISSION COMPLETE!\nAll city checkpoints collected."

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
        car.set_controls(Vector2.ZERO)

func _follow_camera() -> void:
    var target: Node3D = car if driving else player
    if camera == null:
        camera = Camera3D.new()
        camera.fov = 75.0
        add_child(camera)
        camera.current = true
        camera.global_position = Vector3(0, 5, 14)
    var focus := target.global_position + Vector3(0, 1.3, 0)
    var offset := target.global_transform.basis.z * (8.5 if driving else 6.0) + Vector3(0, 3.0, 0)
    camera.global_position = camera.global_position.lerp(focus + offset, 0.12)
    camera.look_at(focus, Vector3.UP)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(310, 100)
    layer.add_child(panel)
    info = Label.new()
    info.text = "NITISH 5  |  CITY EXPLORER\nCheckpoints: 0 / 5\nWASD: Move  •  E: Enter car"
    info.add_theme_font_size_override("font_size", 17)
    panel.add_child(info)
    _add_hold_button(layer, "▲", Vector2(100, -160), "move_forward")
    _add_hold_button(layer, "▼", Vector2(100, -70), "move_back")
    _add_hold_button(layer, "◀", Vector2(12, -115), "move_left")
    _add_hold_button(layer, "▶", Vector2(188, -115), "move_right")
    _add_hold_button(layer, "JUMP", Vector2(-190, -160), "jump", true)
    var enter := Button.new()
    enter.text = "ENTER / EXIT"
    enter.position = Vector2(-190, -78)
    enter.size = Vector2(165, 58)
    enter.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    layer.add_child(enter)
    enter.pressed.connect(_toggle_vehicle)

func _add_hold_button(layer: CanvasLayer, caption: String, offset: Vector2, action: String, right_side := false) -> void:
    var button := Button.new()
    button.text = caption
    button.size = Vector2(76, 70)
    if right_side:
        button.position = Vector2(-100, 0) + offset
        button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    else:
        button.position = Vector2(20, 0) + offset
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    button.modulate = Color(1, 1, 1, 0.82)
    layer.add_child(button)
    button.button_down.connect(func(): Input.action_press(action))
    button.button_up.connect(func(): Input.action_release(action))
