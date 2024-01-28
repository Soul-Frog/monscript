class_name Customization

extends Node2D

enum CustomizationColor {
	BLUE,
	BROWN,
	DARK,
	ORANGE,
	BLONDE,
	LIGHTGREEN,
	GREEN,
	TEAL,
	LIGHTBLUE,
	PURPLE,
	PINK,
	RED,
	SKINONE,
	SKINTWO,
	SKINTHREE,
	SKINFOUR,
	SKINFIVE,
	SKINSIX,
	SKINSEVEN
}

var customization_colors = {
	CustomizationColor.BROWN : [Color("#5d4037"), Color("#3e2723")],
	CustomizationColor.DARK : [Color("#424242"), Color("#212121")],
	CustomizationColor.ORANGE : [Color("#ff5722"), Color("#d84315")],
	CustomizationColor.BLONDE : [Color("#ffb74d"), Color("#ffa726")],
	CustomizationColor.LIGHTGREEN : [Color("#9ccc65"), Color("#7cb342")],
	CustomizationColor.GREEN : [Color("#056f00"), Color("#0d5302")],
	CustomizationColor.TEAL : [Color("#00897b"), Color("#00695c")],
	CustomizationColor.LIGHTBLUE : [Color("#03a9f4"), Color("#0288d1")],
	CustomizationColor.BLUE : [Color("#5677fc"), Color("#455ede")],
	CustomizationColor.PURPLE : [Color("#7e57c2"), Color("#673ab7")],
	CustomizationColor.PINK : [Color("#f48fb1"), Color("#f06292")],
	CustomizationColor.RED : [Color("#e84e40"), Color("#d01716")],
	CustomizationColor.SKINONE : [Color("#ffab91"), Color("#f69988")],
	CustomizationColor.SKINTWO : [Color("#f9d5ba"), Color("#e4a47c")],
	CustomizationColor.SKINTHREE : [Color("#e4a47c"), Color("#d38b59")],
	CustomizationColor.SKINFOUR : [Color("#d38b59"), Color("#ae6b3f")],
	CustomizationColor.SKINFIVE : [Color("#ae6b3f"), Color("#7f4c31")],
	CustomizationColor.SKINSIX : [Color("#7f4c31"), Color("#603429")],
	CustomizationColor.SKINSEVEN : [Color("#603429"), Color("#442725")]
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$CharacterCustomizationScreen/PlayerOverhead.disable_movement()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
