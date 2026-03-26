extends Control

@onready var ip_input: LineEdit = $VBox/IPInput
@onready var port_input: LineEdit = $VBox/PortInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var host_btn: Button = $VBox/Buttons/HostButton
@onready var join_btn: Button = $VBox/Buttons/JoinButton

func _ready():
	ip_input.text = "127.0.0.1"
	port_input.text = "9999"
	status_label.text = ""

	# GameFlow launches the server with --server flag — auto-host without UI
	if "--server" in OS.get_cmdline_args():
		_on_host_pressed()

func _on_host_pressed():
	host_btn.disabled = true
	join_btn.disabled = true
	var port = int(port_input.text)
	var error = NetworkManager.host_game(port)
	if error == OK:
		status_label.text = "Server started! Loading game..."
		# Small delay so the label is visible
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		status_label.text = "Failed to start server! Error: %d" % error
		host_btn.disabled = false
		join_btn.disabled = false

func _on_join_pressed():
	host_btn.disabled = true
	join_btn.disabled = true
	var ip = ip_input.text.strip_edges()
	var port = int(port_input.text)
	var error = NetworkManager.join_game(ip, port)
	if error == OK:
		status_label.text = "Connecting to %s:%d..." % [ip, port]
		NetworkManager.connection_succeeded.connect(_on_connected, CONNECT_ONE_SHOT)
		NetworkManager.connection_failed.connect(_on_failed, CONNECT_ONE_SHOT)
	else:
		status_label.text = "Failed to connect!"
		host_btn.disabled = false
		join_btn.disabled = false

func _on_connected():
	status_label.text = "Connected! Loading game..."
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_failed():
	status_label.text = "Connection failed! Check IP and port."
	host_btn.disabled = false
	join_btn.disabled = false
