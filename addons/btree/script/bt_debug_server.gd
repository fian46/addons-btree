extends Node

const rt = preload("res://addons/btree/Runtime/runtime.gd")
var bt_script = load("res://addons/btree/script/btree.gd")
var server = WebSocketServer.new()
var objects = []
var connected_id = -1
var queue = []
var send_tree = false
var selected_instance
var paused = false
var step = false
var hot_reload_cache = {}

func _ready():
	get_tree().set_meta("BT_SERVER", self)
	if  not OS.is_debug_build():
		print("BT release build")
		return
	print("BT debug build")
	server = WebSocketServer.new()
	server.listen(7777)
	server.connect("client_connected", self, "debug_attached")
	server.connect("client_disconnected", self, "debug_detached")
	server.connect("data_received", self, "client_data")
	print("BT debug server init")
	return

func _exit_tree():
	if  server && connected_id != -1:
		server.get_peer(connected_id).close(0, "")
		for i in range(120):
			server.poll()
	return

func client_data(id):
	var msg = server.get_peer(id).get_var(true)
	if  msg.type == 0:
		send_tree = msg.visible
		if  not send_tree:
			paused = false
			step = false
			if  selected_instance:
				selected_instance.debug = null
				selected_instance = null
	elif msg.type == 1:
		if  msg.instance_id == -1:
			paused = false
			step = false
			if  selected_instance:
				selected_instance.debug = null
			return
		var new_instance = instance_from_id(msg.instance_id)
		if  selected_instance != new_instance:
			paused = false
			step = false
			if  selected_instance:
				selected_instance.debug = null
			selected_instance = new_instance
			if  selected_instance:
				selected_instance.debug = weakref(self)
				flush(selected_instance)
		else:
			selected_instance.debug = weakref(self)
	elif msg.type == 2:
		paused = msg.paused
	elif msg.type == 3:
		step = msg.step
	elif msg.type == 4:
		hot_reload(msg.id, msg.data)
	return

func hot_reload(id, data):
	hot_reload_cache[id] = data
	for wr in objects:
		var ref = wr.get_ref()
		if  ref:
			for child in ref.get_children():
				if  child is bt_script:
					if  child._tree_id == id:
						child.swap_runtime(data)
	return

func debug_detached(id, was_clean):
	if  id == connected_id:
		connected_id = -1
		send_tree = false
	return

func debug_attached(id, protocol):
	if  connected_id != -1:
		server.get_peer(connected_id).close()
		connected_id = -1
	send_tree = false
	connected_id = id
	return

func flush(btree):
	if  send_tree:
		var msg = {}
		msg.type = 1
		msg.payload = extract_data(btree)
		msg.version = btree.get_instance_id()
		write(msg)
	return

func _process(delta):
	schedule_cleanup()
	if  server:
		if  server.get_connection_status() != 0:
			while queue.size() > 0 and server.get_connection_status() == 2:
				var front = queue.pop_front()
				server.get_peer(connected_id).put_var(front, true)
			server.poll()
	return

func extract_data(btree):
	var offset = {}
	walk_tree(Vector2.ZERO, btree.tree.root, offset)
	return walk(btree.rtree, offset)

func walk_tree(shift:Vector2, node:Dictionary, result:Dictionary):
	if  node.type == rt.TNodeTypes.MINIM:
		var shifted = node.data.offset + shift - node.data.data.root.data.offset
		walk_tree(shifted, node.data.data.root, result)
	else:
		result[node.name] = node.data.offset + shift
		for i in node.child:
			walk_tree(shift, i, result)
	return

func walk(nd:rt.TNode, offset:Dictionary):
	if  nd == null:
		return null
	var node = {}
	node.name = nd.name
	node.offset = offset[nd.name]
	if  nd.get("fn"):
		node.fn = nd.get("fn")
		node.dp = nd.get("params")
	
	if  not nd.ticked:
		node.status = "IDLE"
	else:
		if  nd.status == 0:
			node.status = "RUNNING"
		elif nd.status == 1:
			node.status = "SUCCEED"
		else:
			node.status = "FAILED"
	node.child = []
	if  nd is rt.CompositeTNode:
		for i in nd.children:
			var ch = walk(i, offset)
			node.child.append(ch)
	elif nd is rt.DecoratorTNode:
		var ch = walk(nd.child, offset)
		node.child.append(ch)
	return node

func write(msg):
	queue.append(msg)
	return

func register_instance(root):
	objects.append(weakref(root))
	for ch in root.get_children():
		if  ch is bt_script:
			if  hot_reload_cache.has(ch._tree_id):
				var tree = hot_reload_cache[ch._tree_id]
				ch.swap_runtime(tree)
	return

var tick = 0
func schedule_cleanup():
	tick += 1
	if  tick > 60:
		tick = 0
		cleanup()
	return

var net_data = {}
func cleanup():
	var clone = []
	for i in objects:
		var ref = i.get_ref()
		if  ref:
			clone.append(i)
	objects = clone
	net_data.clear()
	for i in objects:
		var ref = i.get_ref() as Node
		var parent = {}
		parent.id = ref.get_instance_id()
		parent.name = str("[", ref.name, "@" , ref.get_instance_id(), "]")
		var tree = {}
		for child in ref.get_children():
			if  child is bt_script:
				var btree = {}
				btree.id = child.get_instance_id()
				btree.name = str("[ ", child.name, "@", child.get_instance_id(), "]")
				tree[btree.name] = btree
		parent.tree = tree
		net_data[parent.name] = parent
	if  send_tree:
		var msg = {}
		msg.type = 0
		msg.payload = net_data
		write(msg)
	schedule_cleanup()
	return
