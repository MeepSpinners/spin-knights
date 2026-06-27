extends Enemy

class_name RangedEnemy

@export var projectile_scene: PackedScene
@export var engage_range = 85.0
@export var kite_range = 65.0
@export var kite_buffer = 8.0
@export var fire_cd = 1.4
@export var proj_speed = 2.5
@export var proj_damage = 1.0
@export var proj_recoil = 3.0
@export var lead_shots = false
@export var max_extra_range = 100.0

var shot_timer = 0.0

func _ready() -> void:
	lead_shots = randf() >= 0.5

func handle_ai(delta: float):
	shot_timer -= delta
	var player = get_tree().get_first_node_in_group("Player")
	var to_player: Vector2 = player.global_position - self.global_position
	var dist = to_player.length()
	var standing_range = kite_range + max_extra_range * float(max_health - health) / max_health
	if dist <= engage_range and shot_timer <= 0.0:
		fire_at(player)
		shot_timer = fire_cd

	if dist > standing_range + kite_buffer:
		$NavigationAgent2D.target_position = player.global_position
	elif dist < standing_range - kite_buffer:
		$NavigationAgent2D.target_position = self.global_position - to_player.normalized() * (standing_range - dist + kite_buffer)
	else:
		$NavigationAgent2D.target_position = self.global_position

	if $NavigationAgent2D.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		velocity = self.global_position.direction_to($NavigationAgent2D.get_next_path_position()) * ai_speed

	animated_sprite.speed_scale = 1.0
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
		
func fire_at(target):
	var origin = self.global_position
	var dir: Vector2
	if lead_shots:
		dir = lead_direction(origin, target)
	else:
		dir = (target.global_position - origin).normalized()
		
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	print("spd1:" + str(proj_speed))
	proj.setup(origin, dir * proj_speed, proj_damage, proj_recoil, self)
	print(proj.velocity)

func lead_direction(origin, target):
	var target_velocity: Vector2 = target.velocity if "velocity" in target else Vector2.ZERO
	var to_target:Vector2 = target.global_position - origin
	var a:float = target_velocity.dot(target_velocity) - proj_speed * proj_speed
	var b:float = 2.0 * to_target.dot(target_velocity)
	var c:float = to_target.dot(to_target)
	var t:float = 0.0
	
	if absf(a) < 0.0001:
		if absf(b) > 0.0001:
			t = -c / b
	else:
		var discrim = (b * b) - (4 * a * c)
		if discrim >= 0.0:
			var sq = sqrt(discrim)
			var t1 = (-b - sq) / (a * 2.0)
			var t2 = (-b + sq) / (a * 2.0)
			t = INF
			if t1 > 0.0:
				t = t1
			if t2 > 0.0 and t2 < t:
				t = t2
			if t == INF:
				t = 0.0
	var aim = target.global_position + target_velocity * maxf(t, 0.0)
	return (aim - origin).normalized()
