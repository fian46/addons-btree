tool
extends WindowDialog

const rt = preload("res://addons/btree/Runtime/runtime.gd")

func _on_rtree_about_to_show():
	version = -1
	var graph = $layout/split/debug_graph
	clear_editor(graph)
	$client_debugger.ensure_connection()
	var msg = {}
	msg.type = 0
	msg.visible = true
	write(msg)
	return

var version = -1
var skip = 0
func read(msg):
	if  msg.type == 0:
		var data = msg.payload
		update_tree(data)
	if  msg.type == 1:
		queue_update(msg)
	return

var queue = []

func queue_update(msg):
	queue.append(msg)
	return

var step = false
var pause = false

func _process(delta):
	if  pause:
		var msg = {}
		msg.type = 2
		msg.paused = true
		write(msg)
	else:
		var msg = {}
		msg.type = 2
		msg.paused = false
		write(msg)
	
	if step:
		var msg = {}
		msg.type = 3
		msg.step = true
		write(msg)
	else:
		var msg = {}
		msg.type = 3
		msg.step = false
		write(msg)

	if  queue.size() > 20:
		while queue.size() > 1:
			update_graph()
	else:
		update_graph()
	return

func update_graph():
	if  queue.size() == 0:
		return
	var msg = queue.pop_front()
	if  version != msg.version:
		pause = false
		step = false
		version = msg.version
		generate_tree(msg.payload)
		update_state(msg.payload)
	else:
		update_state(msg.payload)
	return

func update_state(data):
	var graph = $layout/split/debug_graph
	u_walk(data, graph)
	return

func u_walk(data, graph):
	var node = node_map[data.name]
	update_label(node, data.status)
	if  not data.has("child"):
		data.child = []
	for i in data.child:
		if  i == null:
			continue
		u_walk(i, graph)
	return

func update_label(node, status):
	if  not node:
		return
	node.text = status
	if  status == "IDLE":
		node.self_modulate = Color.white
	elif  status == "RUNNING":
		node.self_modulate = Color.yellow
	elif  status == "SUCCEED":
		node.self_modulate = Color.green
	else:
		node.self_modulate = Color.red
	return

var node_map = {}

func generate_tree(data:Dictionary):
	var graph = $layout/split/debug_graph
	clear_editor(graph)
	node_map.clear()
	walk(data, graph)
	return

func walk(data, graph):
	var node = create_node(data, data.child.size()) as GraphNode
	node_map[node.name] = node.get_child(0)
	if  data.has("fn"):
		var label = Label.new()
		label.text = str("Function Name : ", data.fn)
		node.add_child(label)
		var dp = data.dp
		if  dp.size() > 0:
			var pt = Label.new()
			pt.text = "Parameters : "
			node.add_child(pt)
		for i in range(dp.size()):
			var param = Label.new()
			param.text = str(i, " : ", dp[i])
			node.add_child(param)
	node.offset = data.offset
	graph.add_child(node)
	for i in range(data.child.size()):
		var sel = data.child[i]
		if  sel == null:
			continue
		var child = walk(sel, graph)
		graph.connect_node( node.name, i, child.name, 0)
	return node

var node_scene = preload("res://addons/btree/Editor/root.tscn")

func create_node(data:Dictionary, slot_count:int):
	var node = node_scene.instance()
	node.title = data.name
	node.name = data.name
	if  slot_count > 0:
		for i in range(slot_count):
			node.add_child(Label.new())
			if  i == 0 and data.name != "root":
				node.set_slot(i, true, 0, Color.blue, true, 0, Color.blue)
			else:
				node.set_slot(i, false, 0, Color.blue, true, 0, Color.blue)
	else:
		node.add_child(Label.new())
		node.set_slot(0, true, 0, Color.blue, false, 0, Color.blue)
	node.get_child(0).text = data.status
	return node

func clear_editor(graph):
	for i in graph.get_connection_list():
		graph.disconnect_node(i.from, i.from_port, i.to, i.to_port)
	for i in graph.get_children():
		if  i is GraphNode:
			graph.remove_child(i)
			i.queue_free()
	return

var bt_id = {}
func update_tree(data:Dictionary):
	var tree:Tree = $layout/split/rtree
	var selected_text = ""
	if  tree.get_selected():
		selected_text = tree.get_selected().get_text(0)
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	bt_id.clear()
	for i in data.keys():
		var parent = data[i]
		var item = tree.create_item(root)
		item.set_text(0, parent.name)
		if  selected_text == item.get_text(0):
			item.select(0)
		for j in parent.tree.keys():
			var bt = parent.tree[j]
			var btitem = tree.create_item(item)
			btitem.set_text(0, str("BT-", bt.name))
			if  selected_text == btitem.get_text(0):
				btitem.select(0)
			bt_id[btitem] = bt.id
	update_start_debug_btn()
	return

func write(msg):
	$client_debugger.write(msg)
	return

func _on_rtree_popup_hide():
	var msg = {}
	msg.type = 0
	msg.visible = false
	write(msg)
	return

func _on_rtree_item_selected():
	update_start_debug_btn()
	return

func update_start_debug_btn():
	var item = $layout/split/rtree.get_selected()
	var selected = item != null and item.get_text(0).begins_with("BT-") 
	if  selected:
		start_debug()
	else:
		stop_debug()
	return

func error():
	$layout/split/rtree.clear()
	stop_debug()
	return

func start_debug():
	$layout/hbox3.visible = true
	var tree = $layout/split/rtree
	var selected = tree.get_selected()
	if  bt_id.has(selected):
		var msg = {}
		msg.type = 1
		msg.instance_id = bt_id[selected]
		write(msg)

func stop_debug():
	$layout/hbox3.visible = false
	var graph = $layout/split/debug_graph
	queue.clear()
	clear_editor(graph)
	var msg = {}
	msg.type = 1
	msg.instance_id = -1
	version = -1
	write(msg)
	return

func _on_pause_pressed():
	pause = not pause
	return

func _on_step_button_down():
	step = true
	return

func _on_step_button_up():
	step = false
	return
