# The console cvars' setter code
# Copyright (c) 2016 Hugo Locurcio and contributors - MIT license

# This file is preloaded from scripts/autoload/console.gd.
# You should make functions static in this script in order to avoid warnings.

extends Node

# The label's text
static func label_text(value):
	Console.set_label_text(value)

# The maximal framerate at which the application can run
static func client_max_fps(value):
	OS.set_target_fps(int(value))