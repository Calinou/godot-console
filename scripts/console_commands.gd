# The console commands' code
# Copyright (c) 2016 Hugo Locurcio and contributors - MIT license

# This file is preloaded from scripts/autoload/console.gd.
# You should make functions static in this script in order to avoid warnings.

extends MainLoop

# Prints a string in console
static func echo(text):
	# Erase "echo" from the output
	text.erase(0, 5)
	Console.append_bbcode(text + "\n")
	print(text)

# Lists all available commands
static func cmdlist():
	var commands = Console.commands
	for command in commands:
		Console.describe_command(command)

# Prints some help
static func help():
	var help_text = """Type [color=#ffff66]cmdlist[/color] to get a list of commands.
Type [color=#ffff66]quit[/color] to exit the application."""
	Console.append_bbcode(help_text + "\n")

# Exits the application
static func quit():
	Console.quit()