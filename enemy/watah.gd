extends Enemy

func apply_explosion_effect(enemy: Enemy):
	enemy.apply_status_effect(Freeze.new(5.0))
