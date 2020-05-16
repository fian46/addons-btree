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
	var pscript:GDScript = data.get_parent().get_script()
	var cscript:GDScript = GDScript.new()
	cscript.set_source_code(pscript.get_source_code())
	if  cscript.reload(false) != OK:
#		hacky trick to compile gdscript implementation
#		different language need different implementation
		get_parent().halt(true)
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

var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var general_fcall_scene = preload("res://addons/btree/Editor/general_fcall/general_fcall.tscn")
var general_decorator_scene = preload("res://addons/btree/Editor/general_decorator/general_decorator.tscn")
var general_fcall_class = preload("res://addons/btree/Editor/general_fcall/general_fcall.gd")
var minim_scene = preload("res://addons/btree/Editor/minim_node/minim_node.tscn")
var inverter_scene = preload("res://addons/btree/Editor/inverter/inverter.tscn")

const Runtime = preload('../Runtime/runtime.gd')

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
		if  n.type == Runtime.TNodeTypes.ROOT:
			var node = get_node("root")
			node.set_data(n.data)
		else:
			var node = create_node(n)
			add_child(node)
	for c in data.tree.connection:
		connect_node(c.from, c.from_port, c.to, c.to_port)
	return

func create_node(n):
	if  n.type == Runtime.TNodeTypes.TASK:
		var task = general_fcall_scene.instance()
		task.as_task()
		task.name = n.name
		task.set_data(n.data)
		return task
	elif n.type == Runtime.TNodeTypes.SEQUENCE:
		var seq = general_decorator_scene.instance()
		seq.as_sequence()
		seq.name = n.name
		seq.set_data(n.data)
		return seq
	elif n.type == Runtime.TNodeTypes.SELECTOR:
		var sel = general_decorator_scene.instance()
		sel.as_selector()
		sel.name = n.name
		sel.set_data(n.data)
		return sel
	elif n.type == Runtime.TNodeTypes.PRIORITY_SELECTOR:
		var pse = pselector_scene.instance()
		pse.name = n.name
		pse.set_data(n.data)
		return pse
	elif n.type == Runtime.TNodeTypes.PRIORITY_CONDITION:
		var inst = general_fcall_scene.instance()
		inst.as_priority_condition()
		inst.name = n.name
		inst.set_data(n.data)
		return inst
	elif n.type == Runtime.TNodeTypes.PARALEL:
		var par = general_decorator_scene.instance()
		par.as_paralel()
		par.name = n.name
		par.set_data(n.data)
		return par
	elif n.type == Runtime.TNodeTypes.MUTE:
		var mute = mute_scene.instance()
		mute.name = n.name
		mute.set_data(n.data)
		return mute
	elif n.type == Runtime.TNodeTypes.REPEAT:
		var rep = repeat_scene.instance()
		rep.name = n.name
		rep.set_data(n.data)
		return rep
	elif n.type == Runtime.TNodeTypes.WHILE:
		var whi = general_fcall_scene.instance()
		whi.as_while()
		whi.name = n.name
		whi.set_data(n.data)
		return whi
	elif n.type == Runtime.TNodeTypes.WAIT:
		var w = wait_scene.instance()
		w.name = n.name
		w.set_data(n.data)
		return w
	elif n.type == Runtime.TNodeTypes.RACE:
		var r = general_decorator_scene.instance()
		r.as_race()
		r.name = n.name
		r.set_data(n.data)
		return r
	elif  n.type == Runtime.TNodeTypes.RANDOM_SELECTOR:
		var r = general_decorator_scene.instance()
		r.as_random_selector()
		r.name = n.name
		r.set_data(n.data)
		return r
	elif  n.type == Runtime.TNodeTypes.RANDOM_SEQUENCE:
		var r = general_decorator_scene.instance()
		r.as_random_sequence()
		r.name = n.name
		r.set_data(n.data)
		return r
	elif n.type == Runtime.TNodeTypes.INVERTER:
		var r = inverter_scene.instance()
		r.name = n.name
		r.set_data(n.data)
		return r
	elif  n.type == Runtime.TNodeTypes.MINIM:
		var m = minim_scene.instance()
		m.name = n.name
		m.set_data(n.data)
		return m
	return null

func connection_request(from, from_slot, to, to_slot):
	if  from == to:
		return
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
	get_parent().hint("Saving Data")
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

func disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	return

func slot_removed(name, slot):
	for i in get_connection_list():
		if  i.from == name and i.from_port == slot:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
	return

func _input(event):
	if  not is_visible_in_tree():
		return

	if  event is InputEventKey:
		if  event.scancode == KEY_M and not event.pressed and event.control and event.shift:
			minimize_node()
			get_parent().hint("Node Minimized")

		if  event.scancode == KEY_C and not event.pressed and event.control and event.shift:
			copy_node()
			get_parent().hint("Recursive Duplicate Node")

		if  event.scancode == KEY_X and not event.pressed and event.control and event.shift:
			rdelete_node()
			get_parent().hint("Recursive Delete Node")

		if  event.scancode == KEY_SPACE and event.pressed and event.control and event.shift:
			rmove_node()
			get_parent().hint("Recursive Move Node")

		if  event.scancode == KEY_S and not event.pressed and event.control:
			_on_save_pressed()

		if  event.scancode == KEY_F  and not event.pressed and event.control:
			focus_selected()
		return

	if  event is InputEventMouseButton:
		if  event.pressed and event.button_index == 4 and event.control and event.shift:
			zoom += 0.1
			accept_event()
			get_parent().hint("Zoom In")
			return
		if  event.pressed and event.button_index == 5 and event.control and event.shift:
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

var minim_class = preload("res://addons/btree/Editor/minim_node/minim_node.gd")

func minimize_node():
	if  not selected:
		get_parent().hint("No Node Selected")
		return
	if  not selected.selected:
		get_parent().hint("No Node Selected")
		return
	if  selected is minim_class:
		get_parent().hint("Cannot Minimize \"Minimize\" Node !")
		return
	if  selected.name == "root":
		get_parent().hint("Cannot Minimize \"root\" Node !")
		return
	var soffset = selected.offset
	var m_inst = minim_scene.instance()
	m_inst.offset = soffset
	add_child(m_inst)

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

	var connection = []
	for i in nodes:
		for j in get_connection_list():
			if  i.name == j.from:
				connection.append(j)

	var current_connection = null
	for i in get_connection_list():
		if  i.to == cp.name:
			current_connection = i
			break

	m_inst.data = {}
	m_inst.data["connection"] = connection
	m_inst.data["nodes"] = nodes

	nodes = []
	for i in get_children():
		if  i is GraphNode:
			var node = {
				"name": i.name,
				"type": i.type,
				"data":i.get_data()
			}
			nodes.append(node)

	var mroot = find(selected.name, nodes)
	build_tree(mroot, get_connection_list(), nodes)
	m_inst.data["root"] = mroot

	for i in get_connection_list():
		if  i.to == selected.name:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)

	if  current_connection:
		connect_node(current_connection.from, current_connection.from_port, m_inst.name, 0)

	for i in m_inst.data["connection"]:
		disconnect_node(i.from, i.from_port, i.to, i.to_port)

	for i in m_inst.data["nodes"]:
		if  has_node(i.name):
			var n = get_node(i.name)
			n.queue_free()
	selected = m_inst
	set_selected(m_inst)
	return

func maximize_node(minim):
	var data  = minim.data

	var connection = data.connection
	var nodes = data.nodes
	var root = data.root

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
		if  i.name == mapping[root.name]:
			rinst = i
			break

	if  rinst:
		var shifted = minim.offset - rinst.offset
		for i in inst_node:
			i.offset += shifted

	for i in nodes:
		for j in connection:
			if  i.name == j.from or i.name == j.to:
				connect_node(mapping[j.from], j.from_port, mapping[j.to], j.to_port)

	for i in get_connection_list():
		if  i.to == minim.name:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
			connect_node(i.from, i.from_port, rinst.name, 0)

	minim.queue_free()
	selected = rinst
	set_selected(rinst)
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
			if  i.name == j.from or i.name == j.to:
				disconnect_node(j.from, j.from_port, j.to, j.to_port)

	for i in nodes:
		if  has_node(i.name):
			var n = get_node(i.name)
			n.free()
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

func node_selected(node):
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
			else:
				var itoken = i.name
				var mtoken = most_similar.name
				if  i is general_fcall_class or i is minim_class:
					itoken = i.search_token()
				if  most_similar is general_fcall_class:
					mtoken = most_similar.search_token()
				if  mtoken.similarity(new_text) < itoken.similarity(new_text):
					most_similar = i
	if  most_similar:
		scroll_offset = most_similar.offset * zoom - ((rect_size / 2) - (most_similar.rect_size / 2))
	return

func popup_request(position):
	$group/Create.get_popup().popup(Rect2(position, Vector2(1, 1)))
	return
