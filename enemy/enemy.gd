extends CharacterBody2D

class_name Enemy

@export var health = 100
@export var friction = 600
@export var contact_damage = 5
@export var flying_damage = 50
@export var recoil_speed = 400
@export var ai_speed = 50
@export var decision_speed = 1
@export var flee_dist = 80
@export var wander_proportion = 0.2
@export var flee_modifier = 0.9
var max_health = 100

var can_be_picked_up = true

func get_can_be_picked_up():
	return can_be_picked_up

signal contact_object(grabbed_enemy: Enemy, object: Object)
signal die(enemy: Enemy)

var timed_out_attackers = []

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

func _ready() -> void:
	max_health = health
	$HealthBar.set_health(health, max_health)
	enter_state(State.AI)
	await get_tree().physics_frame
	choose_behaviour()

class CollisionOutcome:
	var v1: Vector2
	var v2: Vector2
	
	func _init(v1, v2):
		self.v1 = v1
		self.v2 = v2
	func _to_string() -> String:
		return "v1: " + str(v1) + ", v2: " + str(v2)

func inelastic_collision(velocity: Vector2, normal: Vector2) -> CollisionOutcome:
	return CollisionOutcome.new(
		velocity.slide(normal) * 0.6,
		-normal * velocity.length() * 0.4)

func handle_friction_glide(delta: float, on_finish_glide: Callable):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var collision_info = move_and_collide(velocity * delta)
	
	# ONLY FOR STATIC COLLISIONS
	if collision_info:
		var collider = collision_info.get_collider()
		var normal = collision_info.get_normal()
		if collider is Enemy:
			var outcome = inelastic_collision(velocity, normal)
			launch_with_velocity(outcome.v1)
			collider.launch_with_velocity(outcome.v2)
			hit_object(collider)
		else:
			velocity = velocity.bounce(normal) * 0.4
			launch_with_velocity(velocity)

	if velocity.is_zero_approx():
		on_finish_glide.call()

func handle_ai(delta: float):
	decision_timer += delta
	if decision_timer >= decision_speed:
		decision_timer = 0.0
		choose_behaviour()
	match behaviour:
		Behaviour.WANDER:
			pass
		Behaviour.CHASE:
			$NavigationAgent2D.target_position = get_parent().get_node("player").global_position
		Behaviour.FLEE:
			var dir = get_parent().get_node("player").global_position.direction_to(self.global_position)
			$NavigationAgent2D.target_position = self.global_position + dir * flee_dist
	if $NavigationAgent2D.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next = $NavigationAgent2D.get_next_path_position()
	velocity = self.global_position.direction_to(next) * ai_speed

func choose_behaviour():
	var flee_chance = (self.max_health - self.health) / self.max_health * flee_modifier
	var remaining = 1 - flee_chance
	var wander_chance = flee_chance + remaining * wander_proportion
	var action = randf()
	if action <= flee_chance:
		behaviour = Behaviour.FLEE
	elif action <= wander_chance:
		behaviour = Behaviour.WANDER
		var map = $NavigationAgent2D.get_navigation_map()
		$NavigationAgent2D.target_position = NavigationServer2D.map_get_random_point(map, 1, false)
	else:
		behaviour =Behaviour.CHASE

func get_recoil_flash_modifier(time: float):
	return max(0.0, 1.0 - time * 2.0)

var time_since_entered_recoil = 10.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_debug_label()
	
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
			move_and_slide()
			for i in get_slide_collision_count():
				var collision_info = get_slide_collision(i)
				var collider = collision_info.get_collider()
				hit_object(collider)
			pass
		

enum Layers {
	PLAYER = 0,
	ENEMY = 1,
	HELD_ENEMY = 2,
	STATIC_OBJECT = 3
}

func toggle_enemy_can_be_picked_up(can_be_picked_up: bool):
	self.can_be_picked_up = can_be_picked_up
	
func clear_timed_out_attackers():
	timed_out_attackers.clear()

func set_flash_modifier(progress: float):
	$Sprite2D.set_instance_shader_parameter("flash_modifier", progress)

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
			toggle_enemy_can_be_picked_up(false)
		State.FLYING:
			if (not state in [State.HELD]):
				return
			collision_layer = 0 # No one can touch me
			collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT
			$enemy_hitbox.collision_mask = 0
			toggle_enemy_can_be_picked_up(false)
		State.HELD:
			collision_layer = 1 << Layers.HELD_ENEMY
			$enemy_hitbox.collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT
			toggle_enemy_can_be_picked_up(false)
		State.DEAD:
			collision_layer = 0 # No one can touch me
			$enemy_hitbox.collision_mask = 0 # I can't hit anyone
			toggle_enemy_can_be_picked_up(false)
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

func launch_with_velocity(velocity: Vector2):
	enter_state(State.RECOILING)
	self.velocity = velocity

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

func explode():
	var enemies = $explosion_hitbox.get_overlapping_bodies()
	for enemy in enemies:
		if (enemy is Enemy):
			enemy.take_damage(100, self)
			enemy.launch_in_direction(
				global_position.direction_to(enemy.global_position), 1000.0)

@onready var debug_label = $DebugLabel

func update_debug_label():
	var state_string
	match state:
		State.AI:
			state_string = "AI"
		State.ATTACKING:
			state_string = "ATTACKING"
		State.RECOILING:
			state_string = "RECOILING"
		State.FLYING:
			state_string = "FLYING"
		State.HELD:
			state_string = "HELD"
		State.DEAD:
			state_string = "DEAD"
	
	var debug_text = "State: " + state_string
	debug_text += "\nHP: " + str(health)
	
	var active_layers = []
	var current_layer_bitmask = collision_layer
	
	if current_layer_bitmask & (1 << Layers.PLAYER): active_layers.append("Player")
	if current_layer_bitmask & (1 << Layers.ENEMY): active_layers.append("Enemy")
	if current_layer_bitmask & (1 << Layers.HELD_ENEMY): active_layers.append("Held Enemy")
	
	var active_masks = []
	var current_mask_bitmask = $enemy_hitbox.collision_mask
	
	if current_mask_bitmask & (1 << Layers.PLAYER): active_masks.append("Player")
	if current_mask_bitmask & (1 << Layers.ENEMY): active_masks.append("Enemy")
	if current_mask_bitmask & (1 << Layers.HELD_ENEMY): active_masks.append("Held Enemy")
	
	debug_text += "\nLayers: " + (", ".join(active_layers) if active_layers.size() > 0 else "None")
	debug_text += "\nTargets: " + (", ".join(active_masks) if active_masks.size() > 0 else "None")
	
	debug_label.text = debug_text
	
	debug_label.text += "\nVelocity: " + str(velocity)
	debug_label.text += "\nFlash mod: " + str($Sprite2D.material.get_shader_parameter("flash_modifier"))
	if state == State.AI:
		debug_label.text += "\nBehaviour: " + str(Behaviour.keys()[behaviour])
