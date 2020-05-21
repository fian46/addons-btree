tool
extends GraphNode

const Runtime = preload('../../Runtime/runtime.gd')

var type = -1

func _ready():
	$slot0/Add.connect("pressed", self, "add_pressed")
	$slot0/Del.connect("pressed", self, "del_pressed")
	connect("close_request", self, "close_request")
	connect("resize_request", self, "resize_request")
	return

func _enter_tree():
	title = name
	return

func as_sequence():
	type = Runtime.TNodeTypes.SEQUENCE
	name = "sequence"
	return

func as_selector():
	type = Runtime.TNodeTypes.SELECTOR
	name = "selector"
	return

func as_paralel():
	type = Runtime.TNodeTypes.PARALEL
	name = "paralel"
	return

func as_race():
	type = Runtime.TNodeTypes.RACE
	name = "race"
	return

func as_random_selector():
	type = Runtime.TNodeTypes.RANDOM_SELECTOR
	name = "random_selector"
	return

func as_random_sequence():
	type = Runtime.TNodeTypes.RANDOM_SEQUENCE
	name = "random_sequence"
	return

func label():
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
	l.text = str(get_child_count())
	return l

func add_pressed():
	add_child(label())
	set_slot(get_child_count() - 1, false, 0, Color.blue, true, 0, Color.blue, null, null)
	return

func del_pressed():
	if  get_child_count() > 1:
		get_parent().slot_removed(name, get_connection_output_count() - 1)
		clear_slot(get_child_count() - 1)
		remove_child(get_child(get_child_count()-1))
	return

func get_data():
	return {
		"count" : out_count(),
		"offset" : offset,
		"size": rect_size
	}

func out_count():
	var c = 0
	for i in get_children():
		if  i is Label:
			c += 1
	return c

func set_data(data):
	rect_size = data.size
	offset = data.offset
	for i in range(data.count):
		add_child(label())
		set_slot(get_child_count() - 1, false, 0, Color.blue, true, 0, Color.blue, null, null)
	return

func close_request():
	get_parent().child_delete(self)
	return

func resize_request(new_minsize):
	rect_size = new_minsize
	return
