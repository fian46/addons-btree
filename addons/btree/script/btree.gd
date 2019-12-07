extends Node

var target = null
export(Dictionary) var tree = {}
var rtree = null

func _enter_tree():
	target = get_parent()
	var rt = preload("res://addons/btree/Runtime/runtime.gd")
	rtree = rt.create_runtime(tree.root, target)
	return

func _process(delta):
	if  rtree:
		var ts = rtree.tick()
		if  ts != 0:
			rtree.reset()
	return