@tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.ROOT

func _ready():
	connect("dragged", Callable(get_parent(), "node_dragged").bind(self))
	return

func get_data():
	return {
		"offset" : position_offset, #ivo
		"size" : size
	}

func set_data(data):
	position_offset = data.offset #ivo
	size = data.size
	return
