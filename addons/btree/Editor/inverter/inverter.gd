tool
extends BehaviorTreeNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.INVERTER


func get_data():
	return .get_data();

func set_data(data):	
	.set_data(data);
	return
