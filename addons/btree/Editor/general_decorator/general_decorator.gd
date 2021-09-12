tool
extends BehaviorTreeNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
var type = -1
var undo_redo:UndoRedo

func _ready():
	$slot0/Add.connect("pressed", self, "add_pressed")
	$slot0/Del.connect("pressed", self, "del_pressed")	
	return

func as_sequence():
	type = Runtime.TNodeTypes.SEQUENCE
	name = "sequence"
	title = name
	return

func as_selector():
	type = Runtime.TNodeTypes.SELECTOR
	name = "selector"
	title = name
	return

func as_paralel():
	type = Runtime.TNodeTypes.PARALEL
	name = "parallel"
	title = name
	return

func as_race():
	type = Runtime.TNodeTypes.RACE
	name = "race"
	title = name
	return

func as_random_selector():
	type = Runtime.TNodeTypes.RANDOM_SELECTOR
	name = "random_selector"
	title = name
	return

func as_random_sequence():
	type = Runtime.TNodeTypes.RANDOM_SEQUENCE
	name = "random_sequence"
	title = name
	return

func label():
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
	l.text = str(get_child_count())
	return l

#+ button
func add_pressed():
	get_parent().gd_add_slot(name)
	return

#- button
func del_pressed():
	get_parent().gd_del_slot(name)
	return

func set_data(data):
	.set_data(data)
	for i in range(data.count):
		add_child(label())
		set_slot(get_child_count() - 1, false, 0, Color.blue, true, 0, Color.blue, null, null)
	return
