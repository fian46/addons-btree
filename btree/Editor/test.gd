tool
extends Panel

func halt(value):
	$Label.visible = value
	return

var hint_scene = preload("res://addons/btree/Editor/hint.tscn")

func hint(value):
	var hinst = hint_scene.instance()
	hinst.text(value)
	(hinst as Control).rect_min_size = Vector2(50, 30)
	$hint.add_child(hinst)
	if  $hint.get_child_count() > 5:
		$hint.remove_child($hint.get_child(0))
	return

func help(value):
	if  value:
		$help.visible = true
	else:
		$help.visible = false
	return
