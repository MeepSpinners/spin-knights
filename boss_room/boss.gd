extends RangedEnemy

@onready var timer = $Timer

func activate():
	super.activate()
	timer.timeout.connect(on_timer_timeout)
	timer.start()
	on_timer_timeout()
	die.connect(on_boss_death)

func on_boss_death(enemy):
	Progress.cleared_boss()

@onready var meteor = preload("res://boss_room/meteor.tscn")
func on_timer_timeout():
	for i in 3:
		await get_tree().create_timer(1, true, false ,false).timeout
		var m = meteor.instantiate()
		get_parent().add_child(m)
		m.global_position = get_tree().get_first_node_in_group("Player").global_position
