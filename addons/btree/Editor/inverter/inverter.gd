tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.INVERTER

func _ready():
	connect("close_request", self, "close_request")
	return

func _enter_tree():
	title = name
	return

func get_data():
	return {
		"size" : rect_size,
		"offset" : offset
	}

func set_data(data):
	rect_size = data.size
	offset = data.offset
	return

func close_request():
	get_parent().child_delete(self)
	return
