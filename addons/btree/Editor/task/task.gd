tool
extends GraphNode

const type = 1
var load_function = ""
var params = []
var param_scene = preload("res://addons/btree/Editor/task/param.tscn")

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
	for i in params:
		var input = param_scene.instance()
		input.set_id($Params.get_child_count())
		input.connect("remove_me", self, "remove_param")
		input.call_deferred("set_value", i)
		$Params.add_child(input)
	return

func _on_GraphNode_resize_request(new_minsize):
	rect_size = new_minsize
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
	var ml = get_parent().root_object.get_method_list()
	for m in ml:
		if  m.name.begins_with("task_") and m.args.size() == 1:
			tm.append(m.name)
	
	opt.clear()
	for m in tm:
		opt.add_item(m)
	
	if  old_tsel:
		old_sel = tm.find(old_tsel)
		if  old_sel >= 0:
			opt.selected = old_sel
	return

func _on_GraphNode_close_request():
	get_parent().child_delete(self)
	return

func set_data(data):
	offset = data.offset
	rect_size = data.size
	load_function = data.fn
	params = data.params
	return

func get_data():
	var opt = $Main/Required/opt_function
	var sel = $Main/Required/opt_function.selected
	var fname = opt.get_item_text(sel)
	var pr = $Params
	
	var ret_param = []
	var values = []
	for i in range(pr.get_child_count()):
		var val = pr.get_child(i).get_value()
		ret_param.append(val)
		values.append(val[0])
	var ret_data = {
		"offset":offset,
		"size":rect_size,
		"fn":fname,
		"params":ret_param,
		"values":values
	}
	return ret_data

func _on_Add_pressed():
	var input = param_scene.instance()
	input.set_id($Params.get_child_count())
	input.connect("remove_me", self, "remove_param")
	$Params.add_child(input)
	return

func remove_param(param):
	$Params.remove_child(param)
	for i in range($Params.get_child_count()):
		$Params.get_child(i).set_id(i)
	return