tool
extends GraphNode


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
class_name BehaviorTreeNode

# Called when the node enters the scene tree for the first time.
func _ready():
	on_ready();

func on_ready():
	if !is_connected("close_request", self, "close_request"):
		connect("close_request", self, "close_request")

func _enter_tree():
	title = title;

func close_request():
	get_parent().child_delete(self)
	pass
	
func out_count():
	var c = 0
	for i in get_children():
		if  i is Label:
			c += 1
	return c	
	
func get_data():
	return {
		"count" : out_count(),
		"offset" : offset,
		"size": rect_size,
		"title": title
	}
	pass
	
func set_data(data):
	if data.has("title"):
		title = data.title
	else:
		title = data.name
		
	rect_size = data.size
	offset = data.offset
	pass
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
