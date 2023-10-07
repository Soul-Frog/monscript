extends Camera2D

# Sets the limits of the camera to exactly fit the given tilemap
func set_limits(map: Sprite2D):
	assert(map.position.x == int(map.position.x), "Camera won't work unless map is aligned to an integer position.")
	assert(map.position.y == int(map.position.y), "Camera won't work unless map is aligned to an integer position.")
	self.limit_left = int(map.position.x)
	self.limit_right = int(map.position.x) + map.texture.get_width()
	self.limit_top = int(map.position.y)
	self.limit_bottom = int(map.position.y) + map.texture.get_height()
	
	print(limit_left)
	print(limit_right)
	print(limit_top)
	print(limit_bottom)
