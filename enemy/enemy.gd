extends CharacterBody2D

class_name Enemy

@onready var animated_sprite: AnimatedSprite2D = $Anime
@onready var thwack_audio = $thwack_audio
@onready var explode_audio = $explode_audio
@onready var nav_agent = $NavigationAgent2D
@onready var status_sprite: Sprite2D = $status_sprite

@export var health = 4
@export var friction = 60
@export var contact_damage = 1
@export var flying_damage = 2
var base_explosion_damage = 2
var base_explosion_range = 27.0
var additional_explosion_damage = 0
var additional_explosion_range = 0.0
@export var recoil_speed = 40
@export var ai_speed = 5
@export var decision_speed = 1
@export var flee_dist = 8
@export var wander_proportion = 0.2
@export var flee_modifier = 0.9
@export var explosion_knockback = 100.0
var max_health = 100

var activated = false

func update_explosion_damage(damage: float):
	additional_explosion_damage = damage

func update_explosion_range(range: float):
	additional_explosion_range = range
	var explosion_scale = base_explosion_range + additional_explosion_range
	explosion_hitbox.scale = Vector2(
		explosion_scale, explosion_scale
	)

func activate():
	activated = true

var base_animation_speed = 1.0

var active_tags = []

var can_be_picked_up = true

func get_can_be_picked_up():
	return can_be_picked_up

signal contact_object(grabbed_enemy: Enemy, object: Object)
signal die(enemy: Enemy)

var timed_out_attackers = []

var status_effects: Dictionary[String, StatusEffect] = {}

func apply_status_effect(status: StatusEffect):
	if (status_effects.has(status.data.id)):
		status_effects[status.data.id].override(status, self)
		return
	status_effects[status.data.id] = status
	status.apply(self)
	status_sprite.texture = status.data.icon
	status_sprite.modulate.a = 1.0

enum State {
	AI,
	ATTACKING,
	RECOILING,
	FLYING,
	HELD,
	DEAD
}

enum Behaviour {
	WANDER,
	CHASE,
	FLEE
}

var state = State.AI
var behaviour = Behaviour.WANDER
var decision_timer = 0.0
var bounce_count = 0

func _ready() -> void:
	max_health = health
	$HealthBar.set_health(health, max_health)
	enter_state(State.AI)
	await get_tree().physics_frame
	choose_behaviour()

class CollisionOutcome:
	var v1: Vector2
	var v2: Vector2
	
	func _init(p_v1, p_v2):
		self.v1 = p_v1
		self.v2 = p_v2
	func _to_string() -> String:
		return "v1: " + str(v1) + ", v2: " + str(v2)

func inelastic_collision(p_velocity: Vector2, normal: Vector2) -> CollisionOutcome:
	return CollisionOutcome.new(
		p_velocity.slide(normal) * 0.6,
		-normal * p_velocity.length() * 0.4)

func handle_friction_glide(delta: float, on_finish_glide: Callable):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if (state != State.DEAD):
		animated_sprite.speed_scale = base_animation_speed * velocity.length() / 10.0
	var collision_info = move_and_collide(velocity * delta)
	
	# ONLY FOR STATIC COLLISIONS
	if collision_info:
		var collider = collision_info.get_collider()
		var normal = collision_info.get_normal()
		if collider is Enemy:
			var outcome = inelastic_collision(velocity, normal)
			launch_with_velocity(outcome.v1)
			collider.launch_with_velocity(outcome.v2)
		else:
			velocity = velocity.bounce(normal) * 0.4
			launch_with_velocity(velocity)
		
		thwack_audio.play()
		
		if bounce_count < 1:
			hit_object(collider)
		bounce_count += 1

	if velocity.is_zero_approx():
		on_finish_glide.call()

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

func get_animation_state(dir: Vector2):
	var angle = dir.normalized().angle()
	if angle < -7 * PI / 8 or angle >= 7 * PI / 8:
		return AnimationState.new("_right", true, 2, "left")
	elif angle < -5 * PI / 8:
		return AnimationState.new("_right", true, 3, "back-left")
	elif angle < -3 * PI / 8:
		return AnimationState.new("", false, 4, "back")
	elif angle < -PI / 8:
		return AnimationState.new("_right", false, 5, "back-right")
	elif angle < PI / 8:
		return AnimationState.new("_right", false, 6, "right")
	elif angle < 3 * PI / 8:
		return AnimationState.new("_right", false, 7, "front-right")
	elif angle < 5 * PI / 8:
		return AnimationState.new("", false, 0, "front")
	else:
		return AnimationState.new("_right", true, 1, "front-left")
	
func handle_ai(delta: float):
	decision_timer += delta
	if decision_timer >= decision_speed:
		decision_timer = 0.0
		choose_behaviour()
	if (active_tags.has("always_flee")):
		behaviour = Behaviour.FLEE
	match behaviour:
		Behaviour.WANDER:
			pass
		Behaviour.CHASE:
			nav_agent.target_position = get_tree().get_first_node_in_group("Player").global_position
		Behaviour.FLEE:
			var dir = get_tree().get_first_node_in_group("Player").global_position.direction_to(self.global_position)
			nav_agent.target_position = self.global_position + dir * flee_dist
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next = nav_agent.get_next_path_position()
	velocity = self.global_position.direction_to(next) * ai_speed
	
	animated_sprite.speed_scale = base_animation_speed * 1.0
	var animation_state = get_animation_state(velocity)
	if (velocity.is_zero_approx()):
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walking_down" + animation_state.suffix)
		animated_sprite.flip_h = animation_state.flip_h
	
	move_and_slide()
	for i in get_slide_collision_count():
		var collision_info = get_slide_collision(i)
		var collider = collision_info.get_collider()
		hit_object(collider)

func choose_behaviour():
	var flee_chance = float(self.max_health - self.health) / self.max_health * flee_modifier
	var remaining = 1 - flee_chance
	var wander_chance = flee_chance + remaining * wander_proportion
	var action = randf()
	if action <= flee_chance:
		behaviour = Behaviour.FLEE
	elif action <= wander_chance:
		behaviour = Behaviour.WANDER
		var map = nav_agent.get_navigation_map()
		if map:
			nav_agent.target_position = NavigationServer2D.map_get_random_point(map, 1, false)
	else:
		behaviour = Behaviour.CHASE

func get_recoil_flash_modifier(time: float):
	return max(0.0, 1.0 - time * 2.0)

var time_since_entered_recoil = 10.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if not activated:
		return
	
	set_flash_modifier(
		get_recoil_flash_modifier(time_since_entered_recoil))
	time_since_entered_recoil += delta
	
	match state:
		State.DEAD:	
			handle_friction_glide(delta, func(): pass)
		State.FLYING:
			handle_friction_glide(delta, func(): enter_state(State.AI))
		State.RECOILING:
			handle_friction_glide(delta, func(): enter_state(State.AI))
		State.AI:
			handle_ai(delta)
	
func _process(delta: float) -> void:
	
	if not activated:
		return

	var to_be_destroyed: Array[String] = []
	
	var longest_status_duration: float = 0.0
	var longest_status: StatusEffect = null
	for id in status_effects:
		var status = status_effects[id]
		status.tick(self, delta)
		var duration_left = status.duration - status.total_time_passed
		if (duration_left > longest_status_duration):
			longest_status = status
			longest_status_duration = duration_left
		if (status.has_ended()):
			to_be_destroyed.append(id)
	for id in to_be_destroyed:
		status_effects[id].clear(self)
		status_effects.erase(id)
	if (longest_status != null):
		status_sprite.modulate.a = 1.0 - longest_status.total_time_passed / longest_status.duration
enum Layers {
	PLAYER = 0,
	ENEMY = 1,
	HELD_ENEMY = 2,
	STATIC_OBJECT = 3
}

func toggle_enemy_can_be_picked_up(p_can_be_picked_up: bool):
	self.can_be_picked_up = p_can_be_picked_up
	
func clear_timed_out_attackers():
	timed_out_attackers.clear()

func set_flash_modifier(progress: float):
	animated_sprite.set_instance_shader_parameter("flash_modifier", progress)

func trigger_flash():
	time_since_entered_recoil = 0.0
	
func enter_state(new_state: State):
	match new_state:
		State.AI:
			if (not state in [State.ATTACKING, State.RECOILING, State.FLYING]):
				return
			velocity = Vector2.ZERO
			# Become ENEMY layer, and only damage PLAYER layer
			collision_layer = 1 << Layers.ENEMY
			collision_mask = 0
			$enemy_hitbox.collision_mask = 1 << Layers.PLAYER
			animated_sprite.speed_scale = base_animation_speed * 1.0
			toggle_enemy_can_be_picked_up(true)
			clear_timed_out_attackers()
		State.ATTACKING:
			pass # Not sure if there is a point in this existing actually
		State.RECOILING:
			if (not state in [State.AI, State.ATTACKING]):
				return
			# This state is just so the AI is not controlling it
			collision_layer = 1 << Layers.ENEMY
			collision_mask = 1 << Layers.STATIC_OBJECT
			$enemy_hitbox.collision_mask = 1 << Layers.PLAYER
			animated_sprite.speed_scale = base_animation_speed * 1.0
			toggle_enemy_can_be_picked_up(false)
		State.FLYING:
			if (not state in [State.HELD]):
				return
			bounce_count = 0
			collision_layer = 0 # No one can touch me
			collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT
			$enemy_hitbox.collision_mask = 0
			animated_sprite.speed_scale = base_animation_speed * 1.0
			toggle_enemy_can_be_picked_up(false)
		State.HELD:
			collision_layer = 1 << Layers.HELD_ENEMY
			$enemy_hitbox.collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT
			toggle_enemy_can_be_picked_up(false)
			animated_sprite.speed_scale = base_animation_speed * 2.0
			animated_sprite.play("flailing_down")
		State.DEAD:
			collision_layer = 0 # No one can touch me
			$enemy_hitbox.collision_mask = 0 # I can't hit anyone
			toggle_enemy_can_be_picked_up(false)
			animated_sprite.speed_scale = base_animation_speed * 1.0
			animated_sprite.play("death")
			status_sprite.visible = false
		_:
			print("Unknown state probably gonna crash")
	state = new_state

func register_contact_object_listener(listener: Callable) -> void:
	if not contact_object.is_connected(listener):
		contact_object.connect(listener)

func deregister_contact_object_listener(listener: Callable) -> void:
	if contact_object.is_connected(listener):
		contact_object.disconnect(listener)

func register_death_listener(listener: Callable) -> void:
	if not die.is_connected(listener):
		die.connect(listener)

func deregister_death_listener(listener: Callable) -> void:
	if die.is_connected(listener):
		die.disconnect(listener)

func throw(direction, throw_velocity):
	enter_state(State.FLYING)
	velocity = direction * throw_velocity

func picked_up():
	enter_state(State.HELD)
	
func start(pos):
	position = pos
	show()

func launch_in_direction(direction: Vector2, amount: float):
	launch_with_velocity(direction * amount)

func launch_with_velocity(p_velocity: Vector2):
	enter_state(State.RECOILING)
	self.velocity = p_velocity
	var animation_state = get_animation_state(-velocity)
	
	if (state != State.DEAD):
		animated_sprite.play("flailing_down" + animation_state.suffix)
		animated_sprite.flip_h = animation_state.flip_h

func take_damage(damage: float, by_whom: Object):
	if timed_out_attackers.has(by_whom):
		return
	
	self.health -= damage
	$HealthBar.set_health(health, max_health)

	trigger_flash()
	if (by_whom != null):
		enter_state(State.RECOILING)
		timed_out_attackers.append(by_whom)

	if self.health <= 0:
		if (state == State.FLYING || state == State.HELD):
			self.explode()
		enter_state(State.DEAD)
		die.emit(self)
		await get_tree().create_timer(2.0, true, false, false).timeout
		queue_free()

# FOR HITTING OTHER ENEMIES AS A HELD ENEMY
func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	match state:
		State.HELD:
			contact_object.emit(self, body)
		State.AI:
			if body is Player:
				body.take_damage(contact_damage, self, 5.0)

func hit_object(obj: Object) -> void:
	match state:
		State.FLYING:
			take_damage(flying_damage, null)
			if (obj.has_method("take_damage")):
				obj.take_damage(flying_damage, self)
		State.AI:
			if (obj.has_method("take_damage")):
				obj.take_damage(contact_damage, self, 2)

func apply_explosion_effect(enemy: Enemy):
	pass

func get_explosion_scene() -> PackedScene:
	return preload("res://explosion/explosion.tscn")

@onready var explosion_hitbox = $explosion_hitbox

func explode():
	explode_audio.play()
	var explosion_scene = get_explosion_scene()
	if explosion_scene:
		var instance: Explosion = explosion_scene.instantiate()
		instance.start(explosion_hitbox.global_position, explosion_hitbox.scale.x)
		get_parent().add_child(instance)
	
	var enemies = $explosion_hitbox.get_overlapping_bodies()
	for enemy in enemies:
		if (enemy is Enemy):
			enemy.take_damage(base_explosion_damage + additional_explosion_damage, self)
			apply_explosion_effect(enemy)
			enemy.launch_in_direction(
				global_position.direction_to(enemy.global_position), explosion_knockback)
