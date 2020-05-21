tool
extends Control

func _enter_tree():
	yield(get_tree().create_timer(3), "timeout")
	queue_free()
	return

func text(value):
	$label.text = str(value)
	return
