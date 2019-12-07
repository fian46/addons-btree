tool
extends MenuButton

var pop = null

var task_scene = preload("res://addons/btree/Editor/task/task.tscn")
var sequence_scene = preload("res://addons/btree/Editor/sequence/sequence.tscn")
var selector_scene = preload("res://addons/btree/Editor/selector/selector.tscn")
var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var pcond_scene = preload("res://addons/btree/Editor/pselector/priority_condition.tscn")
var par_scene = preload("res://addons/btree/Editor/paralel/parallel.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var while_node_scene = preload("res://addons/btree/Editor/while_node/while_node.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var race_scene = preload("res://addons/btree/Editor/race/race.tscn")

var pop_pos = Vector2.ZERO

func id_pressed(id):
	var zoom =  get_parent().get_parent().zoom
	var inst = null
	match id:
		0: 
			inst = task_scene.instance()
		1:  
			inst = selector_scene.instance()
		2:
			inst = sequence_scene.instance()
		3:
			inst = pselector_scene.instance()
		4:
			inst = pcond_scene.instance()
		5:
			inst = par_scene.instance()
		6:
			inst = mute_scene.instance()
		7:
			inst = repeat_scene.instance()
		8:
			inst = while_node_scene.instance()
		9:
			inst = wait_scene.instance()
		10:
			inst = race_scene.instance()
	inst.offset = (get_parent().get_parent().scroll_offset / zoom) + (get_parent().get_parent().get_local_mouse_position() / zoom)
	get_parent().get_parent().add_child(inst)
	return

func _ready():
	pop = get_popup()
	pop.clear()
	pop.connect("id_pressed", self, "id_pressed")
	pop.add_item("Task")
	pop.add_item("Selector")
	pop.add_item("Sequence")
	pop.add_item("Priority Selector")
	pop.add_item("Priority Condition")
	pop.add_item("Paralel")
	pop.add_item("Mute")
	pop.add_item("Repeat")
	pop.add_item("WhileNode")
	pop.add_item("WaitNode")
	pop.add_item("RaceNode")
	return