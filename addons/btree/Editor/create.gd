tool
extends MenuButton

var pop = null

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const error_no_task = "No function start with \"task_*(task)\" please create one !"

var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var general_fcall_scene = preload("res://addons/btree/Editor/general_fcall/general_fcall.tscn")
var general_decorator_scene = preload("res://addons/btree/Editor/general_decorator/general_decorator.tscn")
var inverter = preload("res://addons/btree/Editor/inverter/inverter.tscn")
var pop_pos = Vector2.ZERO
export(NodePath) var graph_path:NodePath
export(NodePath) var hint_path:NodePath

func id_pressed(id):
	var graph = get_node(graph_path)
	var zoom =  graph.zoom
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
	inst.offset = (graph.scroll_offset / zoom) + (graph.get_local_mouse_position() / zoom)
	graph.add_child(inst)
	return

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
	pop.add_item("Random Selector", Runtime.TNodeTypes.SELECTOR)
	pop.add_item("Random Sequence", Runtime.TNodeTypes.SEQUENCE)
	pop.add_item("Inverter", Runtime.TNodeTypes.INVERTER)
	return
