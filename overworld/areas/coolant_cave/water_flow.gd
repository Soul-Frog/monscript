extends PushZone

@export var MIN_PARTICLE_SPEED = 60
@export var MAX_PARTICLE_SPEED = 90
@export var PARTICLE_COUNT = 30

const _PARTICLE = preload("res://particle.tscn")

var _water_particles = []

func _ready():
	assert(MIN_PARTICLE_SPEED <= MAX_PARTICLE_SPEED)
	
	var min_x = Global.INT_MAX
	var max_x = Global.INT_MIN
	var min_y = Global.INT_MAX
	var max_y = Global.INT_MIN
	for i in $ParticleZone.polygon.size():
		var point = $ParticleZone.polygon[i]
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
			if Geometry2D.is_point_in_polygon(placement, $ParticleZone.polygon):
				var rand_speed = Global.RNG.randi_range(MIN_PARTICLE_SPEED, MAX_PARTICLE_SPEED)
				var velocity = Vector2(rand_speed, rand_speed) * _direction_vector()
				var particle = _PARTICLE.instantiate()
				particle.init(placement, velocity)
				match Global.RNG.randi_range(0, 2):
					0, 1:
						particle.color = Color.WHITE
					2:
						particle.color = Color.SKY_BLUE
				particle.fade_out_done.connect(_on_particle_fade_out_done)
				add_child(particle)
				_water_particles.append(particle)
				placed = true

func _process(delta):
	for particle in _water_particles:
		if not Geometry2D.is_point_in_polygon(particle.position + Vector2(5, 5) * _direction_vector(), $ParticleZone.polygon):
			particle.fade_out()

func _on_particle_fade_out_done(particle):
	const STUCK_MAX = 1000
	var stuck_ctr = 0 
	
	# move until we're back in the water flow zone
	while not Geometry2D.is_point_in_polygon(particle.position, $ParticleZone.polygon) and stuck_ctr < STUCK_MAX:
		particle.translate(Vector2(-1, -1) * _direction_vector())
		stuck_ctr += 1
	
	if stuck_ctr != STUCK_MAX:
		stuck_ctr = 0
		# move until we're at the edge of the zone
		while Geometry2D.is_point_in_polygon(particle.position, $ParticleZone.polygon) and stuck_ctr < STUCK_MAX:
			particle.translate(Vector2(-1, -1) * _direction_vector())
			stuck_ctr += 1
		# move it 1 particle back into the szone
		particle.translate(Vector2(1, 1) * _direction_vector())
		particle.fade_in()
	
	#this should never happen, but if we can't reposition a particle, just delete it
	if stuck_ctr == STUCK_MAX:
		print("warning - particle was stuck")
		_water_particles.erase(particle)
		particle.queue_free()
