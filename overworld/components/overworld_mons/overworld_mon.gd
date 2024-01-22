#base class for all overworld mons
class_name OverworldMon
extends MonScene

# the mons in this battle composition
@export_group("Mons")
@export var mon1Type = MonData.MonType.NONE
@export var mon1Level = 0
@export var mon2Type = MonData.MonType.NONE
@export var mon2Level = 0
@export var mon3Type = MonData.MonType.NONE
@export var mon3Level = 0
@export var mon4Type = MonData.MonType.NONE
@export var mon4Level = 0

var mons = []

func _ready():
	assert(mon1Level >= 0 and mon1Level <= 64, "Illegal level for mon1!")
	assert(mon2Level >= 0 and mon2Level <= 64, "Illegal level for mon2!")
	assert(mon3Level >= 0 and mon3Level <= 64, "Illegal level for mon3!")
	assert(mon4Level >= 0 and mon4Level <= 64, "Illegal level for mon4!")	
	
	# create mons for battle formation
	assert(not(mon1Type == MonData.MonType.NONE 
	and mon2Type == MonData.MonType.NONE 
	and mon3Type == MonData.MonType.NONE
	and mon4Type == MonData.MonType.NONE), 
	"Must have at least one non-NONE mon!")
	
	mons.append(MonData.create_mon(mon1Type, mon1Level) if mon1Type != MonData.MonType.NONE else null)
	mons.append(MonData.create_mon(mon2Type, mon2Level) if mon2Type != MonData.MonType.NONE else null)
	mons.append(MonData.create_mon(mon3Type, mon3Level) if mon3Type != MonData.MonType.NONE else null)
	mons.append(MonData.create_mon(mon4Type, mon4Level) if mon4Type != MonData.MonType.NONE else null)
