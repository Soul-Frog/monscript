extends GutTest

var script_menu = null

func before_all():
	script_menu = load("res://ui/script/script_menu.tscn").instantiate()
	get_tree().get_root().add_child(script_menu) #add to scene so it can update

func after_all():
	script_menu.free()

func test_script_menu_created():
	assert_not_null(script_menu, "Script menu was made!")

# make sure that the maximum possible block sizes doesn't run out of editor space
func test_block_sizes():
	# add all if, do, and to blocks to the menu
	for ifBlock in ScriptData.IF_BLOCK_LIST:
		script_menu._create_and_add_block_to(script_menu.IF_DRAWER, ifBlock.type, ifBlock.name)
	for doBlock in ScriptData.DO_BLOCK_LIST:
		script_menu._create_and_add_block_to(script_menu.DO_DRAWER, doBlock.type, doBlock.name)
	for toBlock in ScriptData.TO_BLOCK_LIST:
		script_menu._create_and_add_block_to(script_menu.TO_DRAWER, toBlock.type, toBlock.name)
	
	await get_tree().process_frame # wait for 1 frame to let blocks update their sizing
	
	# calculate roughly the maximum space for a line
	var max_line_x = script_menu.SCRIPT_SCROLL.size.x - script_menu.NEWLINE_BUTTON.size.x - script_menu.SCRIPT_SCROLL.get_v_scroll_bar().size.x
	
	# quick lambda finding the largest block in an array
	var find_largest = func(blocks: Array, chains_to: ScriptData.Block.Type):
		var largest = null
		for block in blocks:
			if largest == null or (block.size.x > largest.size.x and block.to_block().next_block_type == chains_to):
				largest = block
		return largest
	
	# find the largest if, do, and to blocks that chain together
	var largest_if = find_largest.call(script_menu.IF_DRAWER.get_children(), ScriptData.Block.Type.DO)
	var largest_do = find_largest.call(script_menu.DO_DRAWER.get_children(), ScriptData.Block.Type.TO)
	var largest_to = find_largest.call(script_menu.TO_DRAWER.get_children(), ScriptData.Block.Type.NONE)
	var largest_possible_line_x = largest_if.size.x + largest_do.size.x + largest_to.size.x
	
	gut.p("Largest IF block is %s with size %d." % [largest_if.block_name, largest_if.size.x])
	gut.p("Largest DO block is %s with size %d." % [largest_do.block_name, largest_do.size.x])
	gut.p("Largest TO block is %s with size %d." % [largest_to.block_name, largest_to.size.x])
	gut.p("Combined, they are %d." % largest_possible_line_x)
	gut.p("The maximum size the editor can hold is %d." % max_line_x)
	
	assert_true(max_line_x >= largest_possible_line_x, "Ensure largest possible line fits in editor.")
