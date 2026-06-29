extends Node

@export var step := 32
@export var terrain_depth := 4000
@export var platform_depth := 1

func generate_all_collisions(paths_node:Node2D,static_body:StaticBody2D):
	# Supprime les anciennes collisions générées
	for child in static_body.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()
	# Crée une collision par Path2D
	for path in paths_node.get_children():
		if path is Path2D:
			create_collision_from_path(path, static_body)

func create_collision_from_path(path: Path2D, static_body: StaticBody2D):
	var curve = path.curve
	if curve == null or curve.point_count < 2:
		return
	var polygon := PackedVector2Array()
	var length = curve.get_baked_length()
	var d := 0.0
	# Points du haut, espacés pour éviter trop de mini-segments
	while d <= length:
		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)
		var body_point = static_body.to_local(world_point)
		polygon.append(body_point)
		d += step
	# Dernier point exact
	var last_local = curve.sample_baked(length)
	var last_world = path.to_global(last_local)
	var last_body = static_body.to_local(last_world)
	if polygon.size() == 0 or polygon[polygon.size() - 1].distance_to(last_body) > 1.0:
		polygon.append(last_body)
	# Ferme le terrain vers le bas
	var first = polygon[0]
	var last = polygon[polygon.size() - 1]
	polygon.append(Vector2(last.x, last.y + terrain_depth))
	polygon.append(Vector2(first.x, first.y + terrain_depth))
	var collision = CollisionPolygon2D.new()
	collision.polygon = polygon
	collision.set_meta("path",path)
	static_body.add_child(collision)

func generate_platforms_collisions(paths_node:Node2D,static_body:StaticBody2D):
	# Supprime les anciennes collisions générées
	for child in static_body.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()
	# Crée une collision par Path2D
	for path in paths_node.get_children():
		if path is Path2D:
			create_collision_from_platform(path, static_body)
			
func create_collision_from_platform(path: Path2D, static_body: StaticBody2D):
	var curve = path.curve
	if curve == null or curve.point_count < 2:
		return
	var polygon := PackedVector2Array()
	var length = curve.get_baked_length()
	var d := 0.0
	# Points du haut, espacés pour éviter trop de mini-segments
	while d <= length:
		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)
		var body_point = static_body.to_local(world_point)
		polygon.append(body_point)
		d += step
	# Dernier point exact
	var last_local = curve.sample_baked(length)
	var last_world = path.to_global(last_local)
	var last_body = static_body.to_local(last_world)
	if polygon.size() == 0 or polygon[polygon.size() - 1].distance_to(last_body) > 1.0:
		polygon.append(last_body)
	# Ferme le terrain vers le bas
	for k in range(polygon.size()-1,0,-1):
		polygon.append(polygon[k]+Vector2(0,platform_depth))
	#var first = polygon[0]
	#var last = polygon[polygon.size() - 1]
	#polygon.append(Vector2(last.x, last.y + platform_depth))
	#polygon.append(Vector2(first.x, first.y + platform_depth))
	var collision = CollisionPolygon2D.new()
	collision.polygon = polygon
	collision.set_meta("path",path)
	static_body.add_child(collision)

func generate_all_visuals(paths_node:Node2D,visuals:Node2D,road_texture_data:Dictionary,up_texture_data:Dictionary,down_texture_data:Dictionary,under_texture_data:Dictionary):
	for child in visuals.get_children():child.queue_free()
	for path in paths_node.get_children():
		if path is Path2D:
			# Road
			create_visual_from_path(path, visuals,road_texture_data)
			#Up Road
			var up_path := create_offset_path(path,up_texture_data["Offset"])
			create_visual_from_path(up_path, visuals,up_texture_data)
			#Down Road
			var down_path := create_offset_path(path,down_texture_data["Offset"])
			create_visual_from_path(down_path, visuals,down_texture_data)
			#Undercover
			var under_path := create_offset_path(path,under_texture_data["Offset"])
			create_visual_from_path(under_path, visuals,under_texture_data)

func create_offset_path(path: Path2D, offset: Vector2) -> Path2D:
	var new_path := Path2D.new()
	var new_curve := Curve2D.new()
	var curve = path.curve
	var natural_offset := path.position
	if curve == null:
		return new_path
	for i in range(curve.point_count):
		var pos = curve.get_point_position(i)
		var in_ctrl = curve.get_point_in(i)
		var out_ctrl = curve.get_point_out(i)
		new_curve.add_point(
			pos + offset + natural_offset,
			in_ctrl,
			out_ctrl
		)
	new_path.curve = new_curve
	return new_path

func create_visual_from_path(path: Path2D, visuals: Node2D,texture_data:Dictionary):
	var curve = path.curve
	if curve == null or curve.point_count < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length = curve.get_baked_length()
	var d := 0.0
	var left_points := []
	var right_points := []
	var distances := []
	while d <= length:
		var p = curve.sample_baked(d)
		var p_next = curve.sample_baked(min(d + 1.0, length))
		var dir = (p_next - p).normalized()
		var normal = Vector2(-dir.y, dir.x)
		var world_p = path.to_global(p)
		var local_p = visuals.to_local(world_p)
		left_points.append(local_p + normal * texture_data["Width"] * 0.5)
		right_points.append(local_p - normal * texture_data["Width"] * 0.5)
		distances.append(d)
		d += texture_data["Step"]
	if distances[distances.size() - 1] < length:
		var p = curve.sample_baked(length)
		var p_prev = curve.sample_baked(max(length - 1.0, 0.0))
		var dir = (p - p_prev).normalized()
		var normal = Vector2(-dir.y, dir.x)
		var world_p = path.to_global(p)
		var local_p = visuals.to_local(world_p)
		left_points.append(local_p + normal * texture_data["Width"] * 0.5)
		right_points.append(local_p - normal * texture_data["Width"] * 0.5)
		distances.append(length)
	for i in range(left_points.size() - 1):
		var u0 = distances[i] / texture_data["Repeat"]
		var u1 = distances[i + 1] / texture_data["Repeat"]
		var l0 = left_points[i]
		var r0 = right_points[i]
		var l1 = left_points[i + 1]
		var r1 = right_points[i + 1]
		# Triangle 1
		st.set_uv(Vector2(u0, 1))
		st.add_vertex(v3(l0))
		st.set_uv(Vector2(u0, 0))
		st.add_vertex(v3(r0))
		st.set_uv(Vector2(u1, 1))
		st.add_vertex(v3(l1))
		# Triangle 2
		st.set_uv(Vector2(u1, 1))
		st.add_vertex(v3(l1))
		st.set_uv(Vector2(u0, 0))
		st.add_vertex(v3(r0))
		st.set_uv(Vector2(u1, 0))
		st.add_vertex(v3(r1))
	var mesh = st.commit()
	var mesh_instance := MeshInstance2D.new()
	mesh_instance.mesh = mesh
	mesh_instance.texture = texture_data["Texture"]
	mesh_instance.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	mesh_instance.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visuals.add_child(mesh_instance)

func generate_platforms_visuals(paths_node:Node2D,visuals:Node2D,texture_data:Dictionary):
	for child in visuals.get_children():child.queue_free()
	for path in paths_node.get_children():if path is Path2D:create_visual_from_path(path, visuals,texture_data)

func v3(p: Vector2) -> Vector3:
	return Vector3(p.x, p.y, 0)
