extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)
signal connection_succeeded
signal connection_failed

const DEFAULT_PORT = 9999

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[Server] Started on port %d" % port)
	return OK

func join_game(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[Client] Connecting to %s:%d..." % [ip, port])
	return OK

func _on_peer_connected(id: int):
	print("[Net] Peer connected: %d" % id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int):
	print("[Net] Peer disconnected: %d" % id)
	player_disconnected.emit(id)

func _on_connected():
	print("[Client] Connected! My ID: %d" % multiplayer.get_unique_id())
	connection_succeeded.emit()

func _on_connection_failed():
	print("[Client] Connection failed!")
	connection_failed.emit()
