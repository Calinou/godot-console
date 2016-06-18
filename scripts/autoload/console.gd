# Godot Console main script
# Copyright (c) 2016 Hugo Locurcio and contributors - MIT license

extends Panel

onready var console_text = get_node("ConsoleContainer/ConsoleText")
# This is the script that contains the console commands' code
var ConsoleCommands = preload("res://scripts/console_commands.gd")
# All recognized commands
var commands = {}
# All recognized cvars
var cvars = {}

func _ready():
	# Register built-in commands
	register_command("echo", {
		description = "Prints a string in console",
		args = "<string>",
		num_args = 1
	})
	register_command("cmdlist", {
		description = "Lists all available commands",
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

# This function is called from scripts/console_commands.gd to avoid the
# "Cannot access self without instance." error
func quit():
	get_tree().quit()

# Called when the user presses Enter in the console
func _on_LineEdit_text_entered(text):
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
# TODO
func register_cvar(name, default):
	pass

func append_bbcode(bbcode):
	console_text.set_bbcode(console_text.get_bbcode() + bbcode)

func describe_command(cmd):
	var command = commands[cmd]
	var description = command.description
	var args = command.args
	var num_args = command.num_args
	if num_args >= 1:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + " " + args + ")[/color]\n")
	else:
		append_bbcode("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + ")[/color]\n")


func handle_command(text):
	# The current console text, splitted by spaces (for arguments)
	var cmd = text.split(" ", true)
	# Check if the first word is a valid command
	if commands.has(cmd[0]):
		var command = commands[cmd[0]]
		print("] " + text)
		append_bbcode("[b]] " + text + "[/b]\n")
		# If no argument is supplied, then show description and usage, but only if command has at least 1 argument required
		if cmd.size() == 1 and not command.num_args == 0:
			describe_command(cmd[0])
		else:
			# Run the command! If there are no arguments, don't pass any to the other script.
			if command.num_args == 0:
				ConsoleCommands.call(cmd[0])
			else:
				ConsoleCommands.call(cmd[0], text)
	else:
		# Treat unknown commands as unknown
		append_bbcode("[b]] " + text + "[/b]\n")
		append_bbcode("[i]Unknown command: " + cmd[0] + "[/i]\n")
	get_node("LineEdit").clear()