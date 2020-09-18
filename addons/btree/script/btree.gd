extends Node

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

export(Dictionary) var tree = {}
export(bool) var enable = true
export(int, '_process', '_physics_process') var run_on = 0
var rtree: Runtime.TNode = null

func _ready():
	if  get_tree().has_meta("BT_SERVER"):
		var debug = get_tree().get_meta("BT_SERVER")
		debug.register_instance(get_parent())
	return

func _enter_tree():
	rtree = Runtime.create_runtime(tree.get('root', {}), get_parent())
	return

func _process(delta):
	if run_on == 0:
		btree_process(delta)
	return

func _physics_process(delta):
	if run_on == 1:
		btree_process(delta)
	return

func btree_process(_delta):
	if  not enable or not rtree:
		return
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
