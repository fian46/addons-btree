extends Node

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

export(Dictionary) var tree = {}
export(bool) var enable = true
export(int, '_process', '_physics_process') var run_on = 0
export(int, "resume", "restart") var on_enable = 0
export(String) var _tree_id = ""
var rtree: Runtime.TNode = null
var swap_tree

func _ready():
	generate_id()
	if  get_tree().has_meta("BT_SERVER"):
		var debug = get_tree().get_meta("BT_SERVER")
		debug.register_instance(get_parent())
	return

func generate_id():
	var cn:Node = self
	while cn != null && (cn.filename == "" || cn.filename == null):
		cn = cn.get_parent()
	if  cn:
		var path = cn.get_path_to(self)
		_tree_id = str(hash(cn.filename)) + str(hash(str(path)))
	return

func _enter_tree():
	create_runtime()
	return

func create_runtime():
	rtree = Runtime.create_runtime(tree.get('root', {}), get_parent())
	return

func swap_runtime(new_tree):
	swap_tree = new_tree
	return

func _process(delta):
	if  run_on == 0:
		btree_process(delta)
	return

func _physics_process(delta):
	if  run_on == 1:
		btree_process(delta)
	return

var was_disable = false
func btree_process(_delta):
	if  not enable or not rtree:
		was_disable = true
		return
	if  was_disable:
		if  on_enable == 1:
			rtree.reset()
		was_disable = false
	tick()
	return

var debug

func tick():
	if  debug and debug.get_ref():
		var ref = debug.get_ref()
		if  not ref.paused:
			_tick()
		else:
			if  ref.step:
				ref.step = false
				_tick()
	else:
		_tick()
	return

func _tick():
	if  swap_tree:
		tree = swap_tree
		swap_tree = null
		create_runtime()
		rtree.reset()
	
	var status = rtree.tick()
	flush()
	if  status != Runtime.Status.RUNNING:
		rtree.reset()
		flush()
	return

func flush():
	if  debug:
		var ref = debug.get_ref()
		if  ref:
			ref.flush(self)
	return
