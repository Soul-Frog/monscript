class_name Particle
extends Polygon2D

@onready var _FADE = $Fade

var velocity: Vector2

signal fade_out_done

func init(particle_position, particle_velocity = Vector2(0, 0)) -> void:
		position = particle_position
		velocity = particle_velocity

func _process(delta: float) -> void:
		position += velocity * delta

func move(movement: Vector2) -> void:
		position += movement

func fade_out() -> void:
	_FADE.fade_out()

func fade_in() -> void:
	_FADE.fade_in()

func _on_fade_fade_out_done():
	emit_signal("fade_out_done", self)
