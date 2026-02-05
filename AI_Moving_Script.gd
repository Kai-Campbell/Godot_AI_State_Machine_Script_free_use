extends CharacterBody3D

'Remember to grab the correct extensions for these values and reassign them'
@onready var AI_Character: CharacterBody3D = $"." #root node of the AI character
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D #grab the correct extensions for these, for example your nav agent might be $center/NacigationAgent3D

@export var wander_allowed : bool = true #set to false if you want the AI to wander within a set distance of its spawn position.
@export var object_path : NodePath #set this to make the AI chase the player or an object (like a ball for a sports game)

enum STATE {Idle, Wait, Wander, Attack} #feel free to add more states if needed
var state : STATE = STATE.Idle
var chase_distance = 20
var wander_timer : float = 0.2 #change this value to make the AI wait longer before resuming walking
var wander_timer_count : float = 0.0
const RUN_SPEED : int = 10
var speed : int = 5 
var start_pos : Vector3
var chase_object = null

func _ready() -> void:
	start_pos = global_position #used for setting where the wander area will be, assigned to the AI's spawn point
	chase_object = get_node(object_path) #sets the target object that the AI will pursue when in attack mode
	
func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta

	match state:
		STATE.Idle:
			_idle()
		STATE.Wait:
			_wait(delta)
		STATE.Wander:
			_wander()
		STATE.Attack:
			_attack(chase_object)

	move_and_slide()

'be sure to link the signal of your nav agent on your AI character here for this function to execute'
func _on_navigation_agent_3d_target_reached() -> void: # if you want the target to play an animation or do an action when it reaches its destination, place it in here
	if global_position.distance_to(chase_object.global_position) <= chase_distance:
		state = STATE.Attack
	else:
		state = STATE.Idle

func _idle():
	velocity = Vector3.ZERO
	wander_timer_count = wander_timer
	state = STATE.Wait

func _wait(delta):
	wander_timer_count -= delta
	
	if wander_timer_count <= 0.0:
		var target = get_random_location()
		navigation_agent_3d.set_target_position(target)
		state = STATE.Wander

func _wander():
	var current_position = global_position
	var next_pos = navigation_agent_3d.get_next_path_position()
	var direction = (next_pos - current_position).normalized()
	velocity = direction * speed
	if global_position.distance_to(chase_object.global_position) <= chase_distance:
		state = STATE.Attack

func _attack(path):
	var current_position = global_position
	navigation_agent_3d.target_position = path.global_position
	var next_pos = navigation_agent_3d.get_next_path_position()
	var direction = (next_pos - current_position).normalized()
	velocity = direction * RUN_SPEED
	if global_position.distance_to(chase_object.global_position) > chase_distance:
		state = STATE.Idle

func get_random_location() -> Vector3: 
	var random_loc : Vector3 #Change these two values below to allow for wider wander ranges.
	var random_X = randi_range(-15, 15) 
	var random_Z = randi_range(-10, 10)
	if wander_allowed:
		random_loc = Vector3(random_X , 0.0, random_Z)	
	else:
		random_loc = Vector3(start_pos.x + random_X, 0.0, start_pos.z + random_Z)
	return random_loc
