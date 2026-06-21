extends CharacterBody2D

@export var speed = 200
@export var max_spinning_speed = 100
var held_enemies = []
var nearby_enemies = []

@export var max_held = 1
@export var throw_speed = 200
@export var orbit_radius = 100
@export var max_orbit_speed = 180
@export var health = 100
@export var time_to_max_speed = 3
@export var spinning_damage_delay = 1

var is_playing_animation = false
var last_dir = Vector2.DOWN
var spinning_progress = 0.0

# PUBLIC METHODS
func add_nearby(enemy):
	nearby_enemies.append(enemy)
func remove_nearby(enemy):
	nearby_enemies.erase(enemy)
func take_damage(damage: float, by_whom: Node2D):
	self.health -= damage
	
func start(pos):
	position = pos
	show()

# PRIVATE METHODS

class AnimationState:
	var suffix: String
	var flip_h: bool
	var index: int
	var display: String
	
	func _init(
		p_suffix: String = "", 
		p_flip_h: bool = false, 
		p_index: int = 0, 
		p_display: String = "Default"):
		self.suffix = p_suffix
		self.flip_h = p_flip_h
		self.index = p_index
		self.display = p_display
		
	func _to_string() -> String:
		return self.display

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	
	dir.x = Input.get_axis("move_left","move_right")
	dir.y = Input.get_axis("move_up","move_down")
	
	return dir
func get_animation_state(dir: Vector2) -> AnimationState:
	var angle = dir.normalized().angle()
	if angle < -7 * PI / 8 or angle >= 7 * PI / 8:
		return AnimationState.new("_right", true, 2, "left")
	elif angle < -5 * PI / 8:
		return AnimationState.new("_back_diag", true, 3, "back-left")
	elif angle < -3 * PI / 8:
		return AnimationState.new("_back", false, 4, "back")
	elif angle < -PI / 8:
		return AnimationState.new("_back_diag", false, 5, "back-right")
	elif angle < PI / 8:
		return AnimationState.new("_right", false, 6, "right")
	elif angle < 3 * PI / 8:
		return AnimationState.new("_front_diag", false, 7, "front-right")
	elif angle < 5 * PI / 8:
		return AnimationState.new("_front", false, 0, "front")
	else:
		return AnimationState.new("_front_diag", true, 1, "front-left")
func get_spinning_movement_speed(progress: float):
	return progress * max_spinning_speed
func handle_move(delta: float) -> void:
	var velocity = Vector2.ZERO
	
	# Derive the input direction and the animation state for walking
	var input_dir = get_input_direction()
	var is_moving = input_dir != Vector2.ZERO
	if is_moving:
		last_dir = input_dir
	var input_state = get_animation_state(last_dir)
	
	var final_movement_speed = speed
	if (held_enemies.size() != 0):
		final_movement_speed = get_spinning_movement_speed(spinning_progress)
	if (input_dir.length() > 0):
		velocity = input_dir.normalized() * final_movement_speed

	position += velocity * delta
	
	for enemy in held_enemies:
		enemy.global_position += velocity * delta
	
	if held_enemies.size() == 0:
		var prefix = "walk" if is_moving else "idle"
		$Anime.play(prefix + input_state.suffix)
		$Anime.flip_h = input_state.flip_h

func get_nearest_enemy():
	var min_dist_sq = INF
	var closest_enemy = null
	for enemy in nearby_enemies:
		if (enemy is Enemy):
			var dist = enemy.global_position.distance_squared_to(self.global_position)
			if min_dist_sq > dist and enemy.get_can_be_picked_up():
				min_dist_sq = dist
				closest_enemy = enemy
	return closest_enemy

func handle_pickup():
	if not Input.is_action_just_pressed("interact"):
		return
	if not (held_enemies.size() < max_held && nearby_enemies.size() > 0):
		return
		
	var enemy = get_nearest_enemy()
	
	if enemy == null:
		return

	grab_enemy(enemy)
	
	var dir = global_position.direction_to(enemy.global_position)
	var state = get_animation_state(dir)
	var prefix = "interact"
	$Anime.play(prefix + state.suffix)
	$Anime.flip_h = state.flip_h
	await $Anime.animation_finished

# Resets the spinning progress
func handle_throw():
	if not Input.is_action_just_pressed("throw"):
		return
	if not held_enemies.size() > 0:
		return
	
	var average_dir = 0.0
	var count = 0
	for enemy in held_enemies:
		throw_enemy(enemy)
		var angle = get_throw_direction(enemy).angle()
		average_dir += angle
		count += 1
	average_dir /= count
	spinning_progress = 0.0
	
	var state = get_animation_state(Vector2.from_angle(average_dir))
	$Anime.play("attack" + state.suffix)
	$Anime.flip_h = state.flip_h
	await $Anime.animation_finished
	last_dir = Vector2.from_angle(average_dir)

const STEEPNESS = 2.0
func get_current_orbit_speed(progress: float):
	return max_orbit_speed * (exp(STEEPNESS * progress) - 1.0) / (exp(STEEPNESS) - 1.0)
# Advances the spinning progress
func rotate_enemy_around_player(delta: float) -> void:
	if (held_enemies.size() == 0):
		return
		
	spinning_progress = min(1.0, spinning_progress + delta / time_to_max_speed)
	var average_dir = 0.0
	var current_orbit_speed = get_current_orbit_speed(spinning_progress)
	for enemy in held_enemies:
		var dist = self.global_position.distance_to(enemy.global_position)
		var new_dist = move_toward(dist, orbit_radius, current_orbit_speed * delta)
		var angle = self.global_position.angle_to_point(enemy.global_position)
		var new_angle = angle + deg_to_rad(2 * current_orbit_speed * delta)
		enemy.global_position = self.global_position + Vector2.from_angle(new_angle) * new_dist
		
		average_dir += new_angle
	
	average_dir /= held_enemies.size()
	var state = get_animation_state(Vector2.from_angle(average_dir))
	$Anime.animation = "rotate"
	$Anime.frame = state.index
	$Anime.flip_h = false

func apply_hitstop(duration: float):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
func get_spinning_damage_to_other(grabbed_enemy: Enemy):
	return 10.0 * spinning_progress + 5.0
func get_spinning_damage_to_tool(grabbed_enemy: Enemy):
	return 5.0

func on_grabbed_enemy_contact_enemy(grabbed_enemy: Enemy, enemy: Node2D):
	var time_spinning = spinning_progress * time_to_max_speed
	if (time_spinning < spinning_damage_delay):
		return
	if (enemy.has_method("take_damage")):
		enemy.take_damage(
			get_spinning_damage_to_other(grabbed_enemy), self, spinning_progress)
		grabbed_enemy.take_damage(
			get_spinning_damage_to_tool(grabbed_enemy), null)
		apply_hitstop(0.05)	

func on_grabbed_enemy_die(grabbed_enemy: Enemy):
	held_enemies.erase(grabbed_enemy)
	spinning_progress = 0.0
	grabbed_enemy.deregister_death_listener(on_grabbed_enemy_die)

func grab_enemy(enemy):
	held_enemies.append(enemy)
	enemy.picked_up()
	remove_nearby(enemy)
	enemy.register_contact_enemy_listener(on_grabbed_enemy_contact_enemy)
	enemy.register_death_listener(on_grabbed_enemy_die)
	
func get_throw_direction(enemy: Node2D):
	return global_position.direction_to(enemy. global_position).rotated(PI/2)

func throw_enemy(enemy):
	enemy.throw(get_throw_direction(enemy), throw_speed)
	held_enemies.erase(enemy)
	enemy.deregister_contact_enemy_listener(on_grabbed_enemy_contact_enemy)
	enemy.deregister_death_listener(on_grabbed_enemy_die)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_debug_label()
	if not is_playing_animation:
		handle_move(delta)
		
		rotate_enemy_around_player(delta)
		update_throw_arrow()
		# This chunk locks so that we wait for the animation to play
		is_playing_animation = true
		await handle_pickup()
		await handle_throw()
		is_playing_animation = false

var line_dict = {}
func update_throw_arrow():
	for enemy in held_enemies:
		var line: Line2D = null
		if (not line_dict.has(enemy)):
			line = $Line2D.duplicate()
			line_dict[enemy] = line
			line.top_level = true
			add_child(line)
		line = line_dict[enemy]
		line.clear_points()
		line.add_point(enemy.global_position)
		line.add_point(get_throw_direction(enemy) * 50.0 + enemy.global_position)
	var to_remove = []
	for entry in line_dict:
		if not held_enemies.has(entry):
			to_remove.append(entry)
	for enemy in to_remove:
		line_dict[enemy].queue_free()
		line_dict.erase(enemy)

func update_debug_label():
	$DebugLabel.text = "Nearby: "
	for enemy in nearby_enemies:
		$DebugLabel.text += str(enemy) + ", "
	$DebugLabel.text += "\n"


func _on_pickup_hitbox_area_entered(area: Area2D) -> void:
	if area is Enemy and area.get_can_be_picked_up():
		add_nearby(area)

func _on_pickup_hitbox_area_exited(area: Area2D) -> void:
	if area is Enemy and area.get_can_be_picked_up():
		remove_nearby(area)
