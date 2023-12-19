# websocket_client.gd
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
@icon("res://addons/nodewebsockets/nws_client.svg")
class_name WebSocketClient
extends Node
## A WebSocket client node implementation.
##
## [b]Usage:[/b][br]
## Simply add [WebSocketClient] to your scene, config the server on the 
## inspector and connect the events that you need.[br]


## Emitted when the connection to the server is closed. [param was_clean_close] 
## will be true if the connection was shutdown cleanly.
signal connection_closed(was_clean_close : bool)

## Emitted when the connection to the server fails.
signal connection_error(error : Error)

## Emitted when a connection with the server is established, [param protocol] 
## will contain the sub-protocol agreed with the server.
signal connection_established(peer : WebSocketPeer, protocol : String)

## Emitted when a message is received.
signal data_received(peer : WebSocketPeer, message, is_string : bool)

## Emitted when a message text is received.
signal text_received(peer : WebSocketPeer, message)

## Emitted when the server requests a clean close. You should keep polling 
## until you get a [signal connection_closed] signal to achieve the clean 
## close. See [method WebSocketPeer.close] for more details.
signal server_close_request(code : int, reason : String)


enum POLL_MODE {
	MANUAL,  ## You must to call [method poll] regulary to process any request
	IDLE,    ## poll is called automaticaly on [method Node._process]
	PHYSICS, ## poll is called automaticaly on [method Node._physics_process]
}


## If true the client start listening when [method Node._ready] is called, if 
## false you will need to start the client calling [method connect_to_server]
@export var start_on_ready := true
## Setup the way to call [method poll]
@export var poll_mode : POLL_MODE = POLL_MODE.IDLE
## URL to WebSockets server[br][br]
## [b]Note:[/b] For TLS connections remember use a "wss://" prefix
@export var url_server : String = "ws://127.0.0.1:44380"
## The server sub-protocols allowed during the WebSocket handshake.
@export var protocols := PackedStringArray()
@export_group("Client parameters")
## The extra HTTP headers to be sent during the WebSocket handshake.
## [b]Note:[/b] Not supported in Web exports due to browsers' restrictions.
@export var extra_headers := PackedStringArray()
## Creates an unsafe TLS client configuration where certificate validation is 
## optional. You can optionally provide a valid trusted_chain, but the common 
## name of the certificates will never be checked.[br][br]
## [b]Using this configuration for purposes other than testing is not 
## recommended.[/b]
@export var trusted_unsafe : bool = false
## see [method TLSOptions.client]
@export var trusted_chain : X509Certificate = null
## see [method TLSOptions.client]
@export var trusted_common_name_override : String = ""
## The size of the input buffer in bytes (roughly the maximum amount of memory that will be allocated for the inbound packets).
@export_range(1, 0x7FFFFFFF) var inbound_buffer_size : int = 65536
## The maximum amount of packets that will be allowed in the queues (both inbound and outbound).
@export_range(1, 0xFFFF) var max_queued_packets : int = 2048
## The size of the input buffer in bytes (roughly the maximum amount of memory that will be allocated for the outbound packets).
@export_range(1, 0x7FFFFFFF) var outbound_buffer_size : int = 65536

var _socket := WebSocketPeer.new()
var _is_connected := false


func _ready():
	set_process(false)
	set_physics_process(false)
	if start_on_ready:
		connect_to_server.call_deferred()


func _process(_delta):
	if poll_mode != POLL_MODE.IDLE:
		set_process(false)
		return
	poll()


func _physics_process(_delta):
	if poll_mode != POLL_MODE.PHYSICS:
		set_physics_process(false)
		return
	poll()


## Connect to the server given by [member url_server]
func connect_to_server() -> Error:
	return connect_to_url(url_server)


## Connects to the given URL requesting one of the given 
## [param array_protocols] as sub-protocol. If the list empty (default), no 
## sub-protocol will be requested.[br]
## [br]
## You can optionally pass a list of [param array_headers] to be added to the 
## handshake HTTP request.
func connect_to_url(url : String, array_protocols = null, array_headers = null) -> Error:
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		connection_error.emit(ERR_ALREADY_IN_USE)
		return ERR_ALREADY_IN_USE
	url_server = url
	_is_connected = false
	if array_protocols != null:
		protocols = array_protocols
	if array_headers != null:
		extra_headers = array_headers
	_socket.supported_protocols = protocols
	_socket.handshake_headers = extra_headers
	_socket.inbound_buffer_size = inbound_buffer_size
	_socket.max_queued_packets = max_queued_packets
	_socket.outbound_buffer_size = outbound_buffer_size
	var result : Error = OK
	var tls_options = null
	if trusted_unsafe:
		tls_options = TLSOptions.client_unsafe(trusted_chain)
	elif trusted_chain != null or trusted_common_name_override.length() > 0:
		tls_options = TLSOptions.client(trusted_chain, trusted_common_name_override)
	result = _socket.connect_to_url(url, tls_options)
	if result == OK:
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
	else:
		connection_error.emit(result)
	return result


## Return true if is connected to server
func is_listening() -> bool:
	return _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED


## Disconnects this client from the connected host.[br]
## See [method WebSocketPeer.close] for more information.
func disconnect_from_host(code : int = 1000, reason : String = "") -> void:
	_socket.close(code, reason)


## Disconnects this client from the connected host.[br]
## See [method WebSocketPeer.close] for more information.
func close(code : int = 1000, reason : String = "") -> void:
	_socket.close(code, reason)


## Return the IP address of the currently connected host.
func get_connected_host() -> String:
	return _socket.get_connected_host()


## Return the IP port of the currently connected host.
func get_connected_port() -> int:
	return _socket.get_connected_port()


## Return the [class WebSocketPeer] of this client
func get_peer() -> WebSocketPeer:
	return _socket


func poll() -> void:
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print_verbose("WebSocketClient: connecting to \"", url_server, "\" ...")
		
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				print_verbose("WebSocketClient: connection established.")
				_is_connected = true
				connection_established.emit(_socket, _socket.get_selected_protocol())
			while _socket.get_available_packet_count():
				var message = _socket.get_packet()
				var is_string = _socket.was_string_packet()
				var error = _socket.get_packet_error()
				if error != OK:
					print_verbose("WebSocketClient: packet recived with error: ", error, " is string: ", is_string, " packet: ", message)
					continue
				if is_string:
					var msg_str = message.get_string_from_utf8()
					data_received.emit(_socket, message, is_string)
					text_received.emit(_socket, msg_str)
				else:
					data_received.emit(_socket, message, is_string)
		
		WebSocketPeer.STATE_CLOSING:
			print_verbose("State closing...")
			# Keep polling to achieve proper close.
		
		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			print_verbose("WebSocketClient: closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			server_close_request.emit(code, reason)
			connection_closed.emit(code != -1)
			set_process(false)
			set_physics_process(false)


## Configures the buffer sizes for this [WebSocketPeer].[br]
## [br]
## The first two parameters define the size and queued packets limits of the 
## input buffer, the last are for the output buffer.[br]
## [br]
## Buffer sizes are expressed in KiB
func set_buffers(_input_buffer_size_kb: int, _input_max_packets: int, _output_buffer_size_kb: int) -> Error:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return ERR_ALREADY_IN_USE
	if _input_buffer_size_kb <= 0 or _input_max_packets <= 0 or _output_buffer_size_kb <= 0:
		return ERR_PARAMETER_RANGE_ERROR
	inbound_buffer_size = _input_buffer_size_kb * 1024
	max_queued_packets = _input_max_packets
	outbound_buffer_size = _output_buffer_size_kb * 1024
	return OK


## see [method WebSocketPeer.send]
func send(message : PackedByteArray, write_mode : WebSocketPeer.WriteMode = 1) -> Error:
	return _socket.send(message, write_mode)


## see [method WebSocketPeer.send_text]
func send_text(message : String) -> Error:
	return _socket.send_text(message)
