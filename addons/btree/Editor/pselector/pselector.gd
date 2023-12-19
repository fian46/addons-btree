@tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

const type = Runtime.TNodeTypes.PRIORITY_SELECTOR

func _ready():
	connect("delete_request", Callable(self, "close_request")) #ivo 4.2 
	return

func _on_Add_pressed():
	get_parent().ps_add_slot(name)
	return

func label():
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # ivo 4.1.1
	l.text = str(get_child_count())
	return l

func _on_Del_pressed():
	get_parent().ps_del_slot(name)
	return

func _enter_tree():
	title = name
	return

func get_data():
	return {
		"count" : out_count(),
		"offset" : position_offset, #ivo 4.1.1
		"size": size
	}

func out_count():
	var c = 0
	for i in get_children():
		if  i is Label:
			c += 1
	return c

func set_data(data):
	size = data.size
	position_offset = data.offset #ivo

	for i in range(data.count):
		add_child(label())
		set_slot(get_child_count() - 1, false, 0, Color.BLUE, true, 1, Color.YELLOW, null, null)
	return

func close_request():
	get_parent().child_delete(self)
	return
