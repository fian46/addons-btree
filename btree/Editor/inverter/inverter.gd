tool
extends GraphNode

const Runtime = preload('../../Runtime/runtime.gd')

const type = Runtime.TNodeTypes.INVERTER

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

func _on_inverter_close_request():
	get_parent().child_delete(self)
	return

func _on_inverter_resize_request(new_minsize):
	rect_size = new_minsize
	return
