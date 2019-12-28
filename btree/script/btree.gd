extends Node

export(Dictionary) var tree = {}
export(bool) var enable = true
var target = null
var rtree = null

func _enter_tree():
	target = get_parent()
	var rt = preload("res://addons/btree/Runtime/runtime.gd")
	if  tree.has("root"):
		rtree = rt.create_runtime(tree.root, target)
	return

func _process(delta):
	if  not enable:
		return
	if  rtree:
		var ts = rtree.tick()
		if  ts != 0:
			rtree.reset()
	return