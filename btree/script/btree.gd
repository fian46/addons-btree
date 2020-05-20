extends Node

const Runtime = preload("../Runtime/runtime.gd")

export(Dictionary) var tree = {}
export(bool) var enable = true
export(int, '_process', '_physics_process') var run_on = 0
var rtree: Runtime.TNode = null

func _enter_tree():
	rtree = Runtime.create_runtime(tree.get('root', {}), get_parent())


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
	if rtree.tick() != Runtime.Status.RUNNING:
		rtree.reset()
	return
