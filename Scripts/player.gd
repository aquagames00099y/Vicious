extends CharacterBody3D

#-------------#
#----DASH-----#
#-------------#
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8

var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

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
@export var speed = 10
@export var fall_acc = 75
@export var jump_impulse = 20
var jumpCount = 0
var mouse_sensitivity: float = 0.003
var camera_pitch: float = 0.0
var target_velocity = Vector3.ZERO
@onready var head: Node3D = $Arms
@onready var anim_player: AnimationPlayer = $Arms/AnimationPlayer
@onready var running: AudioStreamPlayer3D = $Running
@onready var jumping: AudioStreamPlayer3D = $Jumping
@onready var slash: AudioStreamPlayer3D = $Slash

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
	
	handle_dash_input()
	update_dash(delta)
	
	if is_on_floor():
		jumpCount = 0
	
	var moveDir = Vector3.ZERO
	
	if Input.is_action_pressed("move_Right"):
		moveDir.x -= 1
	if Input.is_action_pressed("move_Left"):
		moveDir.x += 1
	if Input.is_action_pressed("move_Backward"):
		moveDir.z -= 1
	if Input.is_action_pressed("move_Forward"):
		moveDir.z += 1
		
	if is_dashing:
		target_velocity.x = dash_direction.x * dash_speed
		target_velocity.z = dash_direction.z * dash_speed
		# optional: lock out gravity during dash for a flatter, snappier feel
		target_velocity.y = 0.0
	else:
		var direction = (transform.basis * moveDir)
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
		#target_velocity.y = target_velocity.y
	
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

	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acc * delta)

	if is_on_floor() and Input.is_action_just_pressed("jump") and jumpCount == 0:
		target_velocity.y = jump_impulse
		jumpCount = 1
		jumping.play()
	elif jumpCount == 1 and not is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse * 0.65
		jumpCount = 0
		jumping.play()

	velocity = target_velocity
	move_and_slide()

func _process(delta: float) -> void:
	
	if attackCount == 1 and waitBeforeSlash2 > 0:
		waitBeforeSlash2 -= delta
 
	if Input.is_action_just_pressed("Attack"):
		if attackCount == 0 and not is_attacking:
			is_attacking = true
			slash.play()
			anim_player.play("CharacterArmature|Sword_Slash1")
			attackCount = 1
		elif attackCount == 1 and waitBeforeSlash2 <= 0 and not is_attacking:
			is_attacking = true
			slash.play()
			anim_player.play("CharacterArmature|Sword_Slash2")
			attackCount = 0
			waitBeforeSlash2 = 0.833

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "CharacterArmature|Sword_Slash1":
		is_attacking = false
	elif anim_name == "CharacterArmature|Sword_Slash2":
		is_attacking = false
		attackCount = 0

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("Dash") and can_dash and not is_dashing:
		start_dash()

func start_dash() -> void:
	var input_dir: Vector2 = Input.get_vector("move_Right", "move_Left",  "move_Backward", "move_Forward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# if no movement input, dash in the direction the player is facing
	if direction == Vector3.ZERO:
		direction = transform.basis.z.normalized()
		#direction = transform.basis.x.normalized()

	dash_direction = direction
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	# optional: dash_sound.play()

func update_dash(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			cooldown_timer = dash_cooldown

	if not can_dash and not is_dashing:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_dash = true
