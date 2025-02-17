extends Node2D

#imports
var rng = RandomNumberGenerator.new()
var noise = FastNoiseLite.new()

#terrain data
var max_x : int = 60
var max_y : int = 35
var frequency : float = 1
var depth : int = 1
var water_level : int = -1
var height_resolution : int = 9

#debug
var do_map_fix : bool = true

#tile set
var tile_set_ground : Array[TileMapPattern] = []
var tile_set_water_1  : Array[TileMapPattern] = []
var tile_set_water_2  : Array[TileMapPattern] = []
var tile_set_water_3  : Array[TileMapPattern] = []
var tile_water : TileMapPattern
var tile_error : TileMapPattern
var tile_set_size = 64
var tile_rules : Array = [
	# Squares 4
	[0,0,0,0,1,1,0,1,1],# Square bottom left
	[0,0,0,1,1,0,1,1,0],# Square bottom right
	[1,1,0,1,1,0,0,0,0],# Square top right
	[0,1,1,0,1,1,0,0,0],# Square top left
	
	# Lines 8
	[0,0,0,1,1,1,1,1,1],# Line bottom
	[1,1,0,1,1,0,1,1,0],# Line left
	[1,1,1,1,1,1,0,0,0],# Line top
	[0,1,1,0,1,1,0,1,1],# Line right
	
	# Missing 13
	[0,1,1,1,1,1,1,1,1],# Missing top left
	[1,1,0,1,1,1,1,1,1],# Missing top right
	[1,1,1,1,1,1,1,1,0],# Missing bottom right
	[1,1,1,1,1,1,0,1,1],# Missing bottom left

	[1,1,1,1,1,1,1,1,1],# Full
	
	# Lines with one to the right 17
	[0,0,1,1,1,1,1,1,1],# Line bottom
	[1,1,0,1,1,0,1,1,1],# Line left
	[1,1,1,1,1,1,1,0,0],# Line top
	[1,1,1,0,1,1,0,1,1],# Line right
	
	# Lines with one to the left 21
	[1,0,0,1,1,1,1,1,1], # Line bottom
	[1,1,1,1,1,0,1,1,0], # Line left
	[1,1,1,1,1,1,0,0,1], # Line top
	[0,1,1,0,1,1,1,1,1], # Line right
	
	#squares with corner
	[1, 1, 0, 1, 1, 0, 0, 0, 1], # top left
	[0, 1, 1, 0, 1, 1, 1, 0, 0], # top right
	[1, 0, 0, 0, 1, 1, 0, 1, 1], # bottom right
	[0, 0, 1, 1, 1, 0, 1, 1, 0], # bottom left

	# 2 present
	# 1 missing 25
	[2,1,1,1,1,1,1,1,1],  # top left
	[1,1,2,1,1,1,1,1,1],  # top right
	[1,1,1,1,1,1,1,1,2],  # bottom right
	[1,1,1,1,1,1,2,1,1],  # bottom left
	# lines  27
	[1, 1, 1, 1, 1, 1, 2, 2, 2], # bottom
	[2, 2, 2, 1, 1, 1, 1, 1, 1], # top
	[2, 1, 1, 2, 1, 1, 2, 1, 1], # left
	[1, 1, 2, 1, 1, 2, 1, 1, 2], # right
	# L shaped
	[2, 1, 1, 2, 1, 1, 2, 2, 2], # bottom left
	[1, 1, 2, 1, 1, 2, 2, 2, 2], # bottom right
	[2, 2, 2, 2, 1, 1, 2, 1, 1], # top left	
	[2, 2, 2, 1, 1, 2, 1, 1, 2], # top right
	# 2x1
	[1, 1, 1, 2, 1, 1, 2, 1, 1], # bottom left V
	[1, 1, 1, 1, 1, 1, 2, 2, 1], # bottom left H
	[1, 1, 1, 1, 1, 2, 1, 1, 2], # bottom right V
	[1, 1, 1, 1, 1, 1, 1, 2, 2], # bottom right H
	[2, 1, 1, 2, 1, 1, 1, 1, 1], # top left V
	[1, 2, 2, 1, 1, 1, 1, 1, 1], # top left H
	[1, 1, 2, 1, 1, 2, 1, 1, 1], # top right V
	[2, 2, 1, 1, 1, 1, 1, 1, 1], # top right H
	# two 2x1
	[2, 2, 1, 1, 1, 2, 1, 1, 2], # top right
	[2, 1, 1, 2, 1, 1, 1, 2, 2], # bottom left
	[1, 1, 2, 1, 1, 2, 2, 2, 1], # bottom right
	[1, 2, 2, 2, 1, 1, 2, 1, 1], # top left
	# -1 and 2 present
]

#references
@onready var tile_set_layer : TileMapLayer = $".."
@onready var ground_layer : TileMapLayer = $"../../Ground"
@onready var frequency_slider = $"../../../CharacterBody2D/Camera2D/Control/Frequency"
@onready var depth_slider = $"../../../CharacterBody2D/Camera2D/Control/Depth"
@onready var water_level_slider = $"../../../CharacterBody2D/Camera2D/Control/Water Level"
@onready var height_resolution_slider = $"../../../CharacterBody2D/Camera2D/Control/Height Resolution"
@onready var do_fix_map_button = $"../../../CharacterBody2D/Camera2D/Control/do_fix_map"

func _on_frequency_drag_ended(value_changed: bool) -> void:
	if value_changed:
		frequency = frequency_slider.value
		_generate_map()

func _on_depth_drag_ended(value_changed: bool) -> void:
	if value_changed:
		depth = depth_slider.value
		_generate_map()

func _on_water_level_drag_ended(value_changed: bool) -> void:
	if value_changed:
		water_level = water_level_slider.value
		_generate_map()

func _on_height_resolution_drag_ended(value_changed: bool) -> void:
	if value_changed:
		height_resolution = height_resolution_slider.value
		water_level_slider.max_value = height_resolution-1
		_generate_map()

func _on_check_button_toggled(toggled_on: bool) -> void:
	do_map_fix = toggled_on
	if tile_set_ground.size() != 0:
		_generate_map()

func fix_map(array : Array) -> Array:	
	"""
	Fixes the map to remove corener height differences of more than 1
	"""
	#maybe make it a bit faster later
	var changed = true
	#sequence to find the 8 neighbouring cells
	var dx = [-1, 0, 1, -1, 1, -1, 0, 1]
	var dy = [-1, -1, -1, 0, 0, 1, 1, 1]
	while changed:
		changed = false
		for i in range(len(array)):
			for j in range(len(array[0])):
					for k in range(8):
						#this gives a sequence of 1 -1 1 -1
						var x = i + dx[k]
						#this gives a sequence of 1 1 -1 -1
						var y = j + dy[k]
						if x <= array.size()-1 and x >= 0 and y <= array[0].size()-1 and y >= 0:
							if (array[i][j] - array[x][y]) < -1:
								array[i][j] = array[x][y] -1
								changed = true
	return array

func array_has(array : Array, element) -> int:
	for i in range(len(array)):
		for j in range(len(array[i])):
			if array[i][j] != element[j]:
				break
			if j == len(array[i])-1:
				return i
	return -1

func _render_map(map : Array) -> void:
	#exclude borders for now
	for i in range(1,len(map)-1):
		for j in range(1,len(map[0])-1):
			var tile_pos = Vector2i(i, j)
			var height = map[i][j] -1
			var tile_state = [
				map[i-1][j-1] - height ,map[i][j-1] - height,map[i+1][j-1] - height,map[i-1][j] - height ,map[i][j] - height,map[i+1][j] - height,map[i-1][j+1] - height ,map[i][j+1] - height,map[i+1][j+1] - height
			]
			var tile_chosen = array_has(tile_rules, tile_state)
			if tile_chosen == -1 : 
				ground_layer.set_pattern(tile_pos, tile_error)
				continue
			if map[i][j] < water_level -1:
				ground_layer.set_pattern(tile_pos, tile_water)
			elif map[i][j] == water_level -1:
				ground_layer.set_pattern(tile_pos, tile_set_water_3[tile_chosen])
			elif map[i][j] == water_level:
				ground_layer.set_pattern(tile_pos, tile_set_water_2[tile_chosen])
			elif map[i][j] == water_level + 1 :
				ground_layer.set_pattern(tile_pos, tile_set_water_1[tile_chosen])
			else : 
				ground_layer.set_pattern(tile_pos, tile_set_ground[tile_chosen])

func _upscale_2d_array(array : Array, upscale_value : int) -> Array: 
	var new_array : Array[Array] = []
	for i in range(len(array)*upscale_value):
		new_array.append([])
		for j in range(len(array[0])*upscale_value):
			new_array[i].append(array[floor(i/upscale_value)][floor(j/upscale_value)])	
	return new_array

func _generate_map() -> void:
	var map : Array[Array] = []
	
	var depth_values : Array[int] = []
	var amplitudes : Array[float] = []
	var amplitudes_sum : float = 0
	
	var max : float = -1
	var min : float = 1
	
	for i in range(depth):
		depth_values.append(2 ** i)
		amplitudes.append(1/float(depth_values[i]))
		amplitudes_sum += amplitudes[i]
	
	#create noise value
	for i in range(max_x):
		map.append([]) 
		for j in range(max_y): 
			map[i].append(0)
			for l in range(depth):
				map[i][j] += amplitudes[l] *  noise.get_noise_2d(depth_values[l] * i * frequency,depth_values[l] * j * frequency) 
				if map[i][j] > max:
					max = map[i][j]
				if map[i][j] < min:
					min = map[i][j]
	
	#normalize and scale values
	for i in range(max_x):
		for j in range(max_y): 
			#normalize
			map[i][j] = (map[i][j] - min) / (max - min)
			#scale
			map[i][j] = round(map[i][j]* (height_resolution-1))
	
	if do_map_fix:
		map = fix_map(map)

	map = _upscale_2d_array(map, 2)
	
	_render_map(map)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set frequency to slider
	frequency_slider.value = frequency
	depth_slider.value = depth
	water_level_slider.value = water_level
	height_resolution_slider.value = height_resolution
	water_level_slider.max_value = height_resolution-1
	do_fix_map_button.button_pressed = do_map_fix
	
	#chose noise type
	noise.noise_type = 0
	
	#save tiles
	for i in range(tile_set_size): 
		tile_set_ground.append(tile_set_layer.get_pattern([Vector2i(i, 0)]))
		tile_set_water_1.append(tile_set_layer.get_pattern([Vector2i(i, -1)]))
		tile_set_water_2.append(tile_set_layer.get_pattern([Vector2i(i, -2)]))
		tile_set_water_3.append(tile_set_layer.get_pattern([Vector2i(i, -3)]))
	tile_error = tile_set_layer.get_pattern([Vector2i(1, 1)])
	tile_water = tile_set_layer.get_pattern([Vector2i(0, 1)])
	_generate_map()
