class_name Blackboard
extends Node

# Author: GabrieleTorini (https://github.com/GabrieleTorini)
# https://github.com/GabrieleTorini/godot-behavior-tree/blob/main/addons/behavior_tree/src/blackboard.gd

# This is the database where all your variables go. Here you keep track of 
# whether the player is nearby, your health is low, there is a cover available,
# or whatever.
#
# You just store the data here and use it for condition checks in BTCondition scripts, 
# or as arguments for your function calls in BTAction.
#
# This is a good way to separate data from behavior, which is essential 
# to avoid nasty bugs.

export(Dictionary) var _data: Dictionary

var data: Dictionary



func _enter_tree():
	data = _data.duplicate()


func _ready():
	for key in data.keys():
		assert(key is String)


# Will return false if it's overwritting an existing value
func _set(key: String, value) -> bool:
	var return_val = !has(key)
	data[key] = value
	return return_val



func get(key: String):
	if data.has(key):
		var value = data[key]
		if value is NodePath:
			if value.is_empty() or not get_tree().get_root().has_node(value):
				data[key] = null
				return null
			else:
				return get_node(value) # If you store NodePaths, will return the Node.
		else:
			return value


func has(key: String) -> bool:
	return data.has(key)

func unset(key: String) -> bool:
	var val = data.has(key)
	data.erase(key)
	return val

# Alias functions
func add(key: String, value):
	_set(key, value)

func clear(key: String) -> bool:
	return unset(key)

func remove(key: String) -> bool:
	return unset(key)

func delete(key: String) -> bool:
	return unset(key)
