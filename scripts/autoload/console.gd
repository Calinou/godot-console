# Godot Console main script
# Copyright (c) 2016 Hugo Locurcio and contributors - MIT license

extends Panel

onready var console_text = get_node("ConsoleText")
# Those are the scripts containing command and cvar code
var ConsoleCommands = preload("res://scripts/console_commands.gd")
var ConsoleCvars = preload("res://scripts/console_cvars.gd")
var cmd_history = []
var cmd_history_count = 0
var cmd_history_up = 0
# All recognized commands
var commands = {}
# All recognized cvars
var cvars = {}

var g_player = null

func _ready():
	# Allow selecting console text
	console_text.set_selection_enabled(true)
	# Follow console output (for scrolling)
	console_text.set_scroll_follow(true)
	# Don't allow focusing on the console text itself
	console_text.set_focus_mode(FOCUS_NONE)

	set_process_input(true)
	
	# FIXME, if not done break the terminal
	set_console_opened(false)
	set_console_opened(true)
	
	# By default we show help
	append_bbcode("Welcome in Godot Engine debug console\nProject: " + Globals.get("application/name") + "\nType [color=yellow]cmdlist[/color] to get a list of all commands avaliables\n[color=green]===[/color]\n")

	# Register built-in commands
	register_command("echo", {
		description = "Prints a string in console",
		args = "<string>",
		num_args = 1
	})
	
	register_command("history", {
		description = "Print all previous cmd used during the session",
		args = "",
		num_args = 0
	})

	register_command("cmdlist", {
		description = "Lists all available commands",
		args = "",
		num_args = 0
	})

	register_command("cvarlist", {
		description = "Lists all available cvars",
		args = "",
		num_args = 0
	})

	register_command("help", {
		description = "Outputs usage instructions",
		args = "",
		num_args = 0
	})

	register_command("quit", {
		description = "Exits the application",
		args = "",
		num_args = 0
	})

	register_command("clear", {
		description = "clear the terminal",
		args = "",
		num_args = 0
	})

	# Register built-in cvars
	register_cvar("client_max_fps", {
		description = "The maximal framerate at which the application can run",
		type = "int",
		default_value = 61,
		min_value = 10,
		max_value = 1000
	})

func _input(event):
	if event.is_action_pressed("console_toggle"):
		if is_console_opened():
			set_console_opened(false)
		else:
			set_console_opened(true)
	if event.is_action_pressed("console_up"):
		if (cmd_history_up > 0 and cmd_history_up <= cmd_history.size()):
			cmd_history_up-=1
			get_node("LineEdit").set_text(cmd_history[cmd_history_up])
			
	if event.is_action_pressed("console_down"):
		if (cmd_history_up > -1 and cmd_history_up + 1 < cmd_history.size()):
			cmd_history_up +=1
			get_node("LineEdit").set_text(cmd_history[cmd_history_up])

	if get_node("LineEdit").get_text() != "" and get_node("LineEdit").has_focus() and Input.is_key_pressed(KEY_TAB):
		complete()

func complete():
	var text = get_node("LineEdit").get_text()
	var matches = 0
	# If there are no matches found yet, try to complete for a command or cvar
	if matches == 0:
		for command in commands:
			if command.begins_with(text):
				describe_command(command)
				get_node("LineEdit").set_text(command + " ")
				get_node("LineEdit").set_cursor_pos(100)
				matches += 1
		for cvar in cvars:
			if cvar.begins_with(text):
				describe_cvar(cvar)
				get_node("LineEdit").set_text(cvar + " ")
				get_node("LineEdit").set_cursor_pos(100)
				matches += 1

# This function is called from scripts/console_commands.gd to avoid the
# "Cannot access self without instance." error
func quit():
	get_tree().quit()

# This function is called from scripts/console_commands.gd because get_node()
# can't be used there
func set_label_text(value):
	get_node("/root/Test/ExampleLabel").set_text(value)

func set_console_opened(opened):
	# Close the console
	if opened == true:
		get_node("AnimationPlayer").play("fade")
		# Signal handles the hiding at the end of the animation
	# Open the console
	elif opened == false:
		get_node("AnimationPlayer").play_backwards("fade")
		show()
		get_node("LineEdit").grab_focus()
		get_node("LineEdit").clear()

# This signal handles the hiding of the console at the end of the fade-out animation
func _on_AnimationPlayer_finished():
	if is_console_opened():
		hide()

# Is the console fully opened?
func is_console_opened():
	if get_opacity() == 0:
		return true
	else:
		return false

# Called when the user presses Enter in the console
func _on_LineEdit_text_entered(text):
	# used to manage cmd history
	if cmd_history.size() > 0:
		if (text != cmd_history[cmd_history_count - 1]):
			cmd_history.append(text)
			cmd_history_count+=1
	else:
		cmd_history.append(text)
		cmd_history_count+=1
	cmd_history_up = cmd_history_count
	var text_splitted = text.split(" ", true)
	# Don't do anything if the LineEdit contains only spaces
	if not text.empty() and text_splitted[0]:
		handle_command(text)
	else:
		# Clear the LineEdit but do nothing
		get_node("LineEdit").clear()

# Registers a new command
func register_command(name, args):
	commands[name] = args

# Registers a new cvar (control variable)
func register_cvar(name, args):
	cvars[name] = args
	cvars[name].value = cvars[name].default_value

func append_bbcode(bbcode):
	console_text.set_bbcode(console_text.get_bbcode() + bbcode)

func get_history_str():
	var strOut = ""
	var count = 0
	for i in cmd_history:
		strOut += "[color=#ffff66]" + str(count) + ".[/color] " + i + "\n"
		count+=1
	
	return strOut

func clear():
	console_text.set_bbcode("")

# Describes a command, user by the "cmdlist" command and when the user enters a command name without any arguments (if it requires at least 1 argument)
func describe_command(cmd):
	var command = commands[cmd]
	var description = command.description
	var args = command.args
	var num_args = command.num_args
	if num_args >= 1:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + " " + args + ")[/color]\n")
	else:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + ")[/color]\n")

# Describes a cvar, used by the "cvarlist" command and when the user enters a cvar name without any arguments
func describe_cvar(cvar):
	var cvariable = cvars[cvar]
	var description = cvariable.description
	var type = cvariable.type
	var default_value = cvariable.default_value
	var value = cvariable.value
	if type == "str":
		append_bbcode("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]\"" + str(value) + "\"[/color]  " + str(description) + " [color=#ff88ff](default: \"" + str(default_value) + "\")[/color]\n")
	else:
		var min_value = cvariable.min_value
		var max_value = cvariable.max_value
		append_bbcode("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]" + str(value) + "[/color]  " + str(description) + " [color=#ff88ff](" + str(min_value) + ".." + str(max_value) + ", default: " + str(default_value) + ")[/color]\n")

func handle_command(text):
	# The current console text, splitted by spaces (for arguments)
	var cmd = text.split(" ", true)
	# Check if the first word is a valid command
	if commands.has(cmd[0]):
		var command = commands[cmd[0]]
		print("> " + text)
		append_bbcode("[b]> " + text + "[/b]\n")
		# If no argument is supplied, then show command description and usage, but only if command has at least 1 argument required
		if cmd.size() == 1 and not command.num_args == 0:
			describe_command(cmd[0])
		else:
			# Run the command! If there are no arguments, don't pass any to the other script.
			if command.num_args == 0:
				ConsoleCommands.call(cmd[0].replace(".",""))
			else:
				ConsoleCommands.call(cmd[0].replace(".",""), text)
	# Check if the first word is a valid cvar
	elif cvars.has(cmd[0]):
		var cvar = cvars[cmd[0]]
		print("> " + text)
		append_bbcode("[b]> " + text + "[/b]\n")
		# If no argument is supplied, then show cvar description and usage
		if cmd.size() == 1:
			describe_cvar(cmd[0])
		else:
			# Let the cvar change values!
			if cvar.type == "str":
				for word in range(1, cmd.size()):
					if word == 1:
						cvar.value = str(cmd[word])
					else:
						cvar.value += str(" " + cmd[word])
			elif cvar.type == "int":
				cvar.value = int(cmd[1])
			elif cvar.type == "float":
				cvar.value = float(cmd[1])

			# Call setter code
			ConsoleCvars.call(cmd[0], cvar.value)
	else:
		# Treat unknown commands as unknown
		append_bbcode("[b]> " + text + "[/b]\n")
		append_bbcode("[i][color=#ff8888]Unknown command or cvar: " + cmd[0] + "[/color][/i]\n")
	get_node("LineEdit").clear()
