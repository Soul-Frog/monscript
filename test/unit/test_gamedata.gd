extends GutTest

func test_area_dictionary():
	# size of dictionary should be 1 less than num of enums
	# (1 less because NONE has no correspodning dict entry)
	assert_eq(GameData._area_enum_to_path.size(), GameData.Area.size() - 1)
	
	for area_enum in GameData.Area.values():
		if area_enum == GameData.Area.NONE:
			continue
		
		# make sure mapping and file exist
		var _file_path = GameData.path_for_area(area_enum)
		assert_not_null(_file_path)
		assert_true(Global.does_file_exist(_file_path))
