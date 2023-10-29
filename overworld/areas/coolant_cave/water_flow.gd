extends PushZone

@export var MIN_PARTICLE_SPEED = 6
@export var MAX_PARTICLE_SPEED = 20
@export var PARTICLE_COUNT = 100

class Particle:
	var rect: Rect2
	var color: Color
	var velocity: Vector2
	
	func _init(particle_rect = Rect2(0, 0, 1, 1), particle_color = Color.WHITE, particle_velocity = Vector2(0, 0)) -> void:
		rect = particle_rect
		color = particle_color
		velocity = particle_velocity
	
	func update(delta: float) -> void:
		rect.position += velocity * delta
	
	func translate(movement: Vector2) -> void:
		rect.position += movement

var _particles = []

func _ready():
	assert(MIN_PARTICLE_SPEED <= MAX_PARTICLE_SPEED)
	
	var min_x = Global.INT_MAX
	var max_x = Global.INT_MIN
	var min_y = Global.INT_MAX
	var max_y = Global.INT_MIN
	for i in $Collision.polygon.size():
		var point = $Collision.polygon[i]
		min_x = min(point.x, min_x)
		min_y = min(point.y, min_y)
		max_x = max(point.x, max_x)
		max_y = max(point.y, max_y)
	
	for i in PARTICLE_COUNT:
		var placed = false
		
		while not placed:
			# generate a random point inside the polygon
			var placement = Vector2(Global.RNG.randi_range(min_x, max_x), Global.RNG.randi_range(min_y, max_y))
			
			# make sure it actually falls within the polygon
			if Geometry2D.is_point_in_polygon(placement, $Collision.polygon):
				var random_speed = Global.RNG.randi_range(MIN_PARTICLE_SPEED, MAX_PARTICLE_SPEED)
				var velocity = Vector2(random_speed, random_speed) * _direction_vector()
				_particles.append(Particle.new(Rect2(placement, Vector2(1, 1)), Color.WHITE, velocity))
				placed = true

func _process(delta):
	for particle in _particles:
		particle.update(delta)
	queue_redraw()

func _draw():
	const STUCK_MAX = 1000
	
	for particle in _particles:
		var stuck_ctr = 0 
		if not Geometry2D.is_point_in_polygon(particle.rect.position, $Collision.polygon):
			while not Geometry2D.is_point_in_polygon(particle.rect.position, $Collision.polygon) and stuck_ctr < 1000:
				particle.translate(Vector2(1, 0))
				stuck_ctr += 1
			stuck_ctr = 0
			while Geometry2D.is_point_in_polygon(particle.rect.position, $Collision.polygon) and stuck_ctr < 1000:
				particle.translate(Vector2(1, 0))
				stuck_ctr += 1
			particle.translate(Vector2(-1, 0))
			
			#this should never happen, but if we can't reposition a particle, just delete it
			if stuck_ctr == STUCK_MAX:
				print("warning - particle was stuck")
				_particles.erase(particle)
				continue
		
		draw_rect(particle.rect, particle.color)
