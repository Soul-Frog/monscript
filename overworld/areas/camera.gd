extends Camera2D

# Sets the limits of the camera to exactly fit the given tilemap
func set_limits(tilemap):
	var map_limits = tilemap.get_used_rect()
	var map_cellsize = tilemap.tile_set.get_tile_size()
	self.limit_left = map_limits.position.x * map_cellsize.x
	self.limit_right = map_limits.end.x * map_cellsize.x
	self.limit_top = map_limits.position.y * map_cellsize.y
	self.limit_bottom = map_limits.end.y * map_cellsize.y
