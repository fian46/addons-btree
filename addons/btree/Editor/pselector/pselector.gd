tool
extends BehaviorTreeNode

const Runtime = preload("res://addons/btree/Runtime/runtime.gd")
const type = Runtime.TNodeTypes.PRIORITY_SELECTOR

func _on_Add_pressed():
	get_parent().ps_add_slot(name)
	return

func label():
	var l = Label.new()
	l.align = Label.ALIGN_RIGHT
	l.text = str(get_child_count())
	return l

func _on_Del_pressed():
	get_parent().ps_del_slot(name)
	return

func set_data(data):
	.set_data(data);
	
	for i in range(data.count):
		add_child(label())
		set_slot(get_child_count() - 1, false, 0, Color.blue, true, 1, Color.yellow, null, null)
	return
