extends Area2D

@export var health = 100
@export var air_res = 600
@export var contact_damage = 5
@export var flying_damage = 5
@export var recoil_speed = 400

var velocity = Vector2.ZERO

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_debug_label()
	match state:
		State.FLYING, State.RECOILING:
			position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO, air_res * delta)
			if velocity == Vector2.ZERO:
				enter_state(State.AI)
		State.AI:
			pass

enum Layers {
	PLAYER = 0,
	ENEMY = 1,
	HELD_ENEMY = 2
}

func toggle_enemy_can_be_picked_up(can_be_picked_up: bool):
	$pickuprange/pickupbox.set_deferred("disabled", not can_be_picked_up)
	
func clear_timed_out_attackers():
	timed_out_attackers.clear()
	
func enter_state(new_state: State):
	match new_state:
		State.AI:
			velocity = Vector2.ZERO
			# Become ENEMY layer, and only damage PLAYER layer
			collision_layer = 1 << Layers.ENEMY
			collision_mask = 1 << Layers.PLAYER
			toggle_enemy_can_be_picked_up(true)
			clear_timed_out_attackers()
		State.ATTACKING:
			pass # Not sure if there is a point in this existing actually
		State.RECOILING:
			# This state is just so the AI is not controlling it
			collision_layer = 1 << Layers.ENEMY
			collision_mask = 1 << Layers.PLAYER
			toggle_enemy_can_be_picked_up(false)
		State.FLYING:
			collision_layer = 0 # No one can touch me
			collision_mask = 1 << Layers.ENEMY # I can only hit enemies (will need to add walls)
			toggle_enemy_can_be_picked_up(false)
		State.HELD:
			collision_layer = 1 << Layers.HELD_ENEMY
			collision_mask = 1 << Layers.ENEMY # I can only hit enemies (will need to add walls)
			toggle_enemy_can_be_picked_up(false)
		State.DEAD:
			collision_layer = 0 # No one can touch me
			collision_mask = 0 # I can't hit anyone
			toggle_enemy_can_be_picked_up(false)
		_:
			print("Unknown state probably gonna crash")
	state = new_state

func throw(direction, throw_velocity):
	enter_state(State.FLYING)
	velocity = direction * throw_velocity
	
func picked_up():
	enter_state(State.HELD)
	
func start(pos):
	position = pos
	show()

func _on_pickuprange_area_entered(area: Area2D) -> void:
	if area.has_method("add_nearby"):
		area.add_nearby(self)

func _on_pickuprange_area_exited(area: Area2D) -> void:
	if area.has_method("remove_nearby"):
		area.remove_nearby(self)

func take_damage(damage: float, by_whom: Node2D):
	self.health -= damage
	
	if (by_whom != null):
		enter_state(State.RECOILING)
		velocity = Vector2.from_angle(by_whom.get_angle_to(global_position)) * recoil_speed

	if self.health <= 0:
		if (state == State.FLYING || state == State.HELD):
			self.explode()
		enter_state(State.DEAD)

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	print("self: ", self, ", area: ", area)
	match state:
		State.FLYING:
			take_damage(flying_damage, null)
			if (area.has_method("take_damage")):
				area.take_damage(flying_damage, self)
		State.HELD:
			take_damage(contact_damage, null)
			if (area.has_method("take_damage")):
				area.take_damage(contact_damage, self)
		State.AI:
			if (area.has_method("take_dmamage")):
				area.take_damage(contact_damage, self)

func explode():
	pass

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
