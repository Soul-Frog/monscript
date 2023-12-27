extends Node2D

signal exit

@onready var _exit_button = $Exit

func _ready():
	modulate.a = 0
	_exit_button.disabled = true

func show_results(battle_results: Battle.BattleResult):
	await create_tween().tween_property(self, "modulate:a", 1, 0.2).finished
	_exit_button.disabled = false

func _on_exit_pressed():
	modulate.a = 0
	_exit_button.disabled = true
	emit_signal("exit")
