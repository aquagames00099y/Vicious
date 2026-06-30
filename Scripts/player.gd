extends CharacterBody3D

#-------------#
#---ATTACK----#
#-------------#
var attackCount = 0
var is_attacking = false
var waitBeforeSlash2 = 0.833
var waitBeforeSlash1 = 0.833

#-----------#
#---MOVE----#
#-----------#
var speed = 10
var fall_acc = 75
var jump_impulse = 20
var mouse_sensitivity: float = 0.003
var camera_pitch: float = 0.0
var target_velocity = Vector3.ZERO
@onready var head: Node3D = $Arms
@onready var anim_player: AnimationPlayer = $Arms/AnimationPlayer
@onready var running: AudioStreamPlayer3D = $Running
@onready var jumping: AudioStreamPlayer3D = $Jumping

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_player.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch += event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
		head.rotation.x = camera_pitch

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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
	
	# Only let movement control animation when NOT attacking
	if not is_attacking:
		if moveDir == Vector3.ZERO:
			anim_player.play("CharacterArmature|Fists_Idle")
		else:
			moveDir = moveDir.normalized()
			anim_player.play("CharacterArmature|Sword_Walk")
	
	if moveDir != Vector3.ZERO and is_on_floor():
		if not running.playing:
			running.play()
	else:
		if running.playing:
			running.stop()

		
	var direction = (transform.basis * moveDir)
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acc * delta)

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		jumping.play()

	velocity = target_velocity
	move_and_slide()

func _process(delta: float) -> void:
	
	if attackCount == 1 and waitBeforeSlash2 > 0:
		waitBeforeSlash2 -= delta
 
	if Input.is_action_just_pressed("Attack"):
		if attackCount == 0 and not is_attacking:
			is_attacking = true
			anim_player.play("CharacterArmature|Sword_Slash1")
			attackCount = 1
		elif attackCount == 1 and waitBeforeSlash2 <= 0 and not is_attacking:
			is_attacking = true
			anim_player.play("CharacterArmature|Sword_Slash2")
			attackCount = 0
			waitBeforeSlash2 = 0.833

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "CharacterArmature|Sword_Slash1":
		is_attacking = false
	elif anim_name == "CharacterArmature|Sword_Slash2":
		is_attacking = false
		attackCount = 0
