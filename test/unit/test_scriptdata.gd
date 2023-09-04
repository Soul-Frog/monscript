extends GutTest

var mockIf: ScriptData.Block
var mockDo: ScriptData.Block
var mockDoNoTo: ScriptData.Block
var mockTo: ScriptData.Block
var line2: String
var line3: String

func before_all():
	mockIf = ScriptData.Block.new(ScriptData.Block.Type.IF, "IfMock", ScriptData.Block.Type.DO, "desc", null)
	mockDo = ScriptData.Block.new(ScriptData.Block.Type.DO, "DoMock", ScriptData.Block.Type.TO, "desc", null)
	mockDoNoTo = ScriptData.Block.new(ScriptData.Block.Type.DO, "ToMockNoTo", ScriptData.Block.Type.NONE, "desc", null)
	mockTo = ScriptData.Block.new(ScriptData.Block.Type.TO, "ToMock", ScriptData.Block.Type.NONE, "desc", null)
	line2 = "%s%s%s" % [mockIf.name, ScriptData.BLOCK_DELIMITER, mockDoNoTo.name]
	line3 = "%s%s%s%s%s" % [mockIf.name, ScriptData.BLOCK_DELIMITER, mockDo.name, ScriptData.BLOCK_DELIMITER, mockTo.name]
	ScriptData.IF_BLOCK_LIST.append(mockIf)
	ScriptData.DO_BLOCK_LIST.append(mockDo)
	ScriptData.DO_BLOCK_LIST.append(mockDoNoTo)
	ScriptData.TO_BLOCK_LIST.append(mockTo)

func after_all():
	ScriptData.IF_BLOCK_LIST.erase(mockIf)
	ScriptData.DO_BLOCK_LIST.erase(mockDo)
	ScriptData.DO_BLOCK_LIST.erase(mockDoNoTo)
	ScriptData.TO_BLOCK_LIST.erase(mockTo)

# make sure each block in lists is of right type
func test_block_lists():
	for block in ScriptData.IF_BLOCK_LIST:
		assert_eq(block.type, ScriptData.Block.Type.IF)
	for block in ScriptData.DO_BLOCK_LIST:
		assert_eq(block.type, ScriptData.Block.Type.DO)
	for block in ScriptData.TO_BLOCK_LIST:
		assert_eq(block.type, ScriptData.Block.Type.TO)

# make sure each block in block lists can be returned by name
func test_get_block_by_name():
	for block in ScriptData.IF_BLOCK_LIST:
		assert_eq(block, ScriptData.get_block_by_name(block.name))
	for block in ScriptData.DO_BLOCK_LIST:
		assert_eq(block, ScriptData.get_block_by_name(block.name))
	for block in ScriptData.TO_BLOCK_LIST:
		assert_eq(block, ScriptData.get_block_by_name(block.name))
	

func test_script_with_three_blocks():
	# make a simple script with 3 blocks from string
	var str_script: String = "%s%s%s%s%s" % [ScriptData.SCRIPT_START, ScriptData.LINE_DELIMITER, line3, ScriptData.LINE_DELIMITER, ScriptData.SCRIPT_END]
	var script: ScriptData.MonScript = ScriptData.MonScript.new(str_script)
	assert_not_null(script)
	assert_eq(script.lines.size(), 1)
	
	# make sure line was parsed correctly
	var line :ScriptData.Line = script.lines[0]
	assert_eq(line.ifBlock, mockIf)
	assert_eq(line.doBlock, mockDo)
	assert_eq(line.toBlock, mockTo)
	assert_eq(line.as_string(), line3)
	
	# make sure it can be decomposed back into the same string
	assert_eq(script.as_string(), str_script)


# make sure it can be decomposed back into string
func test_script_with_two_blocks():
	# make a simple script with 2 blocks from string
	var str_script: String = "%s%s%s%s%s" % [ScriptData.SCRIPT_START, ScriptData.LINE_DELIMITER, line2, ScriptData.LINE_DELIMITER, ScriptData.SCRIPT_END]
	var script: ScriptData.MonScript = ScriptData.MonScript.new(str_script)
	assert_not_null(script)
	assert_eq(script.lines.size(), 1)
	
	# make sure line was parsed correctly
	var line :ScriptData.Line = script.lines[0]
	assert_eq(line.ifBlock, mockIf)
	assert_eq(line.doBlock, mockDoNoTo)
	assert_null(line.toBlock)
	assert_eq(line.as_string(), line2)
	
	# make sure it can be decomposed back into string
	assert_eq(script.as_string(), str_script)

func test_script_with_multiple_lines():
	var str_script: String = "%s%s%s%s%s%s%s" % [ScriptData.SCRIPT_START, ScriptData.LINE_DELIMITER, line3, ScriptData.LINE_DELIMITER, line2, ScriptData.LINE_DELIMITER, ScriptData.SCRIPT_END]
	var script: ScriptData.MonScript = ScriptData.MonScript.new(str_script)
	assert_not_null(script)
	assert_eq(script.lines.size(), 2)
	
	# check lines
	var first_line :ScriptData.Line = script.lines[0]
	assert_eq(first_line.ifBlock, mockIf)
	assert_eq(first_line.doBlock, mockDo)
	assert_eq(first_line.toBlock, mockTo)
	assert_eq(first_line.as_string(), line3)
	
	var second_line :ScriptData.Line = script.lines[1]
	assert_eq(second_line.ifBlock, mockIf)
	assert_eq(second_line.doBlock, mockDoNoTo)
	assert_null(second_line.toBlock)
	assert_eq(second_line.as_string(), line2)
	
	# finally, check the script...
	assert_eq(script.as_string(), str_script)
