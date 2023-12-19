@tool
extends GraphNode

const type = 2

func _on_Add_pressed():
	add_child(label())
	set_slot(get_child_count() - 1, false, 0, Color.BLUE, true, 0, Color.BLUE, null, null)
	return

func label():
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT #ivo
	l.text = str(get_child_count())
	return l

func _on_Del_pressed():
	if  get_child_count() > 1:
		#get_parent().slot_removed(name, get_connection_output_count() - 1)
		get_parent().slot_removed(name, get_output_port_count() - 1) #ivo 4.2 
		clear_slot(get_child_count() - 1)
		remove_child(get_child(get_child_count()-1))
	return

func _on_Sequence_close_request():
	get_parent().child_delete(self)
	return

func _on_Sequence_resize_request(new_minsize):
	size = new_minsize
	return

func _enter_tree():
	title = name
	return

func get_data():
	return {
		"count" : out_count(),
		"offset":position_offset, #ivo
		"size": size
	}

func out_count():
	var c = 0
	for i in get_children():
		if  i is Label:
			c += 1
	return c

func set_data(data):
	size = data.size
	position_offset = data.offset #ivo
	for i in range(data.count):
		add_child(label())
		set_slot(get_child_count() - 1, false, 0, Color.BLUE, true, 0, Color.BLUE, null, null)
	return
