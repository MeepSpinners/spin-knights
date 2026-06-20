extends Area2D

var is_held = false
var is_flying = false
var holder = null
var health = 100
var velocity = Vector2.ZERO
var air_res = 5

func _ready() -> void:
	$enemy_hitbox.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.health <= 0:
		if (is_flying || is_held):
			self.explode()
		queue_free()
	elif is_flying:
		position += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, 50 * delta)
		if velocity == Vector2.ZERO:
			is_flying = false
			$pickuprange/pickupbox.disabled = false
			$enemy_hitbox.disabled = true
			$hitbox.disabled = false
	else:
		pass # put ai here
		
func throw(direction, throw_velocity):
	is_held = false
	is_flying = true
	holder = null
	velocity = direction * throw_velocity
	
func picked_up(player):
	is_held = true
	holder = player
	$pickuprange/pickupbox.disabled = true
	$enemy_hitbox.disabled = false
	$hitbox.disabled = true
	
func start(pos):
	position = pos
	show()

func _on_pickuprange_area_entered(area: Area2D) -> void:
	if area.has_method("add_nearby"):
		area.add_nearby(self) 


func _on_pickuprange_area_exited(area: Area2D) -> void:
	if area.has_method("remove_nearby"):
		area.remove_nearby(self) 


func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	self.health -= 5
	area.health -= 5
	
func explode():
	pass
