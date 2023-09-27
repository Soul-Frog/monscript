extends GutTest

const EMPTY_FILE := "empty_file"
const EMPTY_FILE_CONTENTS := ""
const ABC_FILE := "abc_file"
const ABC_FILE_CONTENTS := "A1BCD2EFG3\n\n4\nHI5J6KL789MNOP\nQRSTUV\tWX0YZ~"
const SRC_FILE := "source_file"
var SRC_FILE_CONTENTS := FileAccess.open("res://test/unit/test_global.gd", FileAccess.READ).get_as_text()

const TEST_DIR := "res://test_global_dir"
const TXT_FILES = ["afile.txt", "anotherfile.txt", "lastfile.txt"]
const SAV_FILES = ["save1.sav"]

func before_all():
	FileAccess.open(EMPTY_FILE, FileAccess.WRITE).store_string(EMPTY_FILE_CONTENTS)
	FileAccess.open(ABC_FILE, FileAccess.WRITE).store_string(ABC_FILE_CONTENTS)
	FileAccess.open(SRC_FILE, FileAccess.WRITE).store_string(SRC_FILE_CONTENTS)
	DirAccess.make_dir_absolute(TEST_DIR)
	for file in TXT_FILES:
		print(TEST_DIR + "/" + file)
		FileAccess.open(TEST_DIR + "/" + file, FileAccess.WRITE)
	for file in SAV_FILES:
		FileAccess.open(TEST_DIR + "/" + file, FileAccess.WRITE)

func after_all():
	DirAccess.remove_absolute(EMPTY_FILE)
	DirAccess.remove_absolute(ABC_FILE)
	DirAccess.remove_absolute(SRC_FILE)
	for file in TXT_FILES:
		DirAccess.remove_absolute(TEST_DIR + "/" + file)
	for file in SAV_FILES:
		DirAccess.remove_absolute(TEST_DIR + "/" + file)
	DirAccess.remove_absolute(TEST_DIR)

func test_adjust_towards():
	assert_eq(Global.adjust_towards(10, 5, 3), 7)
	assert_eq(Global.adjust_towards(10, 5, 1), 9)
	assert_eq(Global.adjust_towards(10, 5, 5), 5)
	assert_eq(Global.adjust_towards(10, 5, 6), 5)
	assert_eq(Global.adjust_towards(10, 5, 31312), 5)
	
	assert_eq(Global.adjust_towards(10, 15, 3), 13)
	assert_eq(Global.adjust_towards(10, 15, 1), 11)
	assert_eq(Global.adjust_towards(10, 15, 5), 15)
	assert_eq(Global.adjust_towards(10, 15, 6), 15)
	assert_eq(Global.adjust_towards(10, 15, 313432), 15)

func test_choose_one():
	# with one element, always return that element
	for i in range(0, 10):
		assert_eq(Global.choose_one([i]), i)
	
	# with multiple elements, make sure elements are fairly represented
	const arr = [0, 1, 2, 3, 4]
	var freq = [0, 0, 0, 0, 0]
	const runs = 1000
	
	for i in range(0, runs):
		freq[Global.choose_one(arr)] += 1
	
	for i in range(0, freq.size()):
		var frequency = freq[i]
		assert_almost_eq(frequency, int(float(runs)/freq.size()), int(float(runs)/freq.size()/2))

# tests file_to_string, string_to_file, delete_file, and does_file_exist
func test_file_manip():
	# can read and detect existing files
	assert_eq(Global.file_to_string(EMPTY_FILE), EMPTY_FILE_CONTENTS)
	assert_eq(Global.file_to_string(ABC_FILE), ABC_FILE_CONTENTS)
	assert_eq(Global.file_to_string(SRC_FILE), SRC_FILE_CONTENTS)
	assert_true(Global.does_file_exist(EMPTY_FILE))
	assert_true(Global.does_file_exist(ABC_FILE))
	assert_true(Global.does_file_exist(SRC_FILE))
	assert_false(Global.does_file_exist(""))
	
	# create a file
	const file = "soulturtlemagnetfrog.txt"
	const s = "soul turtles and magnet frogs?"
	assert_false(Global.does_file_exist(file))
	Global.string_to_file(file, s)
	# make sure the contents are right
	assert_true(Global.does_file_exist(file))
	assert_eq(Global.file_to_string(file), s)
	# now delete it and make sure it's gone
	Global.delete_file(file)
	assert_false(Global.does_file_exist(file))

func test_files_in_folder():
	var all: Array = Global.files_in_folder(TEST_DIR)
	assert_eq(all.size(), TXT_FILES.size() + SAV_FILES.size())
	
	var txt: Array = Global.files_in_folder_with_extension(TEST_DIR, ".txt")
	assert_eq(txt.size(), TXT_FILES.size())
	for file in TXT_FILES:
		assert_ne(txt.find(file), -1)
	
	var sav: Array = Global.files_in_folder_with_extension(TEST_DIR, ".sav")
	assert_eq(sav.size(), SAV_FILES.size())
	for file in SAV_FILES:
		assert_ne(sav.find(file), -1)
		
	var none: Array = Global.files_in_folder_with_extension(TEST_DIR, ".ben")
	assert_eq(none.size(), 0)

func test_repeat_str():
	assert_eq(Global.repeat_str("b", 1), "b")
	assert_eq(Global.repeat_str("be", 2), "bebe")
	assert_eq(Global.repeat_str("b", 3), "bbb")
	assert_eq(Global.repeat_str("b1", 4), "b1b1b1b1")
	
