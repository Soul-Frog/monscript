extends Camera2D

# Sets the limits of the camera to exactly fit the given tilemap
func set_limits(map: Sprite2D):
	self.limit_left = map.position.x
	self.limit_right = map.position.x + map.texture.get_width()
	self.limit_top = map.position.y
	self.limit_bottom = map.position.y + map.texture.get_height()
