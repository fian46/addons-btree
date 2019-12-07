tool
extends GraphNode

const type = 0

func get_data():
	return {
		"offset" : offset,
		"size" : rect_size
	}

func set_data(data):
	offset = data.offset
	rect_size = data.size
	return