tool
extends EditorPlugin

var btree = load("res://addons/btree/script/btree.gd")
var ibtree = load("res://addons/btree/icons/icon_tree.svg")
var topi = load("res://addons/btree/icons/icon_tree_top.svg")
var dock_scene = preload("res://addons/btree/Editor/test.tscn")
var dock

func selection_changed():
	if  not dock:
		return
	var tree_editor = dock.get_node("TreeEditor")
	tree_editor.clear_editor()
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if  not selection:
		tree_editor.clear_data()
		dock.halt(true)
		return
	if  selection.size() == 1:
		if  selection[0] is btree:
			tree_editor.load_data(selection[0], self)
			dock.halt(false)
			if  dock.visible:
				tree_editor.reload()
		else:
			tree_editor.clear_data()
			dock.halt(true)
	else:
		tree_editor.clear_data()
		dock.halt(true)
	return

func make_visible(visible):
	if  not dock:
		return
	if  visible:
		print("build")
		selection_changed()
		dock.get_node("TreeEditor").reload()
		dock.show()
	else:
		dock.get_node("TreeEditor").clear_data()
		dock.get_node("TreeEditor").reload()
		dock.hide()
	return

func get_plugin_icon():
	return topi

func has_main_screen():
	return true

func get_plugin_name():
	return "Tree Editor"

func disable_plugin():
	if  not dock:
		return
	get_editor_interface().get_editor_viewport().remove_child(dock)
	dock.queue_free()
	dock = null
	return

func _enter_tree():
	print("enter")
	dock = dock_scene.instance()
	dock.halt(true)
	add_custom_type("BTREE", "Node", btree, ibtree)
	get_editor_interface().get_editor_viewport().add_child(dock)
	get_editor_interface().get_selection().connect("selection_changed",self,"selection_changed");
	make_visible(false)
	return

func _exit_tree():
	print("exit")
	remove_custom_type("BTREE")
	if  not dock:
		return
	dock.queue_free()
	dock = null
	return
