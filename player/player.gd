extends Node2D
@export var speed = 650
var held_enemies = []
var nearby_enemies = []
var max_held = 1
var screen_size
var throw_speed = 200
var orbit_radius = 100
var orbit_speed = 100
var health = 100
var just_pick = false
var just_throw = false
var is_busy = false
var last_dir = Vector2.DOWN
var is_rotate = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_busy:
		var velocity = Vector2.ZERO # The player's movement vector.
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1
		if Input.is_action_pressed("move_down"):
			velocity.y += 1
		if Input.is_action_pressed("move_up"):
			velocity.y -= 1
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
		position += velocity * delta
		for enemy in held_enemies:
			enemy.global_position += velocity * delta
		
		if Input.is_action_just_pressed("interact"):
			if (held_enemies.size() < max_held && nearby_enemies.size() > 0):
				grab_enemy(nearby_enemies[0])
				just_pick = true
		
		if Input.is_action_just_pressed("throw"):
			if held_enemies.size() > 0:
				for enemy in held_enemies:
					throw_enemy(enemy)
				just_throw = true
				
	for enemy in held_enemies:
		var dist = self.global_position.distance_to(enemy.global_position)
		var new_dist = move_toward(dist, orbit_radius, orbit_speed * delta)
		var angle = self.global_position.angle_to_point(enemy.global_position)
		enemy.global_position = self.global_position + Vector2(cos(angle + deg_to_rad(2 * orbit_speed * delta)), sin(angle + deg_to_rad(2 * orbit_speed * delta))) * new_dist
	if not is_busy:
		var dir = Vector2.ZERO
		dir.x = Input.get_axis("move_left","move_right")
		dir.y = Input.get_axis("move_up","move_down")
		var is_moving = dir != Vector2.ZERO
		if is_moving:
			last_dir = dir
		var state = get_suffix(last_dir)
		
		if just_pick:
			$Anime.play("interact" + state[0])
			$Anime.flip_h = state[1]
			await $Anime.animation_finished
			just_pick = false
		elif held_enemies.size() > 0:
			if not is_rotate:
				is_rotate = true
				$Anime.flip_h = false
				$Anime.play("rotate")
				var a = fposmod(last_dir.angle(), 2 * PI)
				$Anime.frame = (2 - int(round(4 * a / PI))) % 8
		else:
			is_rotate = false
			
		if just_throw:
			$Anime.play("attack" + state[0])
			$Anime.flip_h = state[1]
			await $Anime.animation_finished
			just_throw = false
		if held_enemies.size() == 0:
			var prefix = "walk" if is_moving else "idle"
			$Anime.play(prefix + state[0])
			$Anime.flip_h = state[1]

func get_suffix(dir: Vector2):
	var angle = dir.normalized().angle()
	if angle < -7 * PI / 8 or angle >= 7 * PI / 8:
		return ["_right", true]
	elif angle < -5 * PI / 8:
		return ["_back_diag", true]
	elif angle < -3 * PI / 8:
		return ["_back", false]
	elif angle < -PI / 8:
		return ["_back_diag", false]
	elif angle < PI / 8:
		return ["_right", false]
	elif angle < 3 * PI / 8:
		return ["_front_diag", false]
	elif angle < 5 * PI / 8:
		return ["_front", false]
	else:
		return ["_front_diag", true]

func grab_enemy(enemy):
	held_enemies.append(enemy)
	enemy.picked_up(self)
	remove_nearby(enemy)
	
func throw_enemy(enemy):
	enemy.throw(self.global_position.direction_to(enemy.global_position).rotated(PI/2), throw_speed)
	held_enemies.erase(enemy)
	
func add_nearby(enemy):
	nearby_enemies.append(enemy)

func remove_nearby(enemy):
	nearby_enemies.erase(enemy)
	
func start(pos):
	position = pos
	show()

func _on_area_entered(area: Area2D) -> void:
	self.health -= 5
