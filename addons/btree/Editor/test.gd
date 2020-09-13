tool
extends Panel

func halt(value):
	$halt.visible = value
	return

func help():
	$help.popup_centered()
	return
