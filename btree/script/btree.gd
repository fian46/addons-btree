extends Node

const Runtime = preload("../Runtime/runtime.gd")

export(Dictionary) var tree = {}
export(bool) var enable = true
var rtree: Runtime.TNode = null

func _enter_tree():
	rtree = Runtime.create_runtime(tree.get('root', {}), get_parent())
	return

func _process(_delta):
	if  not enable or not rtree:
		return
	if rtree.tick() != Runtime.Status.RUNNING:
		rtree.reset()
	return
