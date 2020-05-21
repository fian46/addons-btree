tool
extends GraphNode

const Runtime = preload('../../Runtime/runtime.gd')

const type = Runtime.TNodeTypes.ROOT

func get_data():
	return {
		"offset" : offset,
		"size" : rect_size
	}

func set_data(data):
	offset = data.offset
	rect_size = data.size
	return
