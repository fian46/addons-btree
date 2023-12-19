@tool
extends GraphNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")

const type = Runtime.TNodeTypes.MINIM
var data

func _ready():
	connect("delete_request", Callable(self, "close_request")) #ivo 4.2 ???
	$expand.connect("pressed", Callable(self, "pressed"))
	return

func search_token():
	return $slot0/label.text

func _enter_tree():
	title = name
	return

func get_data():
	var ret_data = {
		"offset":position_offset, #ivo
		"size":size,
		"data":data,
		"label": $slot0/label.text
	}
	return ret_data

func set_data(ndata):
	position_offset = ndata.offset #ivo
	size = ndata.size
	data = ndata.data
	if  ndata.has("label"):
		$slot0/label.text = ndata.label
	else:
		ndata.label = ""
	return

func pressed():
	get_parent().maximize_node(self)
	return

func close_request():
	get_parent().child_delete(self)
	return
