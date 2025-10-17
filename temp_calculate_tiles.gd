extends Node

# Temporary script to calculate tile count

func _ready():
	var grid_width = 8
	var grid_height = 24
	var tile_count = 0

	for q in range(-grid_width, grid_width + 1):
		for r in range(-grid_height, grid_height + 1):
			var s = -q - r

			if abs(q) <= grid_width and abs(r) <= grid_height and abs(s) <= max(grid_width, grid_height):
				tile_count += 1

	print("Grid Width: %d, Grid Height: %d" % [grid_width, grid_height])
	print("Total tiles: %d" % tile_count)

	# Calculate percentage used vs rectangular bound
	var rect_bound = (grid_width * 2 + 1) * (grid_height * 2 + 1)
	var percentage = (float(tile_count) / float(rect_bound)) * 100.0
	print("Rectangular bound: %d tiles" % rect_bound)
	print("Hexagonal uses: %.1f%% of rectangular bound" % percentage)

	get_tree().quit()
