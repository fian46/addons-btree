tool
extends MenuButton

var pop = null
var undo_redo:UndoRedo = null

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const error_no_task = "No function start with \"task_*(task)\" please create one !"

var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var general_fcall_scene = preload("res://addons/btree/Editor/general_fcall/general_fcall.tscn")
var general_decorator_scene = preload("res://addons/btree/Editor/general_decorator/general_decorator.tscn")
var inverter = preload("res://addons/btree/Editor/inverter/inverter.tscn")
var general_decorator_script = preload("res://addons/btree/Editor/general_decorator/general_decorator.gd")
var random_repeat_scene = preload("res://addons/btree/Editor/repeat/random_repeat.tscn")
var random_wait_scene = preload("res://addons/btree/Editor/wait_node/random_wait_node.tscn")
var pop_pos = Vector2.ZERO
export(NodePath) var graph_path:NodePath
export(NodePath) var hint_path:NodePath
var drop_offset = Vector2.ZERO

func id_pressed(id):
	var graph = get_node(graph_path)
	var zoom =  graph.zoom
	var test_node = create_node(id)
	graph.add_child(test_node)
	var generated_name = test_node.name
	graph.remove_child(test_node)
	test_node.queue_free()
	undo_redo.create_action("add_node")
	undo_redo.add_do_method(self, "add_node", id, generated_name, drop_offset)
	undo_redo.add_undo_method(self, "del_node", generated_name)
	undo_redo.commit_action()
	return

func add_node(id, name, offset):
	var graph = get_node(graph_path)
	var node = create_node(id)
	node.name = name
	node.offset = offset
	(node as GraphNode).connect("dragged", graph, "node_dragged", [node])
	(node as GraphNode).connect("resize_request", graph, "resize_request", [node])
	if  node is general_decorator_script:
		node.undo_redo = undo_redo
	graph.add_child(node)
	return

func del_node(gname):
	var graph = get_node(graph_path)
	var node = graph.get_node_or_null(gname)
	node.queue_free()
	return

func create_node(id):
	var graph = get_node(graph_path)
	var inst = null
	match id:
		Runtime.TNodeTypes.TASK:
			if  not graph.node_has_task():
				var hint = get_node(hint_path)
				hint.text = error_no_task
			inst = general_fcall_scene.instance()
			inst.as_task()
		Runtime.TNodeTypes.SELECTOR:  
			inst = general_decorator_scene.instance()
			inst.as_selector()
		Runtime.TNodeTypes.SEQUENCE:
			inst = general_decorator_scene.instance()
			inst.as_sequence()
		Runtime.TNodeTypes.PRIORITY_SELECTOR:
			inst = pselector_scene.instance()
		Runtime.TNodeTypes.PRIORITY_CONDITION:
			if  not graph.node_has_task():
				var hint = get_node(hint_path)
				hint.text = error_no_task
			inst = general_fcall_scene.instance()
			inst.as_priority_condition()
		Runtime.TNodeTypes.PARALEL:
			inst = general_decorator_scene.instance()
			inst.as_paralel()
		Runtime.TNodeTypes.MUTE:
			inst = mute_scene.instance()
		Runtime.TNodeTypes.REPEAT:
			inst = repeat_scene.instance()
		Runtime.TNodeTypes.WHILE:
			if  not graph.node_has_task():
				var hint = get_node(hint_path)
				hint.text = error_no_task
			inst = general_fcall_scene.instance()
			inst.as_while()
		Runtime.TNodeTypes.WAIT:
			inst = wait_scene.instance()
		Runtime.TNodeTypes.RACE:
			inst = general_decorator_scene.instance()
			inst.as_race()
		Runtime.TNodeTypes.RANDOM_SELECTOR:
			inst = general_decorator_scene.instance()
			inst.as_random_selector()
		Runtime.TNodeTypes.RANDOM_SEQUENCE:
			inst = general_decorator_scene.instance()
			inst.as_random_sequence()
		Runtime.TNodeTypes.INVERTER:
			inst = inverter.instance()
		Runtime.TNodeTypes.RANDOM_REPEAT:
			inst = random_repeat_scene.instance()
		Runtime.TNodeTypes.RANDOM_WAIT:
			inst = random_wait_scene.instance()
	return inst

func _ready():
	pop = get_popup()
	pop.clear()
	pop.connect("id_pressed", self, "id_pressed")
	pop.add_item("Task", Runtime.TNodeTypes.TASK)
	pop.add_item("Selector", Runtime.TNodeTypes.SELECTOR)
	pop.add_item("Sequence", Runtime.TNodeTypes.SEQUENCE)
	pop.add_item("Priority Selector", Runtime.TNodeTypes.PRIORITY_SELECTOR)
	pop.add_item("Priority Condition", Runtime.TNodeTypes.PRIORITY_CONDITION)
	pop.add_item("Paralel", Runtime.TNodeTypes.PARALEL)
	pop.add_item("Mute", Runtime.TNodeTypes.MUTE)
	pop.add_item("Repeat", Runtime.TNodeTypes.REPEAT)
	pop.add_item("While Node", Runtime.TNodeTypes.WHILE)
	pop.add_item("Wait Node", Runtime.TNodeTypes.WAIT)
	pop.add_item("Race Node", Runtime.TNodeTypes.RACE)
	pop.add_item("Random Selector", Runtime.TNodeTypes.RANDOM_SELECTOR)
	pop.add_item("Random Sequence", Runtime.TNodeTypes.RANDOM_SEQUENCE)
	pop.add_item("Inverter", Runtime.TNodeTypes.INVERTER)
	pop.add_item("Random Repeat", Runtime.TNodeTypes.RANDOM_REPEAT)
	pop.add_item("Random Wait", Runtime.TNodeTypes.RANDOM_WAIT)
	return
