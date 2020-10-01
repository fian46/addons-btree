tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

const type = Runtime.TNodeTypes.PRIORITY_SELECTOR

func _ready():
	connect("close_request", self, "close_request")
	return

func _on_Add_pressed():
	get_parent().ps_add_slot(name)
	return

func label():
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
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
		set_slot(get_child_count() - 1, false, 0, Color.blue, true, 1, Color.yellow, null, null)
	return

func close_request():
	get_parent().child_delete(self)
	return
