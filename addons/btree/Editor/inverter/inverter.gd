@tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.INVERTER

func _ready():
	connect("delete_request", Callable(self, "close_request")) #ivo 4.2 ???
	return

func _enter_tree():
	title = name
	return

func get_data():
	return {
		"size" : size,
		"offset":position_offset, #ivo
	}

func set_data(data):
	size = data.size
	position_offset = data.offset #ivo
	return

func close_request():
	get_parent().child_delete(self)
	return
