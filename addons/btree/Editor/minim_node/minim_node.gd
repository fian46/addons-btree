tool
extends BehaviorTreeNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.MINIM
var data

func _ready():	
	$expand.connect("pressed", self, "pressed")
	return

func search_token():
	return $slot0/label.text

func get_data():
	var ret_data = .get_data();
	ret_data.data = data;
	ret_data.label = $slot0/label.text;	
	return ret_data

func set_data(ndata):
	.set_data(ndata)	
	data = ndata.data
	if  ndata.has("label"):
		$slot0/label.text = ndata.label
	else:
		ndata.label = ""
	return

func pressed():
	get_parent().maximize_node(self)
	return
