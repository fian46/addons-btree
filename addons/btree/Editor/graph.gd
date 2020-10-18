tool
extends GraphEdit

var data = null
var root_object = null
var control = null
var active = false
var undo_redo:UndoRedo
var editor_interface:EditorInterface
export(NodePath) var hint_path:NodePath

func _ready():
	set_process_input(true)
	return

func hint(value):
	get_node(hint_path).text = value
	return

func reload():
	clear_editor()
	if  not data:
		return
	if  not control:
		return
	if  not node_has_script():
		get_parent().get_parent().halt("you need to attach script in parent node of BTREE")
		return
	if  not valid_script():
		get_parent().get_parent().halt("node script is error please fix it first before edit")
		return
	build_tree_from_data()
	return

func node_has_task():
	var ml = data.get_parent().get_method_list()
	for m in ml:
		if  m.name.begins_with("task_") and m.args.size() == 1:
			return true
	return false

func node_has_script():
	var pscript:GDScript = data.get_parent().get_script()
	if  not pscript:
		return false
	return true

func valid_script():
	var pscript:GDScript = data.get_parent().get_script()
	if  not pscript:
		return false
	
	var file = File.new()
	file.open(pscript.resource_path, File.READ)
	var source_code = file.get_as_text()
	file.close()
	
	var cscript:GDScript = GDScript.new()
	cscript.set_source_code(source_code)
	if  cscript.reload(false) != OK:
		return false
	return true

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
var general_decorator_script = preload("res://addons/btree/Editor/general_decorator/general_decorator.gd")
var general_fcall_class = preload("res://addons/btree/Editor/general_fcall/general_fcall.gd")
var minim_scene = preload("res://addons/btree/Editor/minim_node/minim_node.tscn")
var inverter_scene = preload("res://addons/btree/Editor/inverter/inverter.tscn")
var random_repeat_scene = preload("res://addons/btree/Editor/repeat/random_repeat.tscn")
var random_wait_scene = preload("res://addons/btree/Editor/wait_node/random_wait_node.tscn")
const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

func build_tree_from_data():
	if  not data:
		return
	if  not data.tree:
		return
	if  not data.tree.has("nodes"):
		return
	load_from(data.tree)
	return

func create_node(n):
	var node
	if  n.type == Runtime.TNodeTypes.TASK:
		node = general_fcall_scene.instance()
		node.as_task()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.SEQUENCE:
		node = general_decorator_scene.instance()
		node.as_sequence()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.SELECTOR:
		node = general_decorator_scene.instance()
		node.as_selector()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.PRIORITY_SELECTOR:
		node = pselector_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.PRIORITY_CONDITION:
		node = general_fcall_scene.instance()
		node.as_priority_condition()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.PARALEL:
		node = general_decorator_scene.instance()
		node.as_paralel()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.MUTE:
		node = mute_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.REPEAT:
		node = repeat_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.WHILE:
		node = general_fcall_scene.instance()
		node.as_while()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.WAIT:
		node = wait_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.RACE:
		node = general_decorator_scene.instance()
		node.as_race()
		node.name = n.name
		node.set_data(n.data)
	elif  n.type == Runtime.TNodeTypes.RANDOM_SELECTOR:
		node = general_decorator_scene.instance()
		node.as_random_selector()
		node.name = n.name
		node.set_data(n.data)
	elif  n.type == Runtime.TNodeTypes.RANDOM_SEQUENCE:
		node = general_decorator_scene.instance()
		node.as_random_sequence()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.INVERTER:
		node = inverter_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif  n.type == Runtime.TNodeTypes.MINIM:
		node = minim_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.RANDOM_REPEAT:
		node = random_repeat_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	elif n.type == Runtime.TNodeTypes.RANDOM_WAIT:
		node = random_wait_scene.instance()
		node.name = n.name
		node.set_data(n.data)
	(node as GraphNode).connect("dragged", self, "node_dragged", [node])
	(node as GraphNode).connect("resize_request", self, "resize_request", [node])
	if  node is general_decorator_script:
		node.undo_redo = undo_redo
	return node

func snapc_vec(size):
	size.x /= snap_distance
	size.y /= snap_distance
	size.x = ceil(size.x)
	size.y = ceil(size.y)
	size *= snap_distance
	return size

func resize_request(nsize:Vector2, node:GraphNode):
	var size = snapc_vec(nsize)
	var snap = snapc_vec(node.rect_size)
	var fit = true
	var temp = node.rect_size
	node.rect_size = size
	fit = node.rect_size.is_equal_approx(size)
	node.rect_size = temp
	if  not fit:
		node.rect_size = Vector2.ZERO
		size = snapc_vec(node.rect_size)
		node.rect_size = temp
	if  not size.is_equal_approx(snap):
		undo_redo.create_action("node resize")
		undo_redo.add_do_method(self, "update_node_rect_size", node.name, size)
		undo_redo.add_undo_method(self, "update_node_rect_size", node.name, node.rect_size)
		undo_redo.commit_action()
	return

func update_node_rect_size(node_name, size):
	var node:GraphNode = get_node_or_null(node_name)
	if  node:
		node.rect_size = size
		if  not node.rect_size.is_equal_approx(size):
			node.rect_size = snapc_vec(node.rect_size)
	return

func connection_request(from, from_slot, to, to_slot):
	if  from == to:
		return
	var dc = []
	for i in get_connection_list():
		if  from == i.from and from_slot == i.from_port:
			dc.append([i.from, i.from_port, i.to, i.to_port])
		if  to == i.to and to_slot == i.to_port:
			dc.append([i.from, i.from_port, i.to, i.to_port])
	undo_redo.create_action("connect_node")
#	redo
	for i in dc:
		undo_redo.add_do_method(self, "disconnect_node", i[0], i[1], i[2], i[3])
	undo_redo.add_do_method(self, "connect_node", from, from_slot, to, to_slot)
#	undo
	undo_redo.add_undo_method(self, "disconnect_node", from, from_slot, to, to_slot)
	for i in dc:
		undo_redo.add_undo_method(self, "connect_node", i[0], i[1], i[2], i[3])
	undo_redo.commit_action()
	return

func child_delete(node):
	var cp = []
	for i in get_connection_list():
		if  node.name == i.from or node.name == i.to:
			cp.append([i.from, i.from_port, i.to, i.to_port])
	
	var data = {}
	data["name"] = node.name
	data["type"] = node.type
	data["data"] = node.get_data()
	
	undo_redo.create_action("delete node")
	undo_redo.add_do_method(self, "remove_node", node.name, cp)
	undo_redo.add_undo_method(self, "re_create_node", data, cp)
	undo_redo.commit_action()
	return

func re_create_node(data, cp):
	var node = create_node(data)
	add_child(node)
	for i in cp:
		connect_node(i[0], i[1], i[2], i[3])
	return

func remove_node(node_name, cp):
	for i in cp:
		disconnect_node(i[0], i[1], i[2], i[3])
	var node = get_node_or_null(node_name)
	if node:
		node.queue_free()
	else:
		print("NOT FOUND : ",node_name)
	return

func _on_save_pressed():
	if  not active:
		print("BT Editor Skip Saving Data !")
		return
	if  not data:
		hint("No BTREE selected !")
		return
	if  not valid_script():
		print("BT Editor Skip Saving, Script Error !")
		return
	hint("Saving Data")
	print("BT Save")
	data.tree = create_snapshot()
	
	var cn:Node = data
	while cn != null && (cn.filename == "" || cn.filename == null):
		cn = cn.get_parent()
	if  cn:
		var path = cn.get_path_to(data)
		data._tree_id = str(hash(cn.filename)) + str(hash(str(path)))
	
	var client = get_parent().get_parent().get_node("rtree/client_debugger")
	var ws:WebSocketClient = client.client as WebSocketClient
	if  ws.get_connection_status() == 2:
		hint("BT hot reload")
		var msg = {}
		msg.type = 4
		msg.id = data._tree_id
		msg.data = data.tree
		client.write(msg)
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
	undo_redo.create_action("disconnect_node")
	undo_redo.add_do_method(self, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "connect_node", from, from_slot, to, to_slot)
	undo_redo.commit_action()
	return

func ps_add_slot(name):
	undo_redo.create_action("add_slot")
	undo_redo.add_do_method(self, "add_slot1", name)
	undo_redo.add_undo_method(self, "del_slot", name)
	undo_redo.commit_action()
	return

func ps_del_slot(name):
	var node = get_node(name)
	if  node.get_child_count() <= 1:
		return
	var port = node.get_connection_output_count() - 1
	var con
	for i in get_connection_list():
		if  i.from == name and i.from_port == port:
			con = i
			break
	undo_redo.create_action("remove_slot")
	if  con:
		undo_redo.add_do_method(self, "disconnect_node", con.from, con.from_port, con.to, con.to_port)
	undo_redo.add_do_method(self, "del_slot", name)
	undo_redo.add_undo_method(self, "add_slot1", name)
	if  con:
		undo_redo.add_undo_method(self, "connect_node", con.from, con.from_port, con.to, con.to_port)
	undo_redo.commit_action()
	return


func gd_add_slot(name):
	undo_redo.create_action("add_slot")
	undo_redo.add_do_method(self, "add_slot", name)
	undo_redo.add_undo_method(self, "del_slot", name)
	undo_redo.commit_action()
	return

func gd_del_slot(name):
	var node = get_node(name)
	if  node.get_child_count() <= 1:
		return
	var port = node.get_connection_output_count() - 1
	var con
	for i in get_connection_list():
		if  i.from == name and i.from_port == port:
			con = i
			break
	undo_redo.create_action("remove_slot")
	if  con:
		undo_redo.add_do_method(self, "disconnect_node", con.from, con.from_port, con.to, con.to_port)
	undo_redo.add_do_method(self, "del_slot", name)
	undo_redo.add_undo_method(self, "add_slot", name)
	if  con:
		undo_redo.add_undo_method(self, "connect_node", con.from, con.from_port, con.to, con.to_port)
	undo_redo.commit_action()
	return

func add_slot1(name):
	var node:GraphNode = get_node(name)
	node.add_child(label(name))
	node.set_slot(node.get_child_count() - 1, false, 0, Color.blue, true, 1, Color.yellow, null, null)
	return

func add_slot(name):
	var node:GraphNode = get_node(name)
	node.add_child(label(name))
	node.set_slot(node.get_child_count() - 1, false, 0, Color.blue, true, 0, Color.blue, null, null)
	return

func del_slot(name):
	var node:GraphNode = get_node(name)
	if  get_child_count() > 1:
		node.clear_slot(node.get_child_count() - 1)
		node.remove_child(node.get_child(node.get_child_count() - 1))
		node.rect_size = Vector2.ZERO
	return

func label(name):
	var node = get_node(name)
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
	l.text = str(node.get_child_count())
	return l

func slot_removed(name, slot):
	for i in get_connection_list():
		if  i.from == name and i.from_port == slot:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
	return

func gui_input(event):
	if  not is_visible_in_tree():
		return

	if  event is InputEventKey:
		if  event.scancode == KEY_M and not event.pressed and event.control and event.shift:
			minimize_node()
			hint("Node Minimized")
			accept_event()

		if  event.scancode == KEY_C and not event.pressed and event.control and event.shift:
			copy_node()
			hint("Recursive Duplicate Node")
			accept_event()

		if  event.scancode == KEY_X and not event.pressed and event.control and event.shift:
			rdelete_node()
			hint("Recursive Delete Node")
			accept_event()

		if  event.scancode == KEY_SPACE and event.pressed and event.control and event.shift:
			rmove_node()
			hint("Recursive Move Node")
			accept_event()

		if  event.scancode == KEY_F  and not event.pressed and event.control:
			focus_selected()
			hint("Focus Node")
			accept_event()

		if  event.scancode == KEY_J  and not event.pressed and event.control:
			jump_to_sourcecode()
			hint("Jump To Sourcecode")
			accept_event()
		if  event.scancode == KEY_LEFT and not event.pressed and event.control and event.shift:
			hint("Prev search")
			_on_prev_pressed()
			accept_event()
		if  event.scancode == KEY_RIGHT and not event.pressed and event.control and event.shift:
			hint("Next search")
			_on_next_pressed()
			accept_event()
		return

	if  event is InputEventMouseButton:
		if  event.button_index == 4 and event.control and event.shift:
			zoom += 0.1
			accept_event()
			hint("Zoom In")
			return
		if  event.button_index == 5 and event.control and event.shift:
			zoom -= 0.1
			accept_event()
			hint("Zoom Out")
			return
	return

var callable = preload("res://addons/btree/Editor/general_fcall/general_fcall.gd")
func jump_to_sourcecode():
	if  selected is callable:
		var fn:String = selected.get_data().fn
		var split:Array = data.get_parent().get_script().source_code.split("\n")
		var selected_line = 0
		for code_line in range(split.size()):
			var current_line:String = split[code_line]
			if  current_line.similarity(fn) > split[selected_line].similarity(fn):
				selected_line = code_line
		editor_interface.edit_resource(data.get_parent().get_script())
		editor_interface.get_script_editor().goto_line(selected_line)
	return

var selected:Node

func copy_node():
	if  not selected:
		hint("No Node Selected")
		return
	if  not selected.selected:
		hint("No Node Selected")
		return
	if  selected.name == "root":
		hint("Cannot Duplicate \"root\" Node !")
		return

	var root_offset = (scroll_offset / zoom) + (get_local_mouse_position() / zoom)
	root_offset = snapc_vec(root_offset)
	
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
	
	var nmap = {}
	for i in nodes:
		var tnode = create_node(i)
		add_child(tnode)
		nmap[i.name] = tnode.name
	
	for i in nmap.values():
		var rm = get_node(i)
		remove_child(rm)
		rm.free()
	
	var con_pair = []
	for n in nodes:
		for j in get_connection_list():
			if  n.name == j.from:
				con_pair.append([nmap[j.from], j.from_port, nmap[j.to], j.to_port])
	
	for i in nodes:
		i.name = nmap[i.name]
	var shifted = root_offset - selected.offset
	undo_redo.create_action("recursive_copy")
	undo_redo.add_do_method(self, "create_graph", nodes, con_pair, shifted)
	undo_redo.add_undo_method(self, "delete_graph", nodes, con_pair)
	undo_redo.commit_action()
	return

func delete_graph(nodes, con_pair):
	for c in con_pair:
		disconnect_node(c[0], c[1], c[2], c[3])
	for n in nodes:
		if  has_node(n.name):
			var i = get_node(n.name)
			remove_child(i)
			i.free()
	return

func create_graph(nodes, con_pair, shifted):
	for n in nodes:
		var inst = create_node(n)
		inst.offset += shifted
		add_child(inst)
	for c in con_pair:
		connect_node(c[0], c[1], c[2], c[3])
	return

var minim_class = preload("res://addons/btree/Editor/minim_node/minim_node.gd")

func minimize_node():
	if  not selected:
		hint("No Node Selected")
		return
	if  not selected.selected:
		hint("No Node Selected")
		return
	if  selected is minim_class:
		hint("Cannot Minimize \"Minimize\" Node !")
		return
	if  selected.name == "root":
		hint("Cannot Minimize \"root\" Node !")
		return
	var tnode = minim_scene.instance()
	add_child(tnode)
	var target_name = tnode.name
	remove_child(tnode)
	tnode.free()
	undo_redo.create_action("minim_node")
	undo_redo.add_do_method(self, "do_minim", selected.name, target_name)
	undo_redo.add_undo_method(self, "do_maxim", target_name)
	undo_redo.commit_action()
	return

func do_minim(node_name, minim_name):
	var mnode = get_node_or_null(node_name)
	if  not mnode:
		return
	var soffset = mnode.offset
	var m_inst = minim_scene.instance()
	m_inst.connect("dragged", self, "node_dragged", [m_inst])
	m_inst.offset = soffset
	m_inst.name = minim_name
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

	var cp = find(mnode.name, nodes)
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

	var mroot = find(mnode.name, nodes)
	build_tree(mroot, get_connection_list(), nodes)
	m_inst.data["root"] = mroot

	for i in get_connection_list():
		if  i.to == mnode.name:
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
	undo_redo.create_action("expand_minim")
	undo_redo.add_do_method(self, "do_maxim", minim.name)
	undo_redo.add_undo_method(self, "do_minim", minim.data.root.name, minim.name)
	undo_redo.commit_action()
	return

func do_maxim(node_name):
	var minim = get_node_or_null(node_name)
	if  not minim:
		return
	
	remove_child(minim)
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
		hint("No Node Selected")
		return
	if  not selected.selected:
		hint("No Node Selected")
		return
	if  selected.name == "root":
		hint("Cannot Delete \"root\" Node")
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
	
	var dcon = []
	
	for i in nodes:
		for j in get_connection_list():
			if  i.name == j.from or i.name == j.to:
				dcon.append([j.from, j.from_port, j.to, j.to_port])
	
	var dnam = []
	for i in nodes:
		if  has_node(i.name):
			var node = get_node(i.name)
			var data = {}
			data["name"] = node.name
			data["type"] = node.type
			data["data"] = node.get_data()
			dnam.append(data)
	selected = null
	
	undo_redo.create_action("recursive_delete")
	for i in dcon:
		undo_redo.add_do_method(self, "disconnect_node", i[0], i[1], i[2], i[3])
	for i in dnam:
		undo_redo.add_do_method(self, "fnode", i)
	
	for i in dnam:
		undo_redo.add_undo_method(self, "cnode", i)
	for i in dcon:
		undo_redo.add_undo_method(self, "connect_node", i[0], i[1], i[2], i[3])
	undo_redo.commit_action()
	return

func cnode(ndata:Dictionary):
	var node = create_node(ndata)
	add_child(node)
	return

func fnode(ndata:Dictionary):
	var node = get_node(ndata.name)
	remove_child(node)
	node.free()
	return

func rmove_node():
	var root_offset = (scroll_offset / zoom) + (get_local_mouse_position() / zoom)
	root_offset = snapc_vec(root_offset)
	if  not selected:
		hint("No Node Selected")
		return
	if  not selected.selected:
		hint("No Node Selected")
		return
	if  (selected as GraphNode).offset.is_equal_approx(root_offset):
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
	
	var shifted_name = []
	for i in nodes:
		if  has_node(i.name):
			shifted_name.append(i.name)
	undo_redo.create_action("recursive_move")
	undo_redo.add_do_method(self, "shift_nodes", shifted_name, shifted)
	undo_redo.add_undo_method(self, "shift_nodes", shifted_name, -shifted)
	undo_redo.commit_action()
	return

func shift_nodes(names, shifted):
	for i in names:
		if  has_node(i):
			var node:GraphNode = get_node(i)
			node.offset += shifted
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

var tindex = 0
var search_text = ""

func _on_search_bar_text_changed(new_text):
	tindex = 0
	search_text = new_text
	var tpairs = comp_pairs(new_text)
	if  not tpairs.empty():
		var si = tpairs[tindex][1]
		scroll_offset = si.offset * zoom - ((rect_size / 2) - (si.rect_size / 2))
	return

func _on_next_pressed():
	tindex += 1
	var tpairs = comp_pairs(search_text)
	if  not tpairs.empty():
		tindex = clamp(tindex, 0, tpairs.size() - 1)
		var si = tpairs[tindex][1]
		scroll_offset = si.offset * zoom - ((rect_size / 2) - (si.rect_size / 2))
	return

func _on_prev_pressed():
	tindex -= 1
	var tpairs = comp_pairs(search_text)
	if  not tpairs.empty():
		tindex = clamp(tindex, 0, tpairs.size() - 1)
		var si = tpairs[tindex][1]
		scroll_offset = si.offset * zoom - ((rect_size / 2) - (si.rect_size / 2))
	return

func comp_pairs(text):
	var tpairs = []
	for i in get_children():
		if  i is GraphNode:
			var itoken = i.name
			if  i is general_fcall_class or i is minim_class:
				itoken = i.search_token()
			var similarity = itoken.similarity(text)
			if  similarity > 0.2:
				tpairs.append([itoken.similarity(text), i])
	tpairs.sort_custom(self, "sort_tp")
	return tpairs

func sort_tp(a, b):
	return a[0] > b[0]

export(NodePath) var create_path

func popup_request(position):
	var create = get_node(create_path)
	create.drop_offset = (scroll_offset / zoom) + (get_local_mouse_position() / zoom)
	create.undo_redo = undo_redo
	create.get_popup().popup(Rect2(position, Vector2(1, 1)))
	return

func _on_debug_pressed():
	get_parent().get_parent().debug()
	return

func _on_help_pressed():
	get_parent().get_parent().help()
	return

func _process(delta):
	if  not dragged_nodes.empty():
		var redo = []
		var undo = []
		for i in dragged_nodes:
			undo.append([i[2], i[0]])
			redo.append([i[2], i[1]])
		undo_redo.create_action("node_drag")
		undo_redo.add_do_method(self, "update_node_offset", redo)
		undo_redo.add_undo_method(self, "update_node_offset", undo)
		undo_redo.commit_action()
		dragged_nodes.clear()
	return

func update_node_offset(node_offset):
	for i in node_offset:
		var n:GraphNode = get_node_or_null(i[0])
		if  n:
			n.offset = (i[1] / snap_distance) * snap_distance
	return

var dragged_nodes = []
func node_dragged(start, end, node):
	var event = [start, end, node.name]
	dragged_nodes.append(event)
	return

func create_snapshot():
	var info = {}
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
	return info

func load_snapshot(data):
	clear_editor()
	load_from(data)
	return

func load_from(data):
	var nodes = data.nodes
	var conn = data.connection
	for n in nodes:
		if  n.type == Runtime.TNodeTypes.ROOT:
			var node = get_node("root")
			node.set_data(n.data)
		else:
			var node:GraphNode = create_node(n)
			add_child(node)
	for c in data.connection:
		connect_node(c.from, c.from_port, c.to, c.to_port)
	return

var param_scene = preload("res://addons/btree/Editor/task/param.tscn")

func add_param(name):
	undo_redo.create_action("add_param")
	undo_redo.add_do_method(self, "add_last", name)
	undo_redo.add_do_method(self, "sync_data_and_node", name)
	undo_redo.add_undo_method(self, "del_last", name)
	undo_redo.add_undo_method(self, "sync_data_and_node", name)
	undo_redo.commit_action()
	return

func add_last(name):
	var node = get_node(name)
	node.params.clear()
	var np = node.get_node("Params")
	for i in np.get_children():
		node.params.append(i.get_value())
	node.params.append(["", 1])
	return

func del_last(name):
	var node = get_node(name)
	node.params.clear()
	var np = node.get_node("Params")
	for i in np.get_children():
		node.params.append(i.get_value())
	node.params.pop_back()
	return

func sync_data_and_node(name):
	var node = get_node(name)
	var params:Array = node.params
	var target = node.get_node("Params")
	while params.size() > target.get_child_count():
		var inst = param_scene.instance()
		inst.connect("remove_me", node, "remove_param")
		target.add_child(inst)
	while params.size() < target.get_child_count():
		var del = target.get_child(0)
		target.remove_child(del)
		del.queue_free()
	for i in range(params.size()):
		var sel = target.get_child(i)
		sel.set_value(params[i])
		sel.update_label()
	node.rect_size = Vector2.ZERO
	return

func del_param(name, index):
	var node = get_node(name)
	var np = node.get_node("Params")
	var params:Array = node.params
	params.clear()
	for i in np.get_children():
		params.append(i.get_value())
	
	var old_value = params[index]
	
	undo_redo.create_action("remove_param")
	undo_redo.add_do_method(self, "cls_index", name, index)
	undo_redo.add_do_method(self, "sync_data_and_node", name)
	undo_redo.add_undo_method(self, "ins_index", name, index, old_value)
	undo_redo.add_undo_method(self, "sync_data_and_node", name)
	undo_redo.commit_action()
	return

func cls_index(name, index):
	var node = get_node(name)
	var np = node.get_node("Params")
	var params:Array = node.params
	params.clear()
	for i in np.get_children():
		params.append(i.get_value())
	params.remove(index)
	return

func ins_index(name, index, value):
	var node = get_node(name)
	var np = node.get_node("Params")
	var params:Array = node.params
	params.clear()
	for i in np.get_children():
		params.append(i.get_value())
	params.insert(index, value)
	return
