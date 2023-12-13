extends Node2D

enum _Direction {
	UP, DOWN
}

@onready var atk_arrows = $ArrowContainer/AttackArrows
@onready var def_arrows = $ArrowContainer/DefenseArrows
@onready var spd_arrows = $ArrowContainer/SpeedArrows

func _ready() -> void:
	assert(atk_arrows)
	assert(def_arrows)
	assert(spd_arrows)
	assert(atk_arrows.get_child_count() == BattleMon.MAX_BUFF_STAGE and atk_arrows.get_child_count() == abs(BattleMon.MIN_DEBUFF_STAGE))
	assert(def_arrows.get_child_count() == BattleMon.MAX_BUFF_STAGE and def_arrows.get_child_count() == abs(BattleMon.MIN_DEBUFF_STAGE))
	assert(spd_arrows.get_child_count() == BattleMon.MAX_BUFF_STAGE and spd_arrows.get_child_count() == abs(BattleMon.MIN_DEBUFF_STAGE))
	reset()

# Updates the arrows of the given container to match the given stat stage number
func update_arrows(container: BoxContainer, stat_stage: int) -> void:
	assert(abs(stat_stage) <= container.get_child_count(), "Not enough arrows to represent this stat stage!")
	
	var stage = abs(stat_stage)
	var should_flip_v = stat_stage >= 0
	
	var i = 1
	for arrow in container.get_children():
		arrow.visible = i <= stage
		arrow.flip_v = should_flip_v
		i += 1

func reset() -> void:
	update_arrows(atk_arrows, 0)
	update_arrows(def_arrows, 0)
	update_arrows(spd_arrows, 0)

func on_stats_changed(mon: BattleMon) -> void:
	update_arrows(atk_arrows, mon.atk_buff_stage)
	update_arrows(def_arrows, mon.def_buff_stage)
	update_arrows(spd_arrows, mon.spd_buff_stage)
