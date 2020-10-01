tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.WAIT

func _ready():
	connect("close_request", self, "close_request")
	$slot0/count.value = 0
	return

func _enter_tree():
	title = name
	return

func close_request():
	get_parent().child_delete(self)
	return

func get_data():
	return {
		"count":$slot0/count.value,
		"size":rect_size,
		"offset":offset
	}

func set_data(data):
	rect_size = data.size
	offset = data.offset
	$slot0/count.call_deferred("set_value", data.count)
	return
