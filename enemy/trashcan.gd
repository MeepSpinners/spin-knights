extends Enemy

func apply_explosion_effect(enemy: Enemy):
	enemy.apply_status_effect(Disgusted.new(5.0))
