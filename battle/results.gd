extends Node2D

signal exit

@onready var _exit_button = $Exit

func _ready():
	modulate.a = 0
	_exit_button.disabled = true

func show_results(battle_results: Battle.BattleResult, xp_earned: int, bits_earned: int, bugs_earned: Array, mon_blocks: Array):
	# todo - update xp earned
	# todo - update bits earned
	# todo - show bugs earned
	
	await create_tween().tween_property(self, "modulate:a", 1, 0.2).finished
	_exit_button.disabled = false

func _on_exit_pressed():
	modulate.a = 0
	_exit_button.disabled = true
	emit_signal("exit")
