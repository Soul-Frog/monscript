extends GutTest

const EMPTY_FILE : String = "empty_file"
const EMPTY_FILE_CONTENTS : String = ""
const ABC_FILE : String = "abc_file"
const ABC_FILE_CONTENTS : String = "A1BCD2EFG3\n\n4\nHI5J6KL789MNOP\nQRSTUV\tWX0YZ~"
const SRC_FILE : String = "source_file"
const SRC_FILE_CONTENTS : String = FileAccess.open("res://test/unit/test_global.gd", FileAccess.READ).get_as_text()

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
		assert_almost_eq(frequency, float(runs)/freq.size(), float(runs)/freq.size()/2)

func test_file_to_string():
