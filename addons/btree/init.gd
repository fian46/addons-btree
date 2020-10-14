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
		graph.editor_interface = get_editor_interface()
		graph.undo_redo = get_undo_redo()
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
	var ps = ProjectSettings
	var mbo = "network/limits/websocket_server/max_out_buffer_kb"
	var mbi = "network/limits/websocket_server/max_in_buffer_kb"
	ps.set_setting(mbo, 4096)
	ps.set_setting(mbi, 4096)
	ps.save()
	make_visible(false)
	add_autoload_singleton("BTDebugServer", "res://addons/btree/script/bt_debug_server.gd")
	get_tree().connect("node_added", self, "nodes")
	get_tree().connect("node_renamed", self, "nodes")
	get_undo_redo().clear_history()
	get_editor_interface().get_resource_filesystem().connect("resources_reload", self, "fs_reload")
	return

func fs_reload(names):
	dock.halt(null)
	var graph = dock.get_node("editor/graph")
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if  selection.size() == 1:
		if  selection[0] is btree:
			graph.clear_editor()
			graph.load_data(selection[0], self)
			graph.reload()
	return

func nodes(node):
	if  node is btree:
		var cn:Node = node
		while cn != null && (cn.filename == "" || cn.filename == null):
			cn = cn.get_parent()
		if  cn:
			var path = cn.get_path_to(node)
			node._tree_id = str(hash(cn.filename)) + str(hash(str(path)))
	return

func _exit_tree():
	var ps = ProjectSettings
	var mbo = "network/limits/websocket_server/max_out_buffer_kb"
	var mbi = "network/limits/websocket_server/max_in_buffer_kb"
	ps.set_setting(mbo, ps.property_get_revert(mbo))
	ps.set_setting(mbi, ps.property_get_revert(mbi))
	ps.save()
	get_tree().disconnect("node_added",self, "nodes")
	get_tree().disconnect("node_renamed", self, "nodes")
	remove_custom_type("BTREE")
	remove_autoload_singleton("BTDebugServer")
	get_editor_interface().get_resource_filesystem().disconnect("resources_reload", self, "fs_reload")
	get_undo_redo().clear_history()
	if  not dock:
		return
	dock.queue_free()
	dock = null
	return

func handles(object):
	if  object is btree:
		return true
	return false

var try = 0
func _process(delta):
	var interface = get_editor_interface()
	if  interface.is_playing_scene():
		if  dock:
			var debug = dock.get_node("rtree/client_debugger")
			if  not debug.is_debug():
				try -= 1
				if  try <= 0:
					try = 60
					debug.ensure_connection()
	return
