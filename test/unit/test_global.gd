extends GutTest

const EMPTY_FILE : String = "empty_file"
const EMPTY_FILE_CONTENTS : String = ""
const ABC_FILE : String = "abc_file"
const ABC_FILE_CONTENTS : String = "A1BCD2EFG3\n\n4\nHI5J6KL789MNOP\nQRSTUV\tWX0YZ~"
const SRC_FILE : String = "source_file"
var SRC_FILE_CONTENTS : String = FileAccess.open("res://test/unit/test_global.gd", FileAccess.READ).get_as_text()

func before_all():
	FileAccess.open(EMPTY_FILE, FileAccess.WRITE).store_string(EMPTY_FILE_CONTENTS)
	FileAccess.open(ABC_FILE, FileAccess.WRITE).store_string(ABC_FILE_CONTENTS)
	FileAccess.open(SRC_FILE, FileAccess.WRITE).store_string(SRC_FILE_CONTENTS)

func after_all():
	DirAccess.remove_absolute(EMPTY_FILE)
	DirAccess.remove_absolute(ABC_FILE)
	DirAccess.remove_absolute(SRC_FILE)

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

class CallAfterDelayParam:
	var wasCalled : bool = false
	var val : int = 0

# tests call_after_delay
# this test works but takes some time to run...
func test_call_after_delay():
	assert_true(true) # test disabled
#	const delay := 5.0
#	var param := CallAfterDelayParam.new()
#
#	Global.call_after_delay(5, param, func(p : CallAfterDelayParam):
#		p.wasCalled = true
#		p.val = 8
#		)
#
#	# make sure function hasn't been called immediately
#	assert_false(param.wasCalled)
#	assert_eq(param.val, 0)
#
#	await(wait_seconds(delay * 2))
#
#	# function should be called by now
#	assert_true(param.wasCalled)
#	assert_eq(param.val, 8)

func test_repeat_str():
	assert_eq(Global.repeat_str("b", 1), "b")
	assert_eq(Global.repeat_str("be", 2), "bebe")
	assert_eq(Global.repeat_str("b", 3), "bbb")
	assert_eq(Global.repeat_str("b1", 4), "b1b1b1b1")
	
