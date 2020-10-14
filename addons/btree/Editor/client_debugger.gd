tool
extends Node

var client:WebSocketClient = WebSocketClient.new()

func is_debug():
	return client.get_connection_status() == 2

func ensure_connection():
	if  client:
		if client.get_connection_status() == 0:
			client = WebSocketClient.new()
			client.connect_to_url("127.0.0.1:7777")
			client.connect("connection_established", self, "connected")
			client.connect("connection_closed", self, "disconected")
			client.connect("connection_error", self, "failed")
			client.connect("data_received", self, "data")
	return

func data():
	var peer = client.get_peer(1)
	var msg = peer.get_var(true)
	get_parent().read(msg)
	return

var queue = []

func write(msg):
	var status = client.get_connection_status()
	if  status == 2 or status == 1:
		queue.append(msg)
	return

func is_debug_started():
	if  client:
		return client.get_connection_status() == 2
	else:
		return false

func failed():
	get_parent().error()
	print("BT debug error, instance not found")
	return

func connected(protocol):
	print("BT debug started")
	return

func disconected(was_it_clean):
	print("BT debug stopped")
	get_parent().error()
	return

func _process(delta):
	if  client:
		if  client.get_connection_status() != 0:
			while queue.size() > 0 and client.get_connection_status() == 2:
				var front = queue.pop_front()
				client.get_peer(1).put_var(front, true)
			client.poll()
	return
