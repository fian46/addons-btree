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
	var tree_editor = dock.get_node("editor/graph")
	tree_editor.clear_editor()
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if  not selection:
		tree_editor.clear_data()
		dock.halt("Please select a BTREE node")
		return
	if  selection.size() == 1:
		if  selection[0] is btree:
			tree_editor.load_data(selection[0], self)
			dock.halt(null)
			if  dock.visible:
				tree_editor.reload()
		else:
			tree_editor.clear_data()
			dock.halt("Please select a BTREE node")
	else:
		tree_editor.clear_data()
		dock.halt("Please select a BTREE node")
	return

func make_visible(visible):
	if  not dock:
		return
	if  visible:
		selection_changed()
		var graph = dock.get_node("editor/graph")
		graph.active = true
		graph.reload()
		dock.show()
	else:
		var graph = dock.get_node("editor/graph")
		graph._on_save_pressed()
		graph.active = false
		graph.clear_data()
		graph.reload()
		dock.hide()
	return

func apply_changes():
#	why you behave not consistent ? please fix this
	var graph = dock.get_node("editor/graph")
	graph._on_save_pressed()
	return

func get_plugin_icon():
	return topi

func has_main_screen():
	return true

func get_plugin_name():
	return "BTEditor"

func disable_plugin():
	if  not dock:
		return
	get_editor_interface().get_editor_viewport().remove_child(dock)
	dock.queue_free()
	dock = null
	return

func _enter_tree():
	dock = dock_scene.instance()
	dock.halt("Please select a BTREE node")
	add_custom_type("BTREE", "Node", btree, ibtree)
	get_editor_interface().get_editor_viewport().add_child(dock)
	get_editor_interface().get_selection().connect("selection_changed",self,"selection_changed");
	make_visible(false)
	add_autoload_singleton("BTDebugServer", "res://addons/btree/script/bt_debug_server.gd")
	return

func _exit_tree():
	remove_custom_type("BTREE")
	remove_autoload_singleton("BTDebugServer")
	if  not dock:
		return
	dock.queue_free()
	dock = null
	return
