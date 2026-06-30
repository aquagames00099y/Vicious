extends CharacterBody3D

var speed = 10
var fall_acc = 75
var jump_impulse = 20
var mouse_sensitivity: float = 0.003
var camera_pitch: float = 0.0
var target_velocity = Vector3.ZERO

@onready var head: Node3D = $Arms
@onready var anim_player: AnimationPlayer = $Arms/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the whole body left/right (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate only the head up/down (pitch), and clamp it
		camera_pitch += event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
		head.rotation.x = camera_pitch

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Esc key by default
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	
	var moveDir = Vector3.ZERO
	
	if Input.is_action_pressed("move_Right"):
		moveDir.x -= 1
	if Input.is_action_pressed("move_Left"):
		moveDir.x += 1
	if Input.is_action_pressed("move_Backward"):
		moveDir.z -= 1
	if Input.is_action_pressed("move_Forward"):
		moveDir.z += 1
		
	if anim_player.current_animation != "CharacterArmature|Sword_Slash1":
		if moveDir == Vector3.ZERO:
			anim_player.play("CharacterArmature|Fists_Idle")
		else:
			moveDir = moveDir.normalized()
			anim_player.play("CharacterArmature|Sword_Walk")
		
		# $CharacterArmature.basis = basis.looking_at(moveDir)

	var direction = (transform.basis * moveDir)
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acc * delta)
	
	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
		
		
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Attack"):
		anim_player.play("CharacterArmature|Sword_Slash1")
