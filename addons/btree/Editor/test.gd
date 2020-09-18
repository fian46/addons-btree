tool
extends Panel

func halt(value):
	if  not value:
		$halt.visible = false
	else:
		$halt.visible = true
		$halt.text = str(value)
	return

func help():
	$help.popup_centered()
	return

func debug():
	$rtree.popup_centered()
	return
