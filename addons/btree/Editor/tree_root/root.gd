tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.ROOT

func _ready():
	connect("dragged", get_parent(), "node_dragged", [self])
	return

func get_data():
	return {
		"offset" : offset,
		"size" : rect_size
	}

func set_data(data):
	offset = data.offset
	rect_size = data.size
	return
