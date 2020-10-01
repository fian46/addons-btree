tool
extends HBoxContainer

signal remove_me(me)
var float_regex:RegEx = RegEx.new()

func _ready():
	float_regex.compile("^[-+]?\\d*\\.?\\d*$")
	$OptionButton.clear()
	$OptionButton.add_item("Number")
	$OptionButton.add_item("Text")
	$OptionButton.selected = 1
	_on_OptionButton_item_selected(1)
	$text_value.connect("text_changed", self, "validate")
	$text_value.connect("focus_exited", self, "fe_validate")
	return

func fe_validate():
	var value = $text_value.text
	if  $OptionButton.selected == 0:
		var r = float_regex.search(value)
		if  r:
			$text_value.text = r.get_string()
		else:
			$text_value.text = "0"
	return

func validate(value:String):
	if  $OptionButton.selected == 0:
		if  value.length() == 0:
			return
		var r = float_regex.search(value)
		if  r:
			var pc = $text_value.caret_position
			$text_value.text = r.get_string()
			$text_value.caret_position = pc
		else:
			$text_value.text = "0"
			$text_value.caret_position = 1
	return

func update_label():
	$Label.text = str(get_index(), " : ")
	return

func _on_Button_pressed():
	emit_signal("remove_me", self)
	return

func get_value():
	var val
	if  $OptionButton.selected == 0:
		var text:String = $text_value.text
		if  text.is_valid_integer():
			val = text.to_int()
		else:
			val = text.to_float()
	else:
		val = $text_value.text
	return [val, $OptionButton.selected]

func set_value(values):
	$OptionButton.selected = values[1]
	_on_OptionButton_item_selected(values[1])
	$text_value.text = str(values[0])
	return

func _on_OptionButton_item_selected(ID):
	if  ID == 0:
		validate($text_value.text)
	return
