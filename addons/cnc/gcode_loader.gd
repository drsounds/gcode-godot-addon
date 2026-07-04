@tool
class_name GCodeFormatLoader
extends ResourceFormatLoader

# Berätta för Godot vilka filändelser vi letar efter
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gcode", "txt"])

# Berätta för Godot vilken typ av resurs vi returnerar
func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "gcode" or ext == "txt":
		return "Resource"
	return ""

func _handles_type(type: StringName) -> bool:
	return type == &"Resource"

# Den faktiska tolkningsmekaniken (The Parser)
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()

	var gcode_res = GCodeResource.new()
	var parsed_commands: Array[Dictionary] = []

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		# Ignorera tomma rader och rena kommentarer
		if line == "" or line.begins_with(";"):
			continue
			
		# Ta bort eventuella inline-kommentarer (allt efter semikolon)
		var clean_line = line.split(";")[0].strip_edges()
		var tokens = clean_line.split(" ")
		
		var cmd_data = {}
		
		for token in tokens:
			if token.is_empty():
				continue
			var letter = token.left(1).to_upper()
			var value_str = token.substr(1)
			
			# Hantera kommandon (G0, G1, M3 osv) vs koordinater (X, Y, Z, F)
			if letter == "G" or letter == "M":
				cmd_data["type"] = letter + str(int(value_str.to_int()))
			else:
				# Värden konverteras till float för exakt precision i 3D-rymden
				cmd_data[letter] = value_str.to_float()
				
		if not cmd_data.is_empty():
			parsed_commands.append(cmd_data)
			
	gcode_res.commands = parsed_commands
	return gcode_res
