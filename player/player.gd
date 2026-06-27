extends CharacterBody2D

class_name Player

@export_group("Movement")
@export var player_speed = 75
@export var friction = 50

@export_group("Entity")
@export var health = 5

@export_group("Combat")
@export var max_held = 1
@export var time_to_max_speed = 3
@export var spinning_damage_delay = 1
@export var max_spinning_speed = 25
@export var throw_speed_scale = 2
@export var orbit_radius = 25
@export var enter_orbit_speed = 100.0
@export var max_orbit_speed = 360
@export var enemy_knockback = 20.0
@export var base_spinning_damage_to_held = 1.0
@export var base_spinning_damage_to_other = 1.0
@export var max_spin_additive_damage_to_other = 0.0

var held_enemies = []
var nearby_enemies = []

var is_playing_animation = false
var is_recoiling = false
var last_dir = Vector2.DOWN
var spinning_progress = 0.0

@onready var animated_sprite = $Anime
@onready var thwack_audio = $whack_audio
@onready var whack_audio = $whack_audio
@onready var grab_audio = $grab_audio
@onready var woosh_audio = $woosh_audio

# PUBLIC METHODS
func add_nearby(enemy):
	if enemy is Enemy:
		nearby_enemies.append(enemy)
		Progress.enemy_enter_range()
		enemy.register_death_listener(remove_nearby)

func remove_nearby(enemy):
	if enemy is Enemy:
		nearby_enemies.erase(enemy)
		enemy.deregister_death_listener(remove_nearby)

func get_recoil_flash_modifier(time: float):
	return max(0.0, 1.0 - time * 2.0)

func set_flash_modifier(progress: float):
	animated_sprite.set_instance_shader_parameter("flash_modifier", progress)

var time_since_entered_recoil = 10.0

@onready var room_hitbox = $room_hitbox
@onready var camera = $Camera2D

@export var camera_zoom_speed = 5.0
@export var original_camera_zoom = 5.0

func handle_camera(delta: float):
	var overlapping = room_hitbox.get_overlapping_areas()
	var room = null if overlapping.size() == 0 else overlapping[0]
	if room is Room:
		var screen_size = get_viewport().get_visible_rect().size
		var shorter_side = min(screen_size.x, screen_size.y)
		var zoom = shorter_side / room.room_size
		var pos = room.global_position
		camera.zoom = camera.zoom.move_toward(Vector2(zoom, zoom), camera_zoom_speed * delta)
		
		var diff = abs(zoom - camera.zoom.x)
		if diff < 0.001:
			camera.offset = pos
			room.activate(false)
		else:
			var time = diff / camera_zoom_speed
			var distance = pos - camera.offset
			var speed = distance / time
			camera.offset += speed * delta
	else:
		camera.zoom = camera.zoom.move_toward(
			Vector2(original_camera_zoom, original_camera_zoom), camera_zoom_speed * delta)
		var diff = abs(original_camera_zoom - camera.zoom.x)
		if diff < 0.001:
			camera.offset = global_position
		else:
			var time = diff / camera_zoom_speed
			var distance = global_position - camera.offset
			var speed = distance / time
			camera.offset += speed * delta

func _process(delta: float):
	time_since_entered_recoil += delta
	set_flash_modifier(get_recoil_flash_modifier(time_since_entered_recoil))
	handle_camera(delta)

func get_player_gui() -> PlayerGUI:
	var player_gui = get_tree().get_first_node_in_group("PlayerGUI")
	if player_gui is PlayerGUI:
		return player_gui
	else:
		return null

func take_damage(damage: float, recoil_source: Node2D, recoil_amount: float = 1.0):
	whack_audio.play()
	
	self.health -= damage
	change_health()
	
	if health <= 0.0:
		Progress.on_death()
		return

	time_since_entered_recoil = 0.0
	if (!recoil_source == null):
		if PlayerStats.thorns_damage > 0.0 and recoil_source is Enemy:
			var enemy: Enemy = recoil_source
			enemy.take_damage(PlayerStats.thorns_damage, self)
	
		is_recoiling = true
		var recoil_dir = -global_position.direction_to(recoil_source.global_position)
		var recoil_speed = 10.0 * recoil_amount
		velocity = recoil_dir * recoil_speed
		await get_tree().create_timer(0.2, true, true, false).timeout
		is_recoiling = false

func start(pos):
	position = pos
	camera.offset = pos
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
	$HealthBar.hide_on_full = false
	$HealthBar.set_health(health, PlayerStats.max_health)
	change_health.call_deferred()
	camera.offset = global_position

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

func handle_controlled_move(delta: float) -> void:
	
	# Derive the input direction and the animation state for walking
	var input_dir = get_input_direction()
	var is_moving = input_dir != Vector2.ZERO
	if is_moving:
		last_dir = input_dir
	var input_state = get_animation_state(last_dir)
	
	var final_movement_speed = player_speed
	
	if (held_enemies.size() != 0):
		final_movement_speed = get_spinning_movement_speed(spinning_progress)
	final_movement_speed *= PlayerStats.speed_multiplier
	

	if (input_dir.length() >= 0):
		velocity = input_dir.normalized() * final_movement_speed

	for enemy in held_enemies:
		enemy.global_position += velocity * delta
	
	if held_enemies.size() == 0:
		var prefix = "walk" if is_moving else "idle"
		animated_sprite.play(prefix + input_state.suffix)
		animated_sprite.flip_h = input_state.flip_h

func handle_sliding_move(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var state = get_animation_state(-velocity.normalized())
	animated_sprite.animation = "rotate"
	animated_sprite.frame = state.index
	animated_sprite.flip_h = false
	
		
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
	if not (held_enemies.size() < max_held && nearby_enemies.size() > 0):
		hide_e()
		return
	
	show_e()
	if not Input.is_action_just_pressed("interact"):
		return
		
	var enemy = get_nearest_enemy()
	
	if enemy == null:
		return

	revolution_progress = 0.0
	
	grab_enemy(enemy)
	
	grab_audio.play()
	
	var dir = global_position.direction_to(enemy.global_position)
	var state = get_animation_state(dir)
	var prefix = "interact"
	animated_sprite.play(prefix + state.suffix)
	animated_sprite.flip_h = state.flip_h
	await animated_sprite.animation_finished

@onready var e_btn = $e_display_button
@onready var q_btn = $q_display_button

func show_e():
	e_btn.show()
func show_q():
	q_btn.show()
func hide_e():
	e_btn.hide()
func hide_q():
	q_btn.hide()

# Resets the spinning progress
func handle_throw():
	if not PlayerStats.unlock_throwing:
		return
	if not Input.is_action_just_pressed("throw"):
		return
	if not held_enemies.size() > 0:
		return
	
	hide_q()
	
	var average_dir = 0.0
	var count = 0
	for enemy in held_enemies:
		# Calculate the current velocity
		var r = enemy.global_position - global_position
		var w = get_current_orbit_speed(spinning_progress) / 180.0 * PI
		var current_velocity = Vector2.ZERO
		current_velocity.x = -w * r.y
		current_velocity.y = w * r.x
		throw_enemy(enemy, current_velocity)
		var angle = get_throw_direction(enemy).angle()
		average_dir += angle
		count += 1
	average_dir /= count
	spinning_progress = 0.0
	
	woosh_audio.play()
	var state = get_animation_state(Vector2.from_angle(average_dir))
	animated_sprite.play("attack" + state.suffix)
	animated_sprite.flip_h = state.flip_h
	await animated_sprite.animation_finished
	last_dir = Vector2.from_angle(average_dir)

const STEEPNESS = 2.0
func get_current_orbit_speed(progress: float):
	return max_orbit_speed * (exp(STEEPNESS * progress) - 1.0) / (exp(STEEPNESS) - 1.0)

var revolution_progress = 0.0

# Advances the spinning progress
func rotate_enemy_around_player(delta: float) -> void:
	if (held_enemies.size() == 0):
		return
	
	spinning_progress = min(
		1.0, 
		spinning_progress + delta / (time_to_max_speed * PlayerStats.spin_duration_shortening))
	var average_dir = 0.0
	var current_orbit_speed = get_current_orbit_speed(spinning_progress)
	
	if spinning_progress > 0.9:
		show_q()
		Progress.reach_max_speed()

	for enemy in held_enemies:
		var dist = self.global_position.distance_to(enemy.global_position)
		var new_dist = move_toward(dist, orbit_radius, enter_orbit_speed * delta)
		var angle = self.global_position.angle_to_point(enemy.global_position)
		var new_angle = angle + deg_to_rad(2 * current_orbit_speed * delta)
		enemy.global_position = self.global_position + Vector2.from_angle(new_angle) * new_dist
		revolution_progress += (new_angle - angle) / 2 / PI
		if (revolution_progress > 1.0):
			woosh_audio.pitch_scale = spinning_progress * 2 + 1.0
			woosh_audio.play()
			revolution_progress -= 1.0
		average_dir += new_angle
	
	average_dir /= held_enemies.size()
	var state = get_animation_state(Vector2.from_angle(average_dir))
	animated_sprite.animation = "rotate"
	animated_sprite.frame = state.index
	animated_sprite.flip_h = false

func apply_hitstop(duration: float):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func get_spinning_damage_to_other(_grabbed_enemy: Enemy):
	return (
		max_spin_additive_damage_to_other 
		* spinning_progress 
		+ base_spinning_damage_to_other
	) * PlayerStats.damage_multiplier

func get_spinning_damage_to_tool(_grabbed_enemy: Enemy):
	return base_spinning_damage_to_held

func add_damage_powerup():
	PlayerStats.add_damage_powerup()

func add_health_powerup():
	PlayerStats.add_health_powerup()
	health = PlayerStats.max_health
	change_health()

func add_explosion_damage_powerup():
	PlayerStats.add_explosion_damage_powerup()
func add_explosion_range_powerup():
	PlayerStats.add_explosion_range_powerup()
func add_thorns_powerup():
	PlayerStats.add_thorns_powerup()

func add_speed_powerup():
	PlayerStats.add_speed_powerup
func add_spin_speed_powerup():
	PlayerStats.add_spin_speed_powerup()

@onready var pickup_hitbox = $pickup_hitbox
var pickup_radius = 1.0
func add_area_powerup():
	pickup_radius += 0.1
	pickup_hitbox.scale = Vector2(pickup_radius, pickup_radius)

func change_health():
	get_player_gui().update_health(health, PlayerStats.max_health)
	$HealthBar.set_health(health, PlayerStats.max_health)

func on_grabbed_enemy_contact_object(grabbed_enemy: Enemy, object: Object):
	var time_spinning = spinning_progress * time_to_max_speed
	if (time_spinning < spinning_damage_delay):
		return
	if (object is Enemy):
		object.take_damage(
			get_spinning_damage_to_other(grabbed_enemy), self)
		object.launch_with_velocity(
			global_position.direction_to(object.global_position) * enemy_knockback
		)
	grabbed_enemy.take_damage(
		get_spinning_damage_to_tool(grabbed_enemy), null)
	apply_hitstop(0.0)	
	thwack_audio.play()
	
func on_grabbed_enemy_die(grabbed_enemy: Enemy):
	held_enemies.erase(grabbed_enemy)
	spinning_progress = 0.0
	grabbed_enemy.deregister_death_listener(on_grabbed_enemy_die)
	hide_q()

func grab_enemy(enemy: Enemy):
	enemy.update_explosion_damage(PlayerStats.additional_explosion_damage)
	enemy.update_explosion_range(PlayerStats.additional_explosion_range)
	held_enemies.append(enemy)
	enemy.picked_up()
	remove_nearby(enemy)
	enemy.register_contact_object_listener(on_grabbed_enemy_contact_object)
	enemy.register_death_listener(on_grabbed_enemy_die)
	

func get_throw_direction(enemy: Node2D):
	return global_position.direction_to(enemy. global_position).rotated(PI/2)

func throw_enemy(enemy, throw_velocity):
	enemy.throw(throw_velocity, throw_speed_scale)
	held_enemies.erase(enemy)
	enemy.deregister_contact_object_listener(on_grabbed_enemy_contact_object)
	enemy.deregister_death_listener(on_grabbed_enemy_die)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not is_playing_animation:
		if not is_recoiling:
			handle_controlled_move(delta)
		else:
			handle_sliding_move(delta)
		move_and_slide()
		
		rotate_enemy_around_player(delta)
		update_throw_arrow()
		# This chunk locks so that we wait for the animation to play
		is_playing_animation = true
		await handle_pickup()
		await handle_throw()
		is_playing_animation = false

var arrow_dict = {}

func teleport(pos: Vector2):
	global_position = pos
	camera.offset = pos

@onready var arrow_scene = preload("res://player/arrow.tscn")
func update_throw_arrow():
	for enemy in held_enemies:
		var arrow: Sprite2D = null

		if not arrow_dict.has(enemy):
			arrow = arrow_scene.instantiate()
			arrow_dict[enemy] = arrow
			arrow.top_level = true
			add_child(arrow)

		arrow = arrow_dict[enemy]
		arrow.global_position = enemy.global_position
		arrow.rotation = get_throw_direction(enemy).angle()

	var to_remove = []
	for entry in arrow_dict:
		if not held_enemies.has(entry):
			to_remove.append(entry)
	for enemy in to_remove:
		arrow_dict[enemy].queue_free()
		arrow_dict.erase(enemy)

func _on_pickup_hitbox_body_entered(body: Node2D) -> void:
	if body is Enemy and body.get_can_be_picked_up():
		add_nearby(body)


func _on_pickup_hitbox_body_exited(body: Node2D) -> void:
	remove_nearby(body)
