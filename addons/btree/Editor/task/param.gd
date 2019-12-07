tool
extends HBoxContainer

signal remove_me(me)

var id = 0

func _ready():
	$OptionButton.clear()
	$OptionButton.add_item("Number")
	$OptionButton.add_item("Text")
	$OptionButton.selected = 1
	return

func set_id(value:int):
	id = value
	return

func _process(delta):
	$Label.text = str(id, " : ")
	return

func _on_TextEdit_gui_input(event):
	return

func _on_Button_pressed():
	emit_signal("remove_me", self)
	return

func get_value():
	var val = $TextEdit.text
	if  $OptionButton.selected == 0:
		if  val.is_valid_integer():
			val = int(val)
		elif val.is_valid_float():
			val = float(val)
		else:
			val = 0
	return [val, $OptionButton.selected]

func set_value(values):
	$TextEdit.text = str(values[0])
	$OptionButton.selected = values[1]
	return

func _on_TextEdit_focus_exited():
	if  not valid():
		$TextEdit.text = "0"
	return

func valid()->bool:
	var val = $TextEdit.text
	if  $OptionButton.selected == 0:
		if  val.is_valid_integer():
			return true
		elif val.is_valid_float():
			return true
		else:
			return false
	else:
		return true

func _on_OptionButton_item_selected(ID):
	if  not valid():
		$TextEdit.text = "0"
	return
