@tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.RANDOM_REPEAT

func _ready():
	connect("delete_request", Callable(self, "close_request")) #ivo 4.2 ???
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
		"size":size,
		"offset":position_offset, #ivo
		"ranges":$slot1/count.value
	}

func set_data(data):
	size = data.size
	position_offset = data.offset #ivo
	$slot0/count.call_deferred("set_value", data.count)
	$slot1/count.call_deferred("set_value", data.ranges)
	return
