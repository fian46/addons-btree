# plugin_nodewebsockets.gd
# This file is part of: NodeWebSockets
# Copyright (c) 2023 IcterusGames
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions: 
#
# The above copyright notice and this permission notice shall be 
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
extends EditorPlugin

var _win_about = null
var _inspector_plugin : EditorInspectorPlugin = null


func _enter_tree():
	_win_about = load("res://addons/nodewebsockets/about.tscn").instantiate()
	_win_about.visible = false
	get_editor_interface().get_base_control().get_window().call_deferred(StringName("add_child"), _win_about)
	_inspector_plugin = load("res://addons/nodewebsockets/plugin_nws_inspector.gd").new()
	_inspector_plugin.about_pressed.connect(_on_about_pressed)
	add_inspector_plugin(_inspector_plugin)


func _exit_tree():
	if _win_about != null:
		_win_about.queue_free()
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)


func _on_about_pressed():
	if _win_about:
		_win_about.popup_centered()
