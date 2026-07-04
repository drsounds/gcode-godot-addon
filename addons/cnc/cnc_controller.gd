extends Node
class_name CNCController

# Här registrerar du vilka objekt i din scen som motsvarar vilket verktygsnummer (T)
@export var target_nodes: Dictionary = {
	1: null, # T1: Kan vara Kameran
	2: null, # T2: Kan vara Vattenytan (MeshInstance3D)
	3: null  # T3: Kan vara Solen/Ljuset (DirectionalLight3D)
}

var current_target: Node3D = null
var current_speed: float = 100.0
var active_tween: Tween

func execute_track(gcode_res: GCodeResource):
	if not gcode_res:
		return
		
	# Om vi redan kör en rörelse, stoppa den
	if active_tween and active_tween.is_running():
		active_tween.kill()
		
	active_tween = create_tween().set_parallel(false)
	
	# Vi loopar igenom alla kommandon sekventiellt
	for cmd in gcode_res.commands:
		
		# --- VERKTYGSVAL (Vilket objekt ska styras?) ---
		# Exempel: T1 (Välj verktyg 1) följt av M6 (Utför verktygsbyte)
		if cmd.has("T"):
			var slot = int(cmd["T"])
			if target_nodes.has(slot):
				current_target = target_nodes[slot]
				
		# --- RÖRELSE (G0 och G1) ---
		if cmd.has("type") and (cmd["type"] == "G0" or cmd["type"] == "G1"):
			if not current_target:
				continue # Gå till nästa om inget objekt är valt ännu
				
			# Hämta nuvarande eller nytt mål
			var target_pos = current_target.position
			if cmd.has("X"): target_pos.x = cmd["X"]
			if cmd.has("Y"): target_pos.y = cmd["Y"]
			if cmd.has("Z"): target_pos.z = cmd["Z"]
			if cmd.has("F"): current_speed = cmd["F"]
			
			# Beräkna tid baserat på avstånd och matning
			var distance = current_target.position.distance_to(target_pos)
			if distance > 0.001:
				var duration = distance / (current_speed / 60.0)
				
				# Interpolera det AKTIVA objektets position
				active_tween.tween_property(current_target, "position", target_pos, duration)\
					.set_trans(Tween.TRANS_CUBIC)\
					.set_ease(Tween.EASE_IN_OUT)
					
		# --- ANPASSADE M-KODER (För att styra andra parametrar) ---
		# Exempel: M3 kan starta något, M5 kan stoppa det
		if cmd.has("type") and cmd["type"] == "M3":
			if current_target and current_target.has_method("start_effect"):
				active_tween.tween_callback(Callable(current_target, "start_effect"))
