tool
extends MenuButton

var pop = null

var pselector_scene = preload("res://addons/btree/Editor/pselector/pselector.tscn")
var mute_scene = preload("res://addons/btree/Editor/mute/mute.tscn")
var repeat_scene = preload("res://addons/btree/Editor/repeat/repeat.tscn")
var wait_scene = preload("res://addons/btree/Editor/wait_node/wait_node.tscn")
var general_fcall_scene = preload("res://addons/btree/Editor/general_fcall/general_fcall.tscn")
var general_decorator_scene = preload("res://addons/btree/Editor/general_decorator/general_decorator.tscn")
var inverter = preload("res://addons/btree/Editor/inverter/inverter.tscn")

var pop_pos = Vector2.ZERO

func id_pressed(id):
	var zoom =  get_parent().get_parent().zoom
	var inst = null
	match id:
		0: 
			inst = general_fcall_scene.instance()
			inst.as_task()
		1:  
			inst = general_decorator_scene.instance()
			inst.as_selector()
		2:
			inst = general_decorator_scene.instance()
			inst.as_sequence()
		3:
			inst = pselector_scene.instance()
		4:
			inst = general_fcall_scene.instance()
			inst.as_priority_condition()
		5:
			inst = general_decorator_scene.instance()
			inst.as_paralel()
		6:
			inst = mute_scene.instance()
		7:
			inst = repeat_scene.instance()
		8:
			inst = general_fcall_scene.instance()
			inst.as_while()
		9:
			inst = wait_scene.instance()
		10:
			inst = general_decorator_scene.instance()
			inst.as_race()
		11:
			inst = general_decorator_scene.instance()
			inst.as_random_selector()
		12:
			inst = general_decorator_scene.instance()
			inst.as_random_sequence()
		13:
			inst = inverter.instance()
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
	pop.add_item("While Node")
	pop.add_item("Wait Node")
	pop.add_item("Race Node")
	pop.add_item("Random Selector")
	pop.add_item("Random Sequence")
	pop.add_item("Inverter")
	return
