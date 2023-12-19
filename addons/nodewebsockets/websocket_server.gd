# websocket_server.gd
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
@icon("res://addons/nodewebsockets/nws_server.svg")
class_name WebSocketServer
extends Node
## A WebSocket server node implementation.
##
## [b]Usage:[/b][br]
## Simply add [WebSocketServer] to your scene, config the server on the 
## inspector and connect the events that you need.[br]

## Emitted when a client requests a clean close. You should keep polling until 
## you get a [signal client_disconnected] signal with the same [param id] to 
## achieve the clean close. See [method WebSocketPeer.close] for more details.
signal client_close_request(peer : WebSocketPeer, id : int, code : int, reason : String)

## Emitted when a new client connects. [param protocol] will be the 
## sub-protocol agreed with the client.
signal client_connected(peer : WebSocketPeer, id : int, protocol : String)

## Emitted when a client disconnects. [param was_clean_close] will be true if 
## the connection was shutdown cleanly.
signal client_disconnected(peer : WebSocketPeer, id : int, was_clean_close : bool)

## Emitted when an error occurred on [method listen]
signal connection_error(error : Error)

## Emitted when the server is started
signal server_listen()

## Emitted when the server close
signal server_closed()

## Emitted when a new message is received.
signal data_received(peer : WebSocketPeer, id : int, message, is_string : bool)

## Emitted when a new text message is received.
signal text_received(peer : WebSocketPeer, id : int, message : String)


enum POLL_MODE {
	MANUAL,  ## You must to call [method poll] regulary to process any request
	IDLE,    ## poll is called automaticaly on [method Node._process]
	PHYSICS, ## poll is called automaticaly on [method Node._physics_process]
}


## If true the server start listening when [method Node._ready] is called, if 
## false you will need to start the server calling [method listen]
@export var start_on_ready := true
## Setup the way to call [method poll]
@export var poll_mode : POLL_MODE = POLL_MODE.IDLE
## If [member start_on_ready] is enable the server starts listening on this port
@export_range(1, 65535) var server_port : int = 44380
## The server sub-protocols allowed during the WebSocket handshake.
@export var protocols := PackedStringArray()
@export_group("Server parameters")
## When not set to * will restrict incoming connections to the specified IP 
## address. Setting bind_ip to 127.0.0.1 will cause the server to listen only 
## to the local host.
@export var bind_ip := "*"
## The time in seconds before a pending client (i.e. a client that has not yet 
## finished the HTTP handshake) is considered stale and forcefully disconnected.
@export var handshake_timeout := 3.0
## If true, this server refuses new connections.
@export var refuse_new_connections := false
## The extra HTTP headers to be sent during the WebSocket handshake.
## [b]Note:[/b] Not supported in Web exports due to browsers' restrictions.
@export var extra_headers := PackedStringArray()
## Certificate requiered to start a TLS server, a valid [member server_key] must be provided too
@export var server_certificate : X509Certificate = null
## Key requiered to start a TLS server, a valid [member server_certificate] must be provided too
@export var server_key : CryptoKey = null
## The size of the input buffer in bytes (roughly the maximum amount of memory that will be allocated for the inbound packets).
@export_range(1, 0x7FFFFFFF) var inbound_buffer_size : int = 65536
## The maximum amount of packets that will be allowed in the queues (both inbound and outbound).
@export_range(1, 0xFFFF) var max_queued_packets : int = 2048
## The size of the input buffer in bytes (roughly the maximum amount of memory that will be allocated for the outbound packets).
@export_range(1, 0x7FFFFFFF) var outbound_buffer_size : int = 65536


class _Client :
	enum STATUS {
		UNKNOWN,
		TCP,
		TLS,
		CONNECTED,
		HANDSHAKE,
	}
	var socket : WebSocketPeer = null
	var stream : StreamPeerTCP = null
	var stream_tls : StreamPeerTLS = null
	var status : int = STATUS.UNKNOWN
	var start_time : int = 0

var _tcp := TCPServer.new()
var _clients : Dictionary = {}
var _clients_erase : Array[int] = []
var _target_peer : int = MultiplayerPeer.TARGET_PEER_BROADCAST
var _closed := true


func _ready():
	set_process(false)
	set_physics_process(false)
	if start_on_ready:
		listen.call_deferred(server_port, protocols)


func _process(_delta):
	if poll_mode != 1:
		set_process(false)
		return
	poll()


func _physics_process(_delta):
	if poll_mode != 2:
		set_physics_process(false)
		return
	poll()


## Starts listening on the given port.[br]
## [br]
## You can specify the desired subprotocols via the "protocols" array.
## If the list empty (default), no sub-protocol will be requested.[br]
func listen(port : int = 0, list_protocols = null) -> Error:
	if _tcp.is_listening():
		connection_error.emit(ERR_ALREADY_IN_USE)
		return ERR_ALREADY_IN_USE
	if port != 0:
		server_port = port
	if list_protocols != null:
		protocols = list_protocols
	var res := _tcp.listen(server_port, bind_ip)
	if res != OK:
		connection_error.emit(res)
	else:
		_closed = false
		match poll_mode:
			POLL_MODE.MANUAL:
				set_process(false)
				set_physics_process(false)
			POLL_MODE.IDLE:
				set_process(true)
				set_physics_process(false)
			POLL_MODE.PHYSICS:
				set_process(false)
				set_physics_process(true)
		server_listen.emit()
	return res


## This needs to be called in order to have any request processed.
func poll() -> void:
	if not _tcp.is_listening():
		if not _closed:
			stop()
		return
	
	while _tcp.is_connection_available():
		if refuse_new_connections:
			_tcp.take_connection().disconnect_from_host()
			continue
		print_verbose("WebSocketServer: TCP connection is available...")
		var client := _Client.new()
		client.status = _Client.STATUS.TCP
		client.start_time = Time.get_ticks_msec()
		client.stream = _tcp.take_connection()
		if server_certificate != null and server_key != null:
			client.status = _Client.STATUS.TLS
			client.stream_tls = StreamPeerTLS.new()
			var result = client.stream_tls.accept_stream(client.stream, TLSOptions.server(server_key, server_certificate))
			if result != OK:
				print_verbose("WebSocketServer: TLS accept stream error: ", result)
				continue
		var id = 0
		while id == 0 or id == 1 or _clients.has(id):
			id = ((randi() << 8) + Time.get_ticks_msec()) & 0x7FFFFFFF
		_clients[id] = client
	
	for client_id in _clients:
		var client : _Client = _clients[client_id]
		
		match client.status:
			_Client.STATUS.TCP:
				client.stream.poll()
				match client.stream.get_status():
					StreamPeerTCP.STATUS_NONE:
						print_verbose("WebSocketServer: TCP status none.")
					
					StreamPeerTCP.STATUS_CONNECTING:
						print_verbose("WebSocketServer: TCP status connecting...")
					
					StreamPeerTCP.STATUS_CONNECTED:
						print_verbose("WebSocketServer: TCP status connected, creating WebSocketPeer...")
						client.socket = WebSocketPeer.new()
						client.socket.supported_protocols = protocols
						client.socket.handshake_headers = extra_headers
						client.socket.inbound_buffer_size = inbound_buffer_size
						client.socket.max_queued_packets = max_queued_packets
						client.socket.outbound_buffer_size = outbound_buffer_size
						client.socket.accept_stream(client.stream)
						client.status = _Client.STATUS.HANDSHAKE
					
					StreamPeerTCP.STATUS_ERROR:
						print_verbose("WebSocketServer: TCP status error.")
						_clients_erase.append(client_id)
						continue
			
			_Client.STATUS.TLS:
				client.stream_tls.poll()
				match client.stream_tls.get_status():
					StreamPeerTLS.STATUS_HANDSHAKING:
						print_verbose("WebSocketServer: TLS handshaking...")
					
					StreamPeerTLS.STATUS_CONNECTED:
						print_verbose("WebSocketServer: TLS status connected, creating WebSocketPeer...")
						client.socket = WebSocketPeer.new()
						client.socket.supported_protocols = protocols
						client.socket.handshake_headers = extra_headers
						client.socket.inbound_buffer_size = inbound_buffer_size
						client.socket.max_queued_packets = max_queued_packets
						client.socket.outbound_buffer_size = outbound_buffer_size
						client.socket.accept_stream(client.stream_tls)
						client.status = _Client.STATUS.HANDSHAKE
					
					StreamPeerTLS.STATUS_ERROR:
						print_verbose("WebSocketServer: TLS status error.")
						_clients_erase.append(client_id)
						continue
					
					StreamPeerTLS.STATUS_DISCONNECTED:
						print_verbose("WebSocketServer: TLS status disconnected.")
						_clients_erase.append(client_id)
						continue
					
					StreamPeerTLS.STATUS_ERROR_HOSTNAME_MISMATCH:
						print_verbose("WebSocketServer: TLS status error hostname mismatch.")
						_clients_erase.append(client_id)
						continue
			
			_Client.STATUS.HANDSHAKE:
				client.socket.poll()
				match client.socket.get_ready_state():
					WebSocketPeer.STATE_CONNECTING:
						print_verbose("WebSocketServer: handshake client connecting...")
						if Time.get_ticks_msec() - client.start_time > handshake_timeout * 1000:
							print_verbose("WebSocketServer: handshake client timeout.")
							_clients_erase.append(client_id)
							continue
					
					WebSocketPeer.STATE_OPEN:
						print_verbose("WebSocketServer: handshake client connected.")
						client.status = _Client.STATUS.CONNECTED
						#client_connected.emit(client.socket, client_id, client.socket.get_selected_protocol()) #orig
						client_connected.emit(client_id, client.socket.get_selected_protocol()) #ivo 
					
					WebSocketPeer.STATE_CLOSED:
						print_verbose("WebSocketServer: handshake client closed.")
						_clients_erase.append(client_id)
						continue
			
			_Client.STATUS.CONNECTED:
				client.socket.poll()
				match client.socket.get_ready_state():
					WebSocketPeer.STATE_CONNECTING:
						print_verbose("WebSocketServer: client conecting...")
					
					WebSocketPeer.STATE_OPEN:
						while client.socket.get_available_packet_count():
							var message = client.socket.get_packet()
							var is_string = client.socket.was_string_packet()
							var error = client.socket.get_packet_error()
							if error != OK:
								print_verbose("WebSocketServer: packet recived with error: ", error, " is string: ", is_string, " client: ", client_id, " / ", client.socket.get_connected_host(), " packet: ", message)
								continue
							if is_string:
								var msg_str = message.get_string_from_utf8()
								data_received.emit(client.socket, client_id, message, is_string)
								text_received.emit(client.socket, client_id, msg_str)
							else:
								data_received.emit(client.socket, client_id, message, is_string)
					
					WebSocketPeer.STATE_CLOSING:
						print_verbose("WebSocketServer: client ", client_id, " / ", client.socket.get_connected_host(), " closing...")
						# Keep polling to achieve proper close.
					
					WebSocketPeer.STATE_CLOSED:
						var code = client.socket.get_close_code()
						var reason = client.socket.get_close_reason()
						print_verbose("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
						client_close_request.emit(client.socket, client_id, code, reason)
						_clients_erase.append(client_id)
						client_disconnected.emit(client.socket, client_id, code != -1)
						continue
	
	for client_id in _clients_erase:
		_clients.erase(client_id)
	_clients_erase.clear()


## Disconnects the peer identified by [param id] from the server.[br]
## See [method WebSocketPeer.close] for more information
func disconnect_peer(id : int, code : int = 1000, reason : String = "") -> void:
	if id == MultiplayerPeer.TARGET_PEER_BROADCAST:
		for client_id in _clients:
			_clients[client_id].socket.close(code, reason)
		return
	if not _clients.has(id):
		return
	_clients[id].socket.close(code, reason)


## Returns an array with the id of all current connected clients
func get_clients() -> Array[int]:
	var result := Array(_clients.keys(), TYPE_INT, "", null)
	for client_id in _clients_erase:
		result.erase(client_id)
	return result


## see [method WebSocketPeer.get_connected_host]
func get_peer_address(id : int) -> String:
	if not _clients.has(id):
		return ""
	return _clients[id].socket.get_connected_host()


## see [method WebSocketPeer.get_connected_port]
func get_peer_port(id : int) -> int:
	if not _clients.has(id):
		return -1
	return _clients[id].socket.get_connected_port()


## Returns true if a peer with the given ID is connected.
func has_peer(id : int) -> bool:
	if _clients_erase.has(id):
		return false
	return _clients.has(id)


## Returns the WebSocketPeer associated to the given [param id], or null if the 
## client is not found.
func get_peer(id : int) -> WebSocketPeer:
	if not _clients.has(id):
		return null
	if _clients_erase.has(id):
		return null
	return _clients[id].socket


## Returns true if the server is actively listening on a port.
func is_listening() -> bool:
	return _tcp.is_listening()


## Configures the buffer sizes for the client [WebSocketPeer].[br]
## [br]
## The first two parameters define the size and queued packets limits of the 
## input buffer, the last are for the output buffer.[br]
## [br]
## Buffer sizes are expressed in KiB
func set_buffers(_input_buffer_size_kb: int, _input_max_packets: int, _output_buffer_size_kb: int) -> Error:
	if _tcp.is_listening():
		return ERR_ALREADY_IN_USE
	if _input_buffer_size_kb <= 0 or _input_max_packets <= 0 or _output_buffer_size_kb <= 0:
		return ERR_PARAMETER_RANGE_ERROR
	inbound_buffer_size = _input_buffer_size_kb * 1024
	max_queued_packets = _input_max_packets
	outbound_buffer_size = _output_buffer_size_kb * 1024
	return OK


## Sets additional headers to be sent to clients during the HTTP handshake.
func set_extra_headers(headers : PackedStringArray = PackedStringArray()) -> void:
	extra_headers = headers


## Stops the server and clear its state.
func stop() -> void:
	_tcp.stop()
	_clients.clear()
	_clients_erase.clear()
	if not _closed:
		_closed = true
		server_closed.emit()


## Sets the peer to which packets will be sent.
## The [param id] can be one of: [constant MultiplayerPeer.TARGET_PEER_BROADCAST] 
## to send to all connected peers, [constant MultiplayerPeer.TARGET_PEER_SERVER] 
## to send to the peer acting as server, a valid peer ID to send to that 
## specific peer, a negative peer ID to send to all peers except that one. By 
## default, the target peer is [constant MultiplayerPeer.TARGET_PEER_BROADCAST].
func set_target_peer(id : int) -> void:
	_target_peer = id


## Sends a raw packet. See [method set_target_peer]
func put_packet(buffer : PackedByteArray) -> Error:
	if not _tcp.is_listening():
		return ERR_UNCONFIGURED
	if _target_peer == MultiplayerPeer.TARGET_PEER_SERVER:
		return OK
	elif _target_peer < 0:
		_target_peer *= -1
		for client_id in _clients:
			if client_id != _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.put_packet(buffer)
	else:
		for client_id in _clients:
			if _target_peer == MultiplayerPeer.TARGET_PEER_BROADCAST or client_id == _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.put_packet(buffer)
	return OK


## Sends a binary packet. See [method set_target_peer]
func send(message : PackedByteArray) -> Error:
	if not _tcp.is_listening():
		return ERR_UNCONFIGURED
	if _target_peer == MultiplayerPeer.TARGET_PEER_SERVER:
		return OK
	elif _target_peer < 0:
		_target_peer *= -1
		for client_id in _clients:
			if client_id != _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.send(message)
	else:
		for client_id in _clients:
			if _target_peer == MultiplayerPeer.TARGET_PEER_BROADCAST or client_id == _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.send(message)
	return OK


## Sends a string message. See [method set_target_peer]
func send_text(message : String) -> Error:
	if not _tcp.is_listening():
		return ERR_UNCONFIGURED
	if _target_peer == MultiplayerPeer.TARGET_PEER_SERVER:
		return OK
	elif _target_peer < 0:
		_target_peer *= -1
		for client_id in _clients:
			if client_id != _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.send_text(message)
	else:
		for client_id in _clients:
			if _target_peer == MultiplayerPeer.TARGET_PEER_BROADCAST or client_id == _target_peer:
				var client : _Client = _clients[client_id]
				if client.status == _Client.STATUS.CONNECTED and \
				client.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
					client.socket.send_text(message)
	return OK

