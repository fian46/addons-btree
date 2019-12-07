tool
extends GraphNode

const type = 9
var load_function = ""

func _ready():
	title = name
	return

func _enter_tree():
	title = name
	update()
	var opt = $Main/Required/opt_function
	for i in range(opt.get_item_count()):
		if  opt.get_item_text(i) == load_function:
			opt.selected = i
			break
		else:
			opt.selected = 0
	return

func update():
	if  not get_parent():
		return
	if  not get_parent().get("root_object"):
		return
	if  not get_parent().root_object:
		return
	var opt = $Main/Required/opt_function
	var old_sel = opt.selected
	var old_tsel = null
	
	if  old_sel >= 0:
		old_tsel = opt.get_item_text(old_sel)
	
	var tm = []
	var ta = []
	var ml = get_parent().root_object.get_method_list()
	for m in ml:
		if  m.name.begins_with("task_") and m.args.size() == 1:
			tm.append(m.name)
			ta.append(m.args.size())
	
	opt.clear()
	for m in tm:
		opt.add_item(m)
	
	if  old_tsel:
		old_sel = tm.find(old_tsel)
		if  old_sel >= 0:
			opt.selected = old_sel
	return

func set_data(data):
	offset = data.offset
	rect_size = data.size
	load_function = data.fn
	return

func get_data():
	var opt = $Main/Required/opt_function
	var sel = $Main/Required/opt_function.selected
	var fname = opt.get_item_text(sel)
	return {
		"offset":offset,
		"size":rect_size,
		"fn":fname
	}

func _on_while_node_resize_request(new_minsize):
	rect_size = new_minsize
	return

func _on_while_node_close_request():
	get_parent().child_delete(self)
	return
