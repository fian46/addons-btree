tool
extends GraphEdit

var data = null
var root_object = null
var control = null

func _ready():
	set_process_input(true)
	return

func reload():
	clear_editor()
	if  not data:
		return
	if  not control:
		return
	build_tree_from_data()
	return

func clear_data():
	data = null
	control = null
	root_object = null
	return


func load_data(ndata, ncontrol):
	data = ndata
	control = ncontrol
	root_object = data.get_parent()
	return

func clear_editor():
	for i in get_connection_list():
		disconnect_node(i.from, i.from_port, i.to, i.to_port)
	for i in get_children():
		if  i is GraphNode and i.name != "root":
			var a = 0
			remove_child(i)
			i.queue_free()
	return

var task_scene = preload("res://addons/btree/Editor/task/task.tscn")
var sequence_scene = preload("res://addons/btree/Editor/sequence/sequence.tscn")
var selector_scene = preload("res://addons/btree/Editor/selector/selector.tscn")
var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var priority_condition = preload("res://addons/btree/Editor/pselector/priority_condition.tscn")
var paralel_scene = preload("res://addons/btree/Editor/paralel/parallel.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var while_node_scene = preload("res://addons/btree/Editor/while_node/while_node.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var race_scene = preload("res://addons/btree/Editor/race/race.tscn")

func build_tree_from_data():
	if  not data:
		return
	if  not data.tree:
		return
	if  not data.tree.has("nodes"):
		return
	var nodes = data.tree.nodes
	var root = data.tree.root
	var conn = data.tree.connection
	for n in nodes:
		if  n.type == 0:
			var node = get_node("root")
			node.set_data(n.data)
		else:
			var node = create_node(n)
			add_child(node)
	for c in data.tree.connection:
		connect_node(c.from, c.from_port, c.to, c.to_port)
	return

func create_node(n):
	if  n.type == 1:
		var task = task_scene.instance()
		task.name = n.name
		task.set_data(n.data)
		return task
	elif n.type == 2:
		var seq = sequence_scene.instance()
		seq.name = n.name
		seq.set_data(n.data)
		return seq
	elif n.type == 3:
		var sel = selector_scene.instance()
		sel.name = n.name
		sel.set_data(n.data)
		return sel
	elif n.type == 4:
		var pse = pselector_scene.instance()
		pse.name = n.name
		pse.set_data(n.data)
		return pse
	elif n.type == 5:
		var pc = priority_condition.instance()
		pc.name = n.name
		pc.set_data(n.data)
		return pc
	elif n.type == 6:
		var par = paralel_scene.instance()
		par.name = n.name
		par.set_data(n.data)
		return par
	elif n.type == 7:
		var mute = mute_scene.instance()
		mute.name = n.name
		mute.set_data(n.data)
		return mute
	elif n.type == 8:
		var rep = repeat_scene.instance()
		rep.name = n.name
		rep.set_data(n.data)
		return rep
	elif n.type == 9:
		var whi = while_node_scene.instance()
		whi.name = n.name
		whi.set_data(n.data)
		return whi
	elif n.type == 10:
		var w = wait_scene.instance()
		w.name = n.name
		w.set_data(n.data)
		return w
	elif n.type == 11:
		var r = race_scene.instance()
		r.name = n.name
		r.set_data(n.data)
		return r
	return null

func _on_TreeEditor_connection_request(from, from_slot, to, to_slot):
	for i in get_connection_list():
		if  from == i.from and from_slot == i.from_port:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
		if  to == i.to and to_slot == i.to_port:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
	connect_node(from, from_slot, to, to_slot)
	return

func child_delete(node):
	for i in get_connection_list():
		if  node.name == i.from:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
		if  node.name == i.to:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
	node.queue_free()
	return

func _on_save_pressed():
	if  not data:
		get_parent().hint("No BTREE selected !")
		return
	get_parent().hint("SAVING CHANGES")
	data.tree = {}
	var info = data.tree
	info.nodes = []
	for i in get_children():
		if  i is GraphNode:
			var node = Dictionary()
			node["name"] = i.name
			node["type"] = i.type
			node["data"] = i.get_data()
			info.nodes.append(node)

	var root = find("root", info.nodes)
	build_tree(root, get_connection_list(), info.nodes)
	info.root = root
	info.connection = get_connection_list()
	if  control:
		control.get_editor_interface().save_scene()
	return

func build_tree(root, conn:Array, nodes):
	var children = []
	var removed = []
	for c in conn:
		if  c.from == root.name:
			removed.append(c)
	
	root.child = children
	removed.sort_custom(self, "sort_from")
	
	for i in removed:
		var ch = find(i.to, nodes)
		children.append(ch)
		conn.remove(conn.find(i))
	
	for i in children:
		build_tree(i, conn, nodes)
	return

func sort_from(a, b):
	return a.from_port < b.from_port

func find(name, nodes):
	for i in nodes:
		if  name == i.name:
			return i
	return null

func _on_TreeEditor_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	return

func slot_removed(name, slot):
	for i in get_connection_list():
		if  i.from == name and i.from_port == slot:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
	return

var ctrl = false
var shift = false

func _input(event):
	if  not is_visible_in_tree():
		return
	if  event is InputEventKey:
		if  event.scancode == KEY_CONTROL and event.pressed:
			ctrl = true
		elif event.scancode == KEY_CONTROL and not event.pressed:
			ctrl = false
		
		if  event.scancode == KEY_SHIFT and event.pressed:
			shift = true
		elif event.scancode == KEY_SHIFT and not event.pressed:
			shift = false
		
		if  event.scancode == KEY_C and not event.pressed and ctrl and shift:
			copy_node()
			get_parent().hint("Recursive Duplicate Node")
		
		if  event.scancode == KEY_X and not event.pressed and ctrl and shift:
			rdelete_node()
			get_parent().hint("Recursive Delete Node")
		
		if  event.scancode == KEY_SPACE and event.pressed and ctrl and shift:
			rmove_node()
			get_parent().hint("Recursive Move Node")
		
		if  event.scancode == KEY_S and not event.pressed and ctrl:
			_on_save_pressed()
		
		if  event.scancode == KEY_F  and not event.pressed and ctrl:
			focus_selected()
	
		return
	
	if  event is InputEventMouseButton:
		if  event.pressed and event.button_index == 4 and ctrl and shift:
			zoom += 0.1
			accept_event()
			get_parent().hint("Zoom In")
		if  event.pressed and event.button_index == 5 and ctrl and shift:
			zoom -= 0.1
			accept_event()
			get_parent().hint("Zoom Out")
		return
	return

var selected:Node

func copy_node():
	if  not selected:
		get_parent().hint("No Node Selected")
		return
	if  not selected.selected:
		get_parent().hint("No Node Selected")
		return
	if  selected.name == "root":
		get_parent().hint("Cannot Duplicate \"root\" Node !")
		return
	
	var root_offset = (scroll_offset / zoom) + (get_local_mouse_position() / zoom)
	
	var nodes = []
	for i in get_children():
		if  i is GraphNode:
			var node = {
				"name": i.name,
				"type": i.type,
				"data":i.get_data()
			}
			nodes.append(node)
	var cp = find(selected.name, nodes)
	
	build_tree(cp, get_connection_list(), nodes)
	nodes.clear()
	rec_populate(cp, nodes)
	
	for i in nodes:
		print(i)
	
	var inst_node = []
	var mapping = {}
	for i in nodes:
		var inst = create_node(i)
		var ori_name = inst.name
		add_child(inst)
		inst_node.append(inst)
		var mapping_name = inst.name
		mapping[ori_name] = mapping_name
	
	var rinst = null
	for i in inst_node:
		if  i.name == mapping[cp.name]:
			rinst = i
			break
	
	if  rinst:
		var shifted = root_offset - rinst.offset
		for i in inst_node:
			i.offset += shifted
	
	for i in nodes:
		for j in get_connection_list():
			if  i.name == j.from:
				connect_node(mapping[j.from], j.from_port, mapping[j.to], j.to_port)
	return

func rdelete_node():
	if  not selected:
		get_parent().hint("No Node Selected")
		return
	if  not selected.selected:
		get_parent().hint("No Node Selected")
		return
	if  selected.name == "root":
		get_parent().hint("Cannot Delete \"root\" Node")
		return
	
	var nodes = []
	for i in get_children():
		if  i is GraphNode:
			var node = {
				"name": i.name,
				"type": i.type,
				"data":i.get_data()
			}
			nodes.append(node)
	
	var cp = find(selected.name, nodes)
	build_tree(cp, get_connection_list(), nodes)
	nodes.clear()
	rec_populate(cp, nodes)
	
	for i in nodes:
		for j in get_connection_list():
			if  i.name == j.from:
				disconnect_node(j.from, j.from_port, j.to, j.to_port)
	
	for i in nodes:
		if  has_node(i.name):
			var n = get_node(i.name)
			remove_child(n)
	selected = null
	return

func rmove_node():
	var root_offset = (scroll_offset / zoom) + (get_local_mouse_position() / zoom)
	if  not selected:
		get_parent().hint("No Node Selected")
		return
	if  not selected.selected:
		get_parent().hint("No Node Selected")
		return
	
	var nodes = []
	for i in get_children():
		if  i is GraphNode:
			var node = {
				"name": i.name,
				"type": i.type,
				"data":i.get_data()
			}
			nodes.append(node)
	
	var cp = find(selected.name, nodes)
	build_tree(cp, get_connection_list(), nodes)
	nodes.clear()
	rec_populate(cp, nodes)
	
	if  not has_node(cp.name):
		return
	
	var rn = get_node(cp.name)
	var shifted = root_offset - rn.offset
	
	for i in nodes:
		if  has_node(i.name):
			var n = get_node(i.name)
			n.offset += shifted
	return

func rec_populate(root, nodes:Array):
	nodes.append(root)
	for data in root.child:
		rec_populate(data, nodes)
	root.child.clear()
	return

func _on_TreeEditor_node_selected(node):
	selected = node
	return

func focus_selected():
	if  not selected:
		return
	if  not selected.selected:
		return
	scroll_offset = selected.offset * zoom - ((rect_size / 2) - (selected.rect_size / 2))
	return

func _on_help_toggled(button_pressed):
	get_parent().help(button_pressed)
	return

func _on_search_bar_text_changed(new_text):
	var most_similar:Node = null
	for i in get_children():
		if  i is GraphNode:
			if  most_similar == null:
				most_similar = i
			elif most_similar.name.similarity(new_text) < i.name.similarity(new_text) :
				most_similar = i
	if  most_similar:
		scroll_offset = most_similar.offset * zoom - ((rect_size / 2) - (most_similar.rect_size / 2))
	return