tool
extends GraphNode

const Runtime = preload('../../Runtime/runtime.gd')

const type = Runtime.TNodeTypes.PRIORITY_SELECTOR

func _on_Add_pressed():
	add_child(label())
	set_slot(get_child_count() - 1, false, 0, Color.blue, true, 1, Color.yellow, null, null)
	return

func label():
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
	l.text = str(get_child_count())
	return l

func _on_Del_pressed():
	if  get_child_count() > 1:
		get_parent().slot_removed(name, get_connection_output_count() - 1)
		clear_slot(get_child_count() - 1)
		remove_child(get_child(get_child_count()-1))
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

func _on_priority_selector_resize_request(new_minsize):
	rect_size = new_minsize
	return

func _on_priority_selector_close_request():
	get_parent().child_delete(self)
	return
