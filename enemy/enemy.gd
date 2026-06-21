extends CharacterBody2D

class_name Enemy

@export var health = 100
@export var friction = 600
@export var contact_damage = 5
@export var flying_damage = 5
@export var recoil_speed = 400

var can_be_picked_up = true

func get_can_be_picked_up():
	return can_be_picked_up

signal contact_object(grabbed_enemy: Enemy, object: Node2D)
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

var state = State.AI

func _ready() -> void:
	enter_state(State.AI)

func handle_friction_glide(delta: float, on_finish_glide: Callable):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if velocity == Vector2.ZERO:
		on_finish_glide.call()

func get_recoil_flash_modifier(time: float):
	return max(0.0, 1.0 - time * 2.0)

var time_since_entered_recoil = 10.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_debug_label()
	
	set_flash_modifier(
		get_recoil_flash_modifier(time_since_entered_recoil))
	time_since_entered_recoil += delta
	
	match state:
		State.DEAD:
			handle_friction_glide(delta, func(): pass)
			move_and_slide()
		State.FLYING:
			handle_friction_glide(delta, func(): enter_state(State.AI))
			move_and_slide()
		State.RECOILING:
			# This has to be at the end to reset the flash modifier
			handle_friction_glide(delta, func(): enter_state(State.AI))
			move_and_slide()
		State.AI:
			move_and_slide()
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
			velocity = Vector2.ZERO
			# Become ENEMY layer, and only damage PLAYER layer
			collision_layer = 1 << Layers.ENEMY
			$enemy_hitbox.collision_mask = 1 << Layers.PLAYER | 1 << Layers.STATIC_OBJECT
			toggle_enemy_can_be_picked_up(true)
			clear_timed_out_attackers()
			# Clear the flashing display
			set_flash_modifier(0.0)
		State.ATTACKING:
			pass # Not sure if there is a point in this existing actually
		State.RECOILING:
			# This state is just so the AI is not controlling it
			collision_layer = 1 << Layers.ENEMY
			$enemy_hitbox.collision_mask = 1 << Layers.PLAYER | 1 << Layers.STATIC_OBJECT
			toggle_enemy_can_be_picked_up(false)
			set_flash_modifier(0.0)
		State.FLYING:
			collision_layer = 0 # No one can touch me
			$enemy_hitbox.collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT # I can only hit enemies (will need to add walls)
			toggle_enemy_can_be_picked_up(false)
			set_flash_modifier(0.0)
		State.HELD:
			collision_layer = 1 << Layers.HELD_ENEMY
			$enemy_hitbox.collision_mask = 1 << Layers.ENEMY | 1 << Layers.STATIC_OBJECT # I can only hit enemies (will need to add walls)
			toggle_enemy_can_be_picked_up(false)
			set_flash_modifier(0.0)
		State.DEAD:
			collision_layer = 0 # No one can touch me
			$enemy_hitbox.collision_mask = 0 # I can't hit anyone
			toggle_enemy_can_be_picked_up(false)
			set_flash_modifier(0.0)
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

func take_damage(damage: float, recoil_source: Node2D, recoil_amount: float = 1.0):
	if timed_out_attackers.has(recoil_source):
		return

	self.health -= damage

	trigger_flash()
	if (recoil_source != null):
		enter_state(State.RECOILING)
		velocity = Vector2.from_angle(recoil_source.get_angle_to(global_position)) * recoil_speed * recoil_amount
		timed_out_attackers.append(recoil_source)

	if self.health <= 0:
		die.emit(self)
		if (state == State.FLYING || state == State.HELD):
			self.explode()
		enter_state(State.DEAD)
		await get_tree().create_timer(2.0, true, false, false).timeout
		queue_free()

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:

	match state:
		State.FLYING:
			take_damage(flying_damage, null)
			if (body.has_method("take_damage")):
				body.take_damage(flying_damage, self)
		State.HELD:
			contact_object.emit(self, body)
		State.AI:
			if (body.has_method("take_damage")):
				body.take_damage(contact_damage, self, 2)

func explode():
	var enemies = $explosion_hitbox.get_overlapping_areas()
	for enemy in enemies:
		if (enemy is Enemy):
			enemy.take_damage(100, self, 5.0)

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
	var current_mask_bitmask = collision_mask
	
	if current_mask_bitmask & (1 << Layers.PLAYER): active_masks.append("Player")
	if current_mask_bitmask & (1 << Layers.ENEMY): active_masks.append("Enemy")
	if current_mask_bitmask & (1 << Layers.HELD_ENEMY): active_masks.append("Held Enemy")
	
	debug_text += "\nLayers: " + (", ".join(active_layers) if active_layers.size() > 0 else "None")
	debug_text += "\nTargets: " + (", ".join(active_masks) if active_masks.size() > 0 else "None")
	
	debug_label.text = debug_text
	
	debug_label.text += "\nVelocity: " + str(velocity)
	debug_label.text += "\nFlash mod: " + str($Sprite2D.material.get_shader_parameter("flash_modifier"))
