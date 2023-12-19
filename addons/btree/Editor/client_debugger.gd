@tool
extends Node

#var client:WebSocketClient = WebSocketClient.new()
#var client:WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new() #ivo
var client:WebSocketClient = WebSocketClient.new() #ivo

#func is_debug():
func is_debug(): #ivo
	return client.get_peer().get_ready_state() == WebSocketPeer.STATE_OPEN #ivo 4.1.1

func ensure_connection():
	if  client:
		if client.get_peer().get_ready_state() != WebSocketPeer.STATE_OPEN: #ivo 4.1.1
			client = WebSocketClient.new() #ivo
			client.connect_to_url("127.0.0.1:7777")
			client.connection_established.connect(connected)
			client.connection_closed.connect(disconected)
			client.connection_error.connect(failed)
			client.data_received.connect(data)
			client.text_received.connect(_on_text_received) #ivo
	return

func _on_text_received(wspeer, message): #ivo
	print("_on_text_received")
	pass

#func data():
func data(wspeer, message, is_string): #WebSocketClient
	var peer = client.get_peer() #ivo
	var msg = message.decode_var(0)
	get_parent().read(msg)
	return

var queue = []

func write(msg):
	#var status = client.get_connection_status()
	var status = client.get_peer().get_ready_state() #ivo
	if  status == WebSocketPeer.STATE_OPEN: #ivo
		queue.append(msg)
	return

func is_debug_started():
	if  client:
		#return client.get_connection_status() == 2
		return client.get_peer().get_connection_status() == WebSocketPeer.STATE_OPEN #ivo 4.1.1
	else:
		return false

func failed():
	get_parent().error()
	print("BT debug error, instance not found")
	return

#func connected(protocol):
func connected(peer, protocol): #ivo
	print(peer)
	print("BT debug started")
	return

func disconected(was_it_clean):
	print("BT debug stopped")
	get_parent().error()
	return

func _process(delta):
	if  client:
		if  client.is_listening():
			while queue.size() > 0 and  client.get_peer().get_ready_state() == WebSocketPeer.STATE_OPEN:
				var front = queue.pop_front()
				client.get_peer().put_var(front, true)
			client.poll()
	return

	
